# Online Retail Sales Analysis – README

## Scenario
Imagine an online retail company based in the UK that sells all kinds of gift and household items to customers across multiple countries. The company has two years of raw transaction data sitting in separate files, and nobody has really analyzed it properly yet.

Three teams — Marketing, Sales, and Finance — each want answers to their own set of questions, but the data is messy, spread across two files, and not in a format that can directly answer anything. As the data analyst on this, my job was to clean the data, load it into a database, and answer each team's questions using SQL.

## Business Translation of Requirements
Each stakeholder came in with a business need, which had to be translated into something a database could actually answer:

| Stakeholder | Business Need | Translated Into |
|---|---|---|
| Marketing | "Who are our most valuable customers, and who's slipping away?" | Customer segmentation using Recency, Frequency, Monetary (RFM) scoring |
| Marketing | "Are people buying from us more than once?" | One-time vs repeat customer rate |
| Marketing | "Which good customers have we lost touch with?" | List of high-value customers inactive for 90+ days |
| Sales | "What's actually selling well?" | Product ranking by revenue and units sold |
| Sales | "Is business growing?" | Month-over-month revenue trend |
| Sales | "Are any products causing problems?" | Cancellation rate per product |
| Finance | "How much are cancellations costing us, and where?" | Cancelled vs completed revenue by country |
| Finance | "What's a typical order worth, and where?" | Average order value by country and month |
| Finance | "Which markets are actually the most profitable per customer?" | Revenue per customer by country |

Full details of each question are in `business_problems.md`, and how each was solved is in `solutions.md`.

## Tools and Requirements
- **Python (Pandas)** – used to load, clean, and combine the two raw yearly CSV files into a single clean dataset before loading it into the database.
- **PostgreSQL** – used as the database to store the cleaned data, run data quality checks, build a clean analytical view, and write all the business queries.
- **Jupyter Notebook** – used to write and run the Python cleaning steps (`combine_datasets.ipynb`).
- **SQL client** (e.g., pgAdmin / psql) – used to run the queries in `retail_sales_queries.sql` against PostgreSQL.

## Project Files
- `notebooks/combine_datasets.ipynb` – Python notebook that cleans and combines the two raw datasets into one CSV.
- `sql/retail_sales_queries.sql` – PostgreSQL script that loads the cleaned data, checks data quality, builds a clean view, and answers all business questions.
- `business_problems.md` – Business questions written in plain language for each stakeholder.
- `solutions.md` – Explanation of how each question was solved using SQL.

## Dataset & Disclaimer
This project uses the **Online Retail II** dataset, publicly available on **Kaggle**. All business problems and stakeholder scenarios written in this project are made up **entirely for practice purposes**, to simulate a real-world data analyst workflow. They do not represent any real company, team, or business decision.
