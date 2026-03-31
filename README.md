# chocolate-database
* This repository contains the complete database management system (DBMS) schema and automation logic for a high-volume retail environment (500k+ records). The project focuses on Database Normalization, Automated Financial Calculations, and Strict Data Integrity through the use of advanced SQL features.

* All of the TABLES, VIEWS, and STORED PROCEDURES are available to view as CSV files within this repository. **Most of the data is limited to 1000 rows so as to keep the file size low (with the exception of the original imported data). Also note that the `sales` table had to be slpit into two parts because of the file size.** I believe this is long enough to get the general idea of the contents of the TABLES/VIEWS/PROCEDURES that would have exceeded this chosen LIMIT. The `sales` table has ~500,000 rows of data, and the `customers` table has ~50,000 rows of data.

* **This projects files are split into two parts: `RetailDBMS.sql`, and `main.sql`.** The purpose of **`RetailDBMS.sql`** is to have a file where all Data Definition Language (DDL) and back-end structure for the DBMS is located: database/table creations, data import/cleaning, and definitions for triggers/views/stored procedures. The purpose of **`main.sql`** is to have a file strictly for user interaction with the DBMS, where all of the defined tools just described can be found and run. 
  
---
### Project Order:
This is the order this project should be viewed in:

* `Project Images/`
	* `Database Structure.png`
 	* `Database Column Info.pdf`
* `Data/CSV Files to Import to SQL/` (Raw Data)
	*  `sales(1).csv` (first half of sales data)
 	*  `sales(2).csv` (second half of sales data)
    *  `products.csv`
    *  `customers.csv`
    *  `stores.csv`
* `SQL Files/`
	* `RetailDBMS.sql`
* `Data/Exported from SQL/` (Cleaned Data)
	* `sales.csv`
	* `products.csv`
 	* `customers.csv`
  	* `stores.csv`
* `SQL Files/`
	* `main.sql`
* `Views/`
	* `Sales Views/`
 	* `Product Views/`
  	* `Customer Views/`
  	* `Store Views/` 
* `Stored Procedures/`
	* `get_sales_by_date('2023-06-21', '2023-09-23').csv`
 	* ` get_product_by_category('Milk').csv`
  	* `get_top_non_loyal_customers_by_year(299.99, 2024).csv`
  	* `get_ranked_products_per_store(3).csv` 


---
### Project Process:
* The following will be a brief project description, **to view the step-by-step process that I took for this project, please view `RetailDBMS.sql` as it is highly detailed, and structured/written in chronological order.**

**1.) Finding the Data:** The data used in this project can be found here: 

[Chocolate Database on Kaggle](https://www.kaggle.com/datasets/ssssws/chocolate-sales-dataset-2023-2024)

This data was used because of it's size and relational table format.

**2.) Breifly Cleaning the Data for Import:** I decided that the `calendar.csv` table was unnecessary as SQL has tools in place to determine the data stored there. Furthermore, the other tables were in good form, but needed to be cleaned slighty. The main problem was the format of the primary keys beginning with a character(s) and having leading zeros (e.g. 'store_id': S093, instead of the ideal 93). To fix this, I simply used the find and replace tool in Excel on all of the tables. After this, the data was ready for import via MySQL's import wizard tool (description of this in `RetailDBMS.sql`).

**3.) `RetailDBMS.sql`:** The rest of my thought processes concerning the flow of this projects creation/cleaning processes can be found on `RetailDBMS.sql`.

---
### Project Insights:
* Following the completion of this project, many conclusions about the data can be drawn that would be impossible to ascertain by just viewing the data tables alone. This section is dedicated to those conclusions, and will describe them  as they relate to specific VIEWS/STORED PROCEDURES that were cerated to answer specific business questions:

VIEWS:
---
#### Sales Table:
**1.) `sales_summary`:** 

This is the **CORE VIEW** of the entire DBMS as it **connects all tables in the database together per individual sales on the `sales` table through the three foreign keys associated with the `products`, `customers`, and `stores` tables!** Therefore, this VIEW shows ALL of the information associated with a sale that cannot be found on the `sales` table alone: all of the product data, customer data, and store data. Using this, you can not only find out the price data of what was bought and how much of it, but what the product specifically is, the gender and age of the customer who bought it, what store city and country they bought it from, and so on.

