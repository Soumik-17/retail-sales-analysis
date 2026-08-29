# Solutions – Online Retail Sales Analysis (SQL)

This file explains how I answered each business question using SQL. I'm a fresher data analyst, so I've kept the explanations simple — focusing on what each query does and why, not just the code.

---

## Setup Before Answering Questions

Before jumping into the actual business questions, I did some groundwork:

1. **Created two tables** — `staging_retail` (everything as TEXT, so messy data loads without errors) and `retail_sales` (properly typed: integers, timestamps, decimals).
2. **Loaded the cleaned CSV** into staging, then inserted it into `retail_sales` with proper type casting (e.g., `quantity::INTEGER`, `invoice_date::TIMESTAMP`).
3. **Checked data quality** — counted nulls in description/customer_id, checked for zero or negative prices, and zero quantities.
4. **Checked for cancelled invoices** — in this dataset, any invoice number starting with `'C'` means it was cancelled.
5. **Checked for duplicate rows** using `GROUP BY` + `HAVING COUNT(*) > 1`.
6. **Built a view called `retail_clean`** on top of `retail_sales`. This view:
   - Adds `line_revenue` (quantity × unit price)
   - Flags cancelled orders (`is_cancelled`)
   - Flags guest checkouts with no customer ID (`is_guest`)
   - Filters out rows with `unit_price <= 0` (bad data)

   I used this view for almost every business question instead of the raw table, so I didn't have to repeat the same logic again and again.
7. **Added indexes** on customer_id, invoice_no, invoice_date, country, and stock_code — mainly to make the queries run faster since the table has over a million rows.

---

## Stakeholder 1: Marketing

### Q1. Best customers vs at-risk customers (RFM Segmentation)
I used the classic **RFM method** — Recency, Frequency, Monetary.
- **Recency**: how many days since their last purchase
- **Frequency**: how many separate orders they placed
- **Monetary**: how much total revenue they generated

I used `NTILE(5)` to split customers into 5 equal groups for each of the three metrics (so everyone gets a score from 1–5). Then I added the three scores together and used simple `CASE WHEN` rules to label customers as **Champions**, **Loyal**, **At Risk**, or **Lost**. Cancelled orders and guest customers (no ID) were excluded since we can't track them properly.

### Q2. One-time vs repeat customers
I first counted how many distinct orders each customer placed. Then I used `COUNT(*) FILTER (...)` to separately count customers with exactly 1 order versus more than 1 order, and calculated the repeat rate as a percentage.

### Q3. Inactive high-value customers
For each customer, I found their last order date and their total lifetime spend. Then I compared their last order date to the most recent date in the whole dataset — if the gap was more than 90 days, they were marked inactive. I sorted the result by lifetime value so the biggest "lost" customers show up first.

---

## Stakeholder 2: Sales

### Q1. Top products by revenue and volume
Simple `GROUP BY` on product, summing up revenue and quantity. I used `RANK()` twice — once ordering by revenue and once by quantity — so we can see if the top-selling product (by volume) is also the top-earning one (sometimes it isn't).

### Q2. Month-over-month revenue growth
I grouped revenue and order counts by month using `DATE_TRUNC('month', invoice_date)`. Then I used `LAG()` to pull in the previous month's revenue next to the current month's, and calculated the percentage change between them. This makes it easy to spot growth or decline trends over time.

### Q3. Products with high cancellation rates
For each product, I counted how many of its order lines were cancelled versus the total lines, then calculated a cancellation percentage. I only kept products with at least 30 total lines — this was to avoid a product that was ordered twice and cancelled once showing up as "100% cancelled," which wouldn't mean much.

---

## Stakeholder 3: Finance

### Q1. Cancellation value by country
For each country, I summed up revenue separately for cancelled and completed orders using `FILTER`, then calculated what percentage of total business value is being cancelled.

### Q2. Average order value by country and month
I first calculated the total value of each invoice (an invoice can have multiple product lines), then grouped those invoice totals by month and country to get the average order value.

### Q3. Revenue per customer by country
I divided each country's total revenue by its number of distinct customers. Countries with fewer than 5 customers were excluded, since an average based on just 1–2 customers can be misleading.

---

## What I'd Improve Next Time
- Add proper error handling/logging while loading data into staging tables.
- Try window functions like `SUM() OVER()` for running totals in the finance section.
- Automate the whole pipeline (Python cleaning → SQL loading) instead of doing it in two separate steps.
