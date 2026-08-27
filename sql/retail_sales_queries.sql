CREATE TABLE retail_sales(
invoice_no VARCHAR(20),
stock_code VARCHAR(20),
description VARCHAR(255),
quantity INTEGER,
invoice_date TIMESTAMP,
unit_price DECIMAL(10,2),
customer_id NUMERIC(10,2),
country VARCHAR(50)
);

CREATE TABLE staging_retail (
    invoice_no    TEXT,
    stock_code    TEXT,
    description   TEXT,
    quantity      TEXT,
    invoice_date  TEXT,
    unit_price    TEXT,
    customer_id   TEXT,
    country       TEXT
);

INSERT INTO retail_sales
SELECT
    invoice_no,
    stock_code,
    description,
    quantity::INTEGER,
    invoice_date::TIMESTAMP,
    unit_price::NUMERIC(10,2),
    NULLIF(customer_id, '')::NUMERIC::INTEGER,
    country
FROM staging_retail;

SELECT * FROM retail_sales LIMIT 5;

SELECT COUNT(*) FROM retail_sales;

---nulls
SELECT
COUNT(*) FILTER (WHERE description IS NULL) AS null_desc,
COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer,
COUNT(*) FILTER (WHERE unit_price <= 0) AS zero_or_neg_price,
COUNT(*) FILTER (WHERE quantity = 0) AS zero_qty
FROM retail_sales;

---cancelled invoices
SELECT COUNT(*) FROM retail_sales WHERE invoice_no LIKE 'C%';

---duplicate_rows
SELECT invoice_no,stock_code,quantity,invoice_date,customer_id,COUNT(*)
FROM retail_sales
GROUP BY invoice_no,stock_code,quantity,invoice_date,customer_id
HAVING COUNT(*)>1;

SELECT invoice_no, stock_code, description, quantity, unit_price, customer_id
FROM retail_sales
WHERE unit_price <= 0
LIMIT 20;

---CLEAN ANALYTICAL VIEW
CREATE OR REPLACE VIEW retail_clean AS
SELECT
*,
(quantity*unit_price) AS line_revenue,
CASE WHEN invoice_no LIKE 'C%' THEN TRUE ELSE FALSE END AS is_cancelled,
CASE WHEN customer_id IS NULL THEN TRUE ELSE FALSE END AS is_guest
FROM retail_sales
WHERE unit_price>0;

---INDEXING FOR PERFORMANCE
CREATE INDEX idx_retail_customer ON retail_sales(customer_id);
CREATE INDEX idx_retail_invoice ON retail_sales(invoice_no);
CREATE INDEX idx_retail_date ON retail_sales(invoice_date);
CREATE INDEX idx_retail_country ON retail_sales(country);
CREATE INDEX idx_retail_stockcode ON retail_sales(stock_code);

---STAKEHOLDER 1 : MARKETING
---Q1
WITH rfm_base AS(
SELECT
customer_id,
MAX(invoice_date) AS last_purchase,
COUNT(DISTINCT invoice_no) AS frequency,
SUM(line_revenue) AS monetary
FROM retail_clean
WHERE is_cancelled = FALSE AND customer_id IS NOT NULL
GROUP BY customer_id
),rfm_scores AS(
SELECT
	customer_id,
	(SELECT MAX(invoice_date) FROM retail_clean) - last_purchase AS recency_gap,
	frequency,
	monetary,
	NTILE(5) OVER (ORDER BY (SELECT MAX(invoice_date) FROM retail_clean) - last_purchase DESC) AS r_score,
	NTILE(5) OVER (ORDER BY frequency) AS f_score,
	NTILE(5) OVER (ORDER BY monetary) AS m_score
	FROM rfm_base
)
SELECT
customer_id,recency_gap,frequency,monetary,
r_score, f_score, m_score,
(r_score + f_score + m_score) AS rfm_total,
CASE
    WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
	WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal'
	WHEN (r_score + f_score + m_score) >=7 THEN 'At Risk'
	ELSE 'Lost'
END AS segment
FROM rfm_scores
ORDER BY rfm_total DESC;

