# chocolate-database
* This repository contains the complete database schema and automation logic for a high-volume retail environment (500k+ records). The project focuses on Database Normalization, Automated Financial Calculations, and Strict Data Integrity through the use of advanced SQL features.

* All of the TABLES, VIEWS, and STORED PROCEDURES are available to view as CSV files within this repository. **Most of the data is limited to 1000 rows so as to keep the file size low (with the exception of the original imported data).** I believe this is long enough to get the general idea of the contents of the TABLES/VIEWS that would have exceeded this LIMIT. The `sales` table has ~500,000 rows of data, and the `customers` table has ~50,000 rows of data.
---
### Project Order:
This is the order this project should be viewed in:


---
### Project Description:
* The following...


---
### Project Insights:
* The following...

### DONE:
Initially set the table data types up to match the maximum data values in the table:
	 Adjusted DEC datatypes in sales table to allow for large aggregate sums (DEC(12,2) perhaps, example: 1,234,567,899.55)
	 Adjusted varchars across the board to accountfor potential INSERTS of larger size than current alloance
    
Add CHECK constraint to 'customer_loyalty_member_status' to make sure user can only input 1 or 0
Add a trigger to 'customer_join_date' so when it set to 1 it inserts todays date
SET COLUMNS EQUAL TO NOT NULL SO INSERTS ARE EXPLICIT AND ALL COLUMNS NEED DATA FOR AN INSERT TO WORK
Clean the sales table
Add those two triggers to the 'sales' table
Need to make sure each entry has unique product_name per brand!!!
Add the VIEW: Product_Brand_Performance: GROUP BY product_brand and get total revenue, total sales, average sale amount



---