**2 & 3.) `monthly_sales` & `yearly_sales`:**

These views **aggregate the massive 500k+ row dataset into time-series snapshots.** They are designed to **identify growth patterns and seasonality.** By calculating total revenue, profit, and average transaction value and profit per month and year, these views answer critical business questions regarding **which periods are most profitable and how the business is scaling over time.**


#### Products Table:
**1.) `product_performance`:**

This view provides **a micro sales analysis of every item in the catalog.** It calculates the total units sold and profit margins for each unique product. **This allows the business to rank all products and identify products with high margins and high volume versus underperforming products** that may be taking up inventory space without contributing significantly to the bottom line.

**2 & 3.) `product_brand_performance` & `product_category_performance`:**

These views provide **a macro sales perspective by grouping data by brand and category.** They help in determining **which chocolate brands (e.g. Hershey vs. Cadbury) and categories (e.g., Dark vs. Milk) are the most profitable.** This is essential for informing procurement strategies and marketing focus. 

#### Customers Table:
**1.) `customer_lifetime_value`:**

This view **identifies the most valuable customers by calculating their total historical spend and profit.** By ranking customers based on CLV, the business can implement high-value retention strategies and identify the characteristics of their most profitable patrons. 

**2.) `loyalty_member_analysis`:**

This view specifically answers the question: **"Is our loyalty program working?"** By comparing transaction volume and average spend between members and non-members, **the business can statistically prove the ROI of the loyalty program or identify areas where it needs improvement.**

**3.) `customer_gender_analysis`:**

Tihs view specifically answers the question: **"Is there a difference in spending between male and female customers?"** By comparing them directly like this, **the business can determine if there is an expected even slpit in spending, or if one gender seems to spend more/less.** After this determination, the business can make moves to **change their advertisment strategy to try to cater more to either male/female customers.**

#### Stores Table:
**1.) `store_performance`:**

By **aggregating sales by geography**, this view ranks physical locations based on profitability. It **answers which cities or countries are the strongest markets**, allowing for better-informed decisions regarding future **store expansions or resource allocation.**

**2.) `ranked_products_per_store`:**

This view provides an **in depth rank of all products per store based on amount of units sold**. This is useful when comparing the most profitable to least profitable stores in the `store_performance` view as **you can see how differently the stores sales vary from the most profitable to least profitable stores.** Furthermore, if you **ORDER this view further by the 'rank_in_store' column, you can see an ordered view of which products are performing best across ALL stores, and which ones are performing worse.**


STORED PROCEDURES:
---
**1.) `get_sales_by_date('2023-06-21', '2023-09-23')`:**

**This procedure if a date filter for the core `sales_summary` VIEW.** Unlike a static view, it **accepts a date range as input**, enabling a manager to pull a comprehensive summary for a specific holiday season, a promotional weekend, or a fiscal quarter without writing a single line of new SQL code. In this specific example, we filter the `sales_summary` view to only show transactions from the summer of 2023. 

**2.) `get_product_by_category('Milk')`**

**This procedure is a filter of the `product_performance` VIEW.** By inputting a specific category (e.g., 'Milk'), it instantly returns the performance metrics for only those items, allowing category managers to deep-dive into specific segments of the inventory. A stored procedure could also be made exactly like this for the 'brand' column as well.

**3.) `get_top_non_loyal_customers_by_year(299.99, 2024)`**

**This is a targeted marketing tool.** It identifies customers who are spending significant amounts (above a specified threshold) but have not yet joined the loyalty program. This allows the business to generate a highly specific "leads list" for loyalty recruitment campaigns, and or potentially reward customers by giving access to the loyalty program for spending a certain amount per a given year. 

**4.) `get_ranked_products_per_store(3)`**

**This view is a filter of the `ranked_products_per_store` VIEW.** This procedure **uses Window Functions to rank products locally within a specific store.** It answers the highly localized question: **"What is the #1 selling item in the London store versus the Paris store?"** This is vital for managing regional inventory variations.
