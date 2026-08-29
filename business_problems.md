# Business Problems – Online Retail Sales Analysis

## About the Project
This project uses the Online Retail II dataset (2009–2011) from Kaggle. It contains transaction-level data for a UK-based online retailer, including invoice numbers, products, quantities, prices, customers, and countries.

After cleaning and combining the raw data, I worked with three business teams — Marketing, Sales, and Finance — and answered the questions they usually care about. Below are the business problems, written the way a stakeholder would actually ask them.

---

## Stakeholder 1: Marketing

**Q1. Which customers are our best ones, and which ones are slipping away?**
Marketing wants to group customers based on how recently they bought, how often they buy, and how much they spend — so they know who to reward and who to win back.

**Q2. Are we mostly getting one-time buyers, or do people come back?**
They want to know what percentage of customers only ordered once versus those who ordered more than once. This tells them if retention is a problem.

**Q3. Which high-value customers have gone quiet?**
Some customers used to spend a lot but haven't ordered in a long time. Marketing wants a list of these customers (inactive for 90+ days) sorted by how valuable they were, so they can be targeted with win-back campaigns.

---

## Stakeholder 2: Sales

**Q1. What are our best-selling and highest-earning products?**
Sales wants a ranked list of products — by total revenue and by total units sold — to know what to promote and stock more of.

**Q2. Is revenue growing or shrinking month over month?**
They want to track monthly revenue and orders over time, along with the percentage growth (or drop) compared to the previous month.

**Q3. Which products get cancelled the most?**
Some products may have a high cancellation rate, which could mean quality issues, wrong listings, or sizing problems. Sales wants to find these products (only ones with enough order volume to be meaningful).

---

## Stakeholder 3: Finance

**Q1. How much money are we losing to cancellations, by country?**
Finance wants to see cancelled revenue vs completed revenue for each country, along with what percentage of business is being cancelled.

**Q2. What does the average order value look like, by country and by month?**
This helps Finance understand order value trends across regions and time.

**Q3. Which countries bring in the most revenue per customer?**
Instead of just total revenue, Finance wants to know which countries have the most valuable customers on average — this helps prioritize which markets to focus on. Countries with very few customers are excluded so the numbers aren't misleading.

---

## Summary
In total, there are 9 business questions across 3 teams. The next file (`solutions.md`) explains how each of these was answered using SQL.