---Q2
WITH customer_orders AS(
SELECT customer_id, COUNT(DISTINCT invoice_no) AS order_count
FROM retail_clean
WHERE is_cancelled = FALSE AND customer_id IS NOT NULL
GROUP BY customer_id
)
SELECT
COUNT(*) FILTER(WHERE order_count = 1) AS one_time_customers,
COUNT(*) FILTER(WHERE order_count > 1) AS repeat_customers,
ROUND(100.0 * COUNT(*) FILTER(WHERE order_count > 1) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_orders;

---Q3
WITH last_purchase AS(
SELECT customer_id, MAX(invoice_date) AS last_order_date, SUM(line_revenue) AS lifetime_value
FROM retail_clean
WHERE is_cancelled = FALSE AND customer_id IS NOT NULL
GROUP BY customer_id
)
SELECT
customer_id, last_order_date, lifetime_value,
(SELECT MAX(invoice_date) FROM retail_clean) - last_order_date AS days_inactive
FROM last_purchase
WHERE (SELECT MAX(invoice_date) FROM retail_clean) - last_order_date > INTERVAL '90 days'
ORDER BY lifetime_value DESC;

---STAKEHOLDER 2:SALES
---Q1
SELECT stock_code, description,
       SUM(quantity) AS total_units,
       SUM(line_revenue) AS total_revenue,
       RANK() OVER (ORDER BY SUM(line_revenue) DESC) AS revenue_rank,
       RANK() OVER (ORDER BY SUM(quantity) DESC) AS volume_rank
FROM retail_clean
WHERE is_cancelled = FALSE
GROUP BY stock_code, description
ORDER BY total_revenue DESC
LIMIT 10;

---Q2
SELECT
    DATE_TRUNC('month', invoice_date) AS sales_month,
    SUM(line_revenue) AS monthly_revenue,
    COUNT(DISTINCT invoice_no) AS num_orders,
    LAG(SUM(line_revenue)) OVER (ORDER BY DATE_TRUNC('month', invoice_date)) AS prev_month_revenue,
    ROUND(100.0 * (SUM(line_revenue) - LAG(SUM(line_revenue)) OVER (ORDER BY DATE_TRUNC('month', invoice_date)))
          / NULLIF(LAG(SUM(line_revenue)) OVER (ORDER BY DATE_TRUNC('month', invoice_date)), 0), 2) AS mom_growth_pct
FROM retail_clean
WHERE is_cancelled = FALSE
GROUP BY sales_month
ORDER BY sales_month;

---Q3
WITH product_stats AS (
    SELECT
        stock_code,
        description,
        COUNT(*) FILTER (WHERE is_cancelled = TRUE) AS cancelled_lines,
        COUNT(*) AS total_lines,
        SUM(line_revenue) FILTER (WHERE is_cancelled = FALSE) AS net_revenue
    FROM retail_clean
    GROUP BY stock_code, description
    HAVING COUNT(*) >= 30   -- ignore low-volume/noisy products
)
SELECT
    stock_code,
    description,
    total_lines,
    cancelled_lines,
    net_revenue,
    ROUND(100.0 * cancelled_lines / total_lines, 2) AS cancellation_rate_pct
FROM product_stats
ORDER BY cancellation_rate_pct DESC
LIMIT 20;

---STAKEHOLDER 3: FINANCE
---Q1
SELECT
    country,
    SUM(line_revenue) FILTER (WHERE is_cancelled = TRUE) AS cancelled_value,
    SUM(line_revenue) FILTER (WHERE is_cancelled = FALSE) AS completed_value,
    ROUND(100.0 * SUM(line_revenue) FILTER (WHERE is_cancelled = TRUE)
        / NULLIF(SUM(ABS(line_revenue)), 0), 2) AS cancellation_rate_pct
FROM retail_clean
GROUP BY country
ORDER BY cancelled_value ASC;

---Q2
WITH invoice_totals AS (
    SELECT invoice_no, country, DATE_TRUNC('month', MIN(invoice_date)) AS order_month,
           SUM(line_revenue) AS order_value
    FROM retail_clean
    WHERE is_cancelled = FALSE
    GROUP BY invoice_no, country
)
SELECT order_month, country,
       COUNT(*) AS num_orders,
       ROUND(AVG(order_value), 2) AS avg_order_value
FROM invoice_totals
GROUP BY order_month, country
ORDER BY order_month, avg_order_value DESC;

---Q3
SELECT
    country,
    COUNT(DISTINCT customer_id) AS num_customers,
    SUM(line_revenue) AS total_revenue,
    ROUND(SUM(line_revenue) / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS revenue_per_customer
FROM retail_clean
WHERE is_cancelled = FALSE AND customer_id IS NOT NULL
GROUP BY country
HAVING COUNT(DISTINCT customer_id) >= 5   -- exclude tiny/noisy country samples
ORDER BY revenue_per_customer DESC;

