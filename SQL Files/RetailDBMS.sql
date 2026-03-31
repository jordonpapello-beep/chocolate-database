-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 								    ------------ DATABASE CREATION ------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
CREATE DATABASE IF NOT EXISTS retailDB; -- The database that will store all of our tables
USE retailDB; -- Set as the default schema so further actions will affect THIS database (useful when there are multiple DBs/conn)


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 									 ------------ TABLE CREATIONS ------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- DONE:
# Initially set the table data types up to match the maximum data values in the table:
	# Adjusted DEC datatypes in sales table to allow for large aggregate sums (DEC(12,2) perhaps, example: 1,234,567,899.55)
	# Adjusted varchars across the board to accountfor potential INSERTS of larger size than current alloance
    
# Add CHECK constraint to 'customer_loyalty_member_status' to make sure user can only input 1 or 0
# Add a trigger to 'customer_join_date' so when it set to 1 it inserts todays date
# SET COLUMNS EQUAL TO NOT NULL SO INSERTS ARE EXPLICIT AND ALL COLUMNS NEED DATA FOR AN INSERT TO WORK
# Clean the sales table
# Add those two triggers to the 'sales' table
# Need to make sure each entry has unique product_name per brand!!!
# Add the VIEW: Product_Brand_Performance: GROUP BY product_brand and get total revenue, total sales, average sale amount




-- Note that the table CREATES below have been updated as the project went on to reflect the changes needed to perfect the data base and
-- DO NOT represent the insitial state of the tables when the data import was done. I have commented specifically what was changed below.

-- customers table which keeps track of customer data:
CREATE TABLE IF NOT EXISTS customers (
	customer_id INT PRIMARY KEY AUTO_INCREMENT, 
    customer_age INT NOT NULL, 
    customer_gender VARCHAR(6) NOT NULL, 
    customer_loyalty_member_status INT NOT NULL DEFAULT 0, -- Default to customer NOT being a loyalty member (i.e. 0)
    customer_join_date DATE, -- Tigger Column (Don't need to INSERT data here)
    CONSTRAINT chk_customer_gender CHECK (customer_gender IN ('Male', 'Female')), -- make sure input is only 'Male' or 'Female'
    CONSTRAINT chk_customer_loyalty_value CHECK (customer_loyalty_member_status IN (0, 1)) -- make sure values can only be 0 or 1 
);

-- products table which keeps track of product data:
CREATE TABLE IF NOT EXISTS products (
	product_id INT PRIMARY KEY AUTO_INCREMENT, 
    product_name VARCHAR(50) NOT NULL UNIQUE, -- so that 'product_name' can not be duplicated (UNIQUE added after data cleaning)
    product_brand VARCHAR(20) NOT NULL,
    product_category VARCHAR(20) NOT NULL,
    product_cocoa_percent INT NOT NULL, 
    product_weight_grams INT NOT NULL,
    product_unit_price DEC(11,2) DEFAULT 0.00 -- THIS COLUMN WAS ADDED AFTER DATA IMPORT DURING DATA CLEANING PHASE!!!
);


-- sales MASTER table which shows all of the customers and the prodcts they bought, as well as sales data.
CREATE TABLE IF NOT EXISTS sales (
	sale_id INT PRIMARY KEY AUTO_INCREMENT, 
    sale_date DATE DEFAULT (CURRENT_DATE),    -- Current date is filled here upon new row entry (makes sense for sale)
    sale_product_id INT NOT NULL, 
    sale_store_id INT NOT NULL,
    sale_customer_id INT NOT NULL,  
    sale_quantity INT NOT NULL, 
    -- sale_unit_price DEC(11,2) NOT NULL,    -- THIS COLUMN WAS DROPPED DURING DATA CLEANING PHASE (MOVED TO products table)!!!
    sale_discount_percent DEC(11,2) DEFAULT 0.00, -- Range: -999,999,999.99 to +999,999,999.99
    sale_revenue DEC(11,2) NOT NULL,              -- Range: -999,999,999.99 to +999,999,999.99
    sale_cost DEC(11,2) NOT NULL,                 -- Range: -999,999,999.99 to +999,999,999.99
    sale_profit DEC(11,2) NOT NULL,               -- Range: -999,999,999.99 to +999,999,999.99
    -- Foreign Keys & Constraints:
    FOREIGN KEY(sale_product_id) REFERENCES products(product_id),    -- links to products table
    FOREIGN KEY(sale_store_id) REFERENCES stores(store_id),          -- links to stores table
    FOREIGN KEY(sale_customer_id) REFERENCES customers(customer_id), -- links to customers table
    CONSTRAINT chk_discount_value CHECK (sale_discount_percent BETWEEN 0 AND 1), -- so that 'sale_discount_percent' is in range
    CONSTRAINT chk_cost_vs_revenue CHECK (sale_cost <= sale_revenue)             -- so that 'sale_profit' can't be < 0    
);

-- stores table which tracks the data for the stores that sells the products:
CREATE TABLE IF NOT EXISTS stores (
	store_id INT PRIMARY KEY AUTO_INCREMENT, 
    store_name VARCHAR(20) NOT NULL UNIQUE,
    store_city VARCHAR(20) NOT NULL,
    store_country VARCHAR(20) NOT NULL, 
    store_type VARCHAR(20) NOT NULL 
);


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 									 ------------ DATA IMPORT ------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
/* Since we have the CSV files from Kaggle with the data we want to imoprt already, we can import as follows:
	1.) Under "Schemas" on the top left, expand "tables" and right-click on the table you want to import data onto
    2.) Select "Table Data Import Wizard"
    3.) Browse to find the CSV with the data you wish to import
    4.) Since I made the tables already, I select "Use Existing Table"
    5.) It will show you a mapping and example output, make sure it is correct and then finish the import
		NOTE: For 'sales' table I had to deselect the 'Source Column' side because the source data was empty and I wanted 
              it to follow the auto increment constraint on the empty 'sales' table (works because value cant be NULL)
*/


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 									 ------------ DATA CLEANING ------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
/* The data is what I wanted but it appears to be randomly generated which leads to a few contradictions that I need to clean.
   The goal is to clean the data so it is believable, eventhough randomly generated, it makes for good practice.
   
	1.) stores table: there is a list of a few cities that were repeated throughout the 'store_city' col and in the same
		rows as incorrect 'store_country' values.
        SOLUTION: I will SET each row with a specific 'store_country' equal to a city that is actually in that country:
				  After this, I can go back in and SET 'store_city' equal to varrying cities per country based on 'customer_id' 
                  or something to make the dataset more believable.
        EXAMPLE: 
        
			UPDATE stores
			SET store_city = "New York"
			WHERE store_country = "USA";
            
            AND THEN AFTER FOR MORE VARIATION
            
            UPDATE stores
			SET store_city = "Long Island"
			WHERE store_country = "USA" AND
				  store_id % 2 = 0;
			
            AS WELL AS
            
			UPDATE stores
			SET store_city = "Buffalo"
			WHERE store_country = "USA" AND
				  store_id % 5 = 0;
            
        Need to do this for:
			• USA
            • UK
            • Germany
            • Australia
            • France
            • Canada
        
    2.) Similar to problem 1, the 'product_category' was randolmy assigned to 'product_name'. So where we have a product_name
		of "Dark Chocolate 80%" we also have product_category of "Milk" when it should be "Dark".
        SOLUTION: 
        
			UPDATE proucts
			SET product_category = "Milk"
			WHERE product_name LIKE "Milk%";
            
		Need to do this for:
			• Dark
            • Milk
            • Praline
            • Truffle
            • White
            
	3.) On the customers table ALL customers had 'customer_join_date' values, even if they weren't a loyalty member.
		To fix this, we just run the following:
			
            UPDATE customers
			SET customer_join_date= NULL
			WHERE customer_loyalty_member_status = 0;
            
	4.) Need to fix the 'sale_unit_price' on 'sales' problem so that it is the same per product (products should have same unit $).
		FIX:
			STRATEGY FOR DATABASE NORMALIZATION:
			Goal: Ensure price consistency across 500,000 rows without manual data entry.

			Step 1: Add a 'product_price' column to the 'products' table.
			   Why: This creates a single "Source of Truth" for what an item costs.

			Step 2: Calculate the "Master Price" for each product from the existing sales data.
			   Why: Since your current sales data has multiple prices for the same ID, 
			        we need to decide on a single standard (like an Average or Max).

			Step 3: Update the 'products' table with these calculated Master Prices.
			   Why: This moves the historical price data into its new permanent home.

			Step 4: Remove 'sale_unit_price' from the 'sales' table.
			   Why: To save storage space and prevent any data anomolies.
		
        
        STEP 1.) Add a 'product_unit_price' to 'products' table:
        
			ALTER TABLE products
			ADD COLUMN product_unit_price DEC(11,2) DEFAULT 0.00;
            
		STEPS 2 & 3.) Calculate the Master Price and Update products to fill in 'product_unit_price' column:
        
			UPDATE products p
			JOIN (
			-- This subquery finds the average price used in the ~500k sales rows
				SELECT sale_product_id, 
					   AVG(sale_unit_price) AS avg_price -- this will be the new unit price for the product!
				FROM sales
				GROUP BY sale_product_id
			) AS price_lookup ON p.product_id = price_lookup.sale_product_id
			SET p.product_unit_price = price_lookup.avg_price;

		STEP 4.) Clean up the sales table by DROPPING 'sale_unit_price':
				 NOTE: If this were actual hisorical data I WOULD NOT DROP THE DATA but since its generated data it's fine.
                 
			ALTER TABLE sales 
			DROP COLUMN sale_unit_price;
            
            
	5.) I noticed that on the 'products' table that there were brands that had duplicate product names: 
        (Cadbury had multiple Dark Chocolate 50% and so on). In an ideal world, every product ID should have a UNIQUE 
        'product_name'. Therefore, after renaming the 'product_name' column values, I will also add the UNIQUE
        constraint to this column so new INSERTS on 'products' won't result in duplicates:
        
        STEP 1.) Create the new product names:
				
                UPDATE products
				SET product_name = CONCAT(product_brand, ' ', product_name, ' (', product_weight_grams, 'g)');
        
        STEP 2.) After this, I noticed that there were STILL 17 'product_name' values duplicates with the follwoing querry:
        
				SELECT product_name, COUNT(*) AS count FROM products
				GROUP BY product_name
				HAVING count >1;
                
		STEP 3.) Since there are no other columns in 'products' to distinctly distinguish the duplicate rows, I have
                 decided to just append the 'product_id' to the duplicates as follows:
                 
                 UPDATE products p
				 JOIN (
				 	 -- This finds only the names that have duplicates
					 SELECT product_name 
					 FROM products 
					 GROUP BY product_name 
					 HAVING COUNT(*) > 1
				 ) AS dupes ON p.product_name = dupes.product_name
				 SET p.product_name = CONCAT(p.product_name, ' [ID:', p.product_id, ']');
                 
		STEP 4.) Now that all'product_names' values are UNIQUE, I will add the UNIQUE constraint to the 'products' table and.
                 revise the CREATE statement to contain the UNIQUE constraint for future INSERTS on 'products':
                 
                 ALTER TABLE products
				 ADD CONSTRAINT
				 UNIQUE (product_name);
        
	
*/


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 									  ------------ TRIGGERS ------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Trigger to SET 'customer_join_date' = Null when 'customer_loyalty_member_status' is SET to 0 
-- AND
-- Trigger to SET 'customer_join_date' = Today's Date when 'customer_loyalty_member_status' is SET to 1 

DELIMITER //
CREATE TRIGGER before_customer_loyalty_update
BEFORE UPDATE ON customers
FOR EACH ROW
BEGIN
    -- Check if status is set to 0:
    IF NEW.customer_loyalty_member_status = 0 THEN
        SET NEW.customer_join_date = NULL;
    
    -- Check if status is set to 1:
    ELSEIF NEW.customer_loyalty_member_status = 1 THEN
        SET NEW.customer_join_date = CURDATE();
    END IF;
END //
DELIMITER ;

	/* NOTE:
		• NEW vs OLD: NEW refers to the incoming value from the UPDATE statement, while OLD refers to what is currently
          in the database.
		• BEGIN...END: This block is required whenever the trigger contains more than one logic line or an IF statement.
	*/
    
    
-- Triggers to automatically calculate the 'sale_revenue' and 'sale_profit' based on quantity, p.unit price, discount, and cost.
	# 1.) 'sale_revenue' = sale_quantity * product_unit_price * (1 - sale_discount_percent)
    # 2.) 'sale_profit' = sale_revenue - sale_cost 
    
DELIMITER //
CREATE TRIGGER before_sale_insert
BEFORE INSERT ON sales
FOR EACH ROW
BEGIN
    -- 1. Create a variable to hold the price from the products table:
    DECLARE current_unit_price DECIMAL(11,2);

    -- 2. Look up the price for the specific product being sold:
    SELECT product_unit_price INTO current_unit_price
    FROM products
    WHERE product_id = NEW.sale_product_id;

    -- 3. Calculate Revenue: quantity * price * (1 - discount):
    SET NEW.sale_revenue = (NEW.sale_quantity * current_unit_price) * (1 - NEW.sale_discount_percent);

    -- 4. Calculate Profit: revenue - cost
    SET NEW.sale_profit = NEW.sale_revenue - NEW.sale_cost;
END //
DELIMITER ;
    
    /* NOTE:
		• Since I moved the 'product_unit_price'to the 'products' table, the trigger needs to perform a "lookup" to find 
          the current price of the item being sold before it can do the math.
		• This is a BEFORE INSERT trigger so that we ensure the calculations happen before the data is actually saved to the disk!
		• Notice the SELECT ... INTO. Because the price lives in a different table, the trigger effectively "reaches out" 
          to the products table the moment a sale starts.
	*/
    
    
-- Trigger to automatically generate the 'product_name' beofre an INSERT on the 'products' table:

DELIMITER //
CREATE TRIGGER before_product_insert
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    -- This builds the name: Brand + Category + Weight
    -- Example: 'Cadbury Dark (100g)'
    SET NEW.product_name = CONCAT(
        NEW.product_brand, ' ', 
        NEW.product_category, ' (', 
        NEW.product_weight_grams, 'g)'
    );
END //
DELIMITER ;
    

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 									    ------------ VIEWS ------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Sales Summary View (CORE VIEW):
CREATE OR REPLACE VIEW sales_summary AS
SELECT
    s.sale_id,
    s.sale_date,
    c.customer_id,
    c.customer_gender,
    c.customer_loyalty_member_status,
    p.product_id,
    p.product_brand,
    p.product_name,
    p.product_category,
    st.store_city,
    st.store_country,
    s.sale_quantity,
    p.product_unit_price,
    s.sale_revenue,
    s.sale_cost,
    s.sale_profit
FROM sales s
JOIN customers c ON s.sale_customer_id = c.customer_id
JOIN products p ON s.sale_product_id = p.product_id
JOIN stores st ON s.sale_store_id = st.store_id
ORDER BY 
	s.sale_date, 
	c.customer_loyalty_member_status DESC, 
    p.product_name, 
    st.store_country, 
    s.sale_quantity DESC; 
    
    -- NOTE: the 'OR REPLACE' keyword is advantageous because it allows editor to adjust the view and rerun this code block
	--       to replace the VIEW, INSTEAD OF HAVING TO RUN A 'DROP VIEW' command!


-- Monthly Sales Trend View:
CREATE OR REPLACE VIEW monthly_sales AS
SELECT
    DATE_FORMAT(sale_date, '%Y-%m') AS `year_month`,
    SUM(sale_quantity) AS units_sold,
    ROUND(SUM(sale_revenue), 2) AS total_revenue,
    ROUND(AVG(sale_revenue), 2) AS avg_transaction_value,
    ROUND(SUM(sale_profit), 2) AS total_profit,
    ROUND(AVG(sale_profit), 2) AS avg_profits
FROM sales
GROUP BY `year_month`
ORDER BY SUM(sale_profit) DESC;


-- Yearly Sales Trend View:
CREATE OR REPLACE VIEW yearly_sales AS
SELECT
    DATE_FORMAT(sale_date, '%Y') AS `year`,
    SUM(sale_quantity) AS units_sold,
    ROUND(SUM(sale_revenue), 2) AS total_revenue,
    ROUND(AVG(sale_revenue), 2) AS avg_transaction_value,
    ROUND(SUM(sale_profit), 2) AS total_profit,
    ROUND(AVG(sale_profit), 2) AS avg_profits
FROM sales
GROUP BY `year`
ORDER BY SUM(sale_profit) DESC;


-- Product Performance View:
CREATE OR REPLACE VIEW product_performance AS
SELECT
    p.product_id AS id,
    p.product_name AS product_name,
    p.product_brand AS product_brand,
    p.product_category AS product_category,
    SUM(s.sale_quantity) AS units_sold,
    SUM(s.sale_revenue) AS total_revenue,
    ROUND(AVG(sale_revenue), 2) AS avg_transaction_value,
    SUM(s.sale_profit) AS total_profit,
    ROUND(AVG(sale_profit), 2) AS avg_profits,
    ROUND((SUM(s.sale_profit) / SUM(s.sale_revenue)) * 100, 2) AS profit_margin_percent
FROM products p
JOIN sales s ON p.product_id = s.sale_product_id
GROUP BY 
    p.product_id, 
    p.product_name, 
    p.product_brand, 
    p.product_category
ORDER BY total_profit DESC, units_sold DESC;


-- Product Brand Performance View:
CREATE OR REPLACE VIEW product_brand_performance AS
SELECT
    p.product_brand AS brand,
    COUNT(DISTINCT p.product_id) AS total_unique_products,
    SUM(s.sale_quantity) AS units_sold,
    SUM(s.sale_revenue) AS total_revenue,
    ROUND(AVG(sale_revenue), 2) AS avg_transaction_value,
    SUM(s.sale_profit) AS total_profit,
    ROUND(AVG(sale_profit), 2) AS avg_profits,
    -- Added a margin calculation for extra insight
    ROUND((SUM(s.sale_profit) / SUM(s.sale_revenue)) * 100, 2) AS profit_margin_percent
FROM products p
JOIN sales s ON p.product_id = s.sale_product_id
GROUP BY p.product_brand
ORDER BY total_profit DESC, units_sold DESC;


--  Product Category Performance View:
CREATE OR REPLACE VIEW product_category_performance AS
SELECT
    p.product_category AS category,
    SUM(s.sale_quantity) AS units_sold,
    SUM(s.sale_revenue) AS total_revenue,
    ROUND(SUM(s.sale_revenue) / SUM(s.sale_quantity), 2) AS avg_revenue_per_unit,
    SUM(s.sale_profit) AS total_profit,
    -- Average revenue and profit per unit to see which category is performing best:
    ROUND(SUM(s.sale_profit) / SUM(s.sale_quantity), 2) AS avg_profit_per_unit,
    ROUND((SUM(s.sale_profit) / SUM(s.sale_revenue)) * 100, 2) AS profit_margin_percent
FROM products p
JOIN sales s ON p.product_id = s.sale_product_id
GROUP BY p.product_category
ORDER BY total_profit DESC, units_sold DESC;


-- Customer Lifetime Value View:
CREATE OR REPLACE VIEW customer_lifetime_value AS
SELECT
    c.customer_id,
    c.customer_loyalty_member_status,
    COUNT(s.sale_id) AS total_orders,
    SUM(s.sale_revenue) AS total_revenue,
    ROUND(AVG(s.sale_revenue), 2) AS avg_transaction_value,
    SUM(s.sale_profit) AS total_profit,
    ROUND(AVG(s.sale_profit), 2) AS avg_sale_profit
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.sale_customer_id
GROUP BY c.customer_id
ORDER BY SUM(s.sale_profit) DESC; -- Show the most profitable customers first


-- Loyalty Member Analysis View:
CREATE OR REPLACE VIEW loyalty_member_analysis AS
    SELECT
        c.customer_loyalty_member_status,
        COUNT(DISTINCT c.customer_id) AS num_customers,
        SUM(s.sale_quantity) AS units_sold,
        SUM(s.sale_revenue) AS total_revenue,
        ROUND(AVG(s.sale_revenue), 2) AS avg_transaction_value,
        SUM(s.sale_profit) AS total_profits,
        ROUND(AVG(s.sale_profit), 2) AS avg_sale_profit
    FROM customers c
    JOIN sales s ON c.customer_id = s.sale_customer_id
    GROUP BY c.customer_loyalty_member_status;


-- Customer Gender Value View:
CREATE OR REPLACE VIEW customer_gender_analysis AS
SELECT
    c.customer_gender,
    COUNT(s.sale_id) AS total_orders,
    SUM(s.sale_quantity) AS units_sold,
    SUM(s.sale_revenue) AS total_revenue,
	ROUND(AVG(s.sale_revenue), 2) AS avg_transaction_value,
	SUM(s.sale_profit) AS total_profits,
	ROUND(AVG(s.sale_profit), 2) AS avg_sale_profit
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.sale_customer_id
GROUP BY c.customer_gender
ORDER BY SUM(s.sale_profit) DESC; -- Show the most profitable customers first


-- Store Performance View:
CREATE OR REPLACE VIEW store_performance AS
SELECT
    st.store_id,
    st.store_name,
    st.store_country,
    st.store_city,
    SUM(s.sale_quantity) AS units_sold,
    SUM(s.sale_revenue) AS total_revenue,
    ROUND(AVG(s.sale_revenue), 2) AS avg_transaction_value,
    SUM(s.sale_profit) AS total_profit,
    ROUND(AVG(s.sale_profit), 2) AS avg_sale_profit
FROM stores st
JOIN sales s ON st.store_id = s.sale_store_id
GROUP BY st.store_id, st.store_city, st.store_country
ORDER BY SUM(s.sale_profit) DESC;


-- Top Products per store View:
CREATE OR REPLACE VIEW ranked_products_per_store AS
SELECT
        st.store_id,
        st.store_name,
        p.product_name,
        SUM(s.sale_quantity) AS total_sold,
        RANK() OVER (
            PARTITION BY st.store_id
            ORDER BY SUM(s.sale_quantity) DESC
        ) AS rank_in_store
    FROM sales s
    JOIN products p ON s.sale_product_id = p.product_id
    JOIN stores st ON s.sale_store_id = st.store_id
    GROUP BY st.store_id, p.product_name;


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 								   ------------ STROED PROCEDURES ------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Sales Summary Between Specified Date Range:
DELIMITER //
CREATE PROCEDURE get_sales_by_date(
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    SELECT *
    FROM sales_summary
    WHERE sale_date BETWEEN start_date AND end_date
    ORDER BY sale_date;
END //
DELIMITER ;


-- Get Product Performance by Category:
DELIMITER //
CREATE PROCEDURE get_product_by_category(IN category_name VARCHAR(50))
BEGIN
    SELECT *
    FROM product_performance
    WHERE product_category = category_name
    ORDER BY total_profit DESC;
END //
DELIMITER ;


-- Get Customers who spend over a certain amount per a given year:
DELIMITER //
CREATE PROCEDURE get_top_non_loyal_customers_by_year(
    IN min_spend DECIMAL(10,2),
    IN target_year INT  
)
BEGIN
    SELECT
        c.customer_id,
        SUM(s.sale_revenue) AS total_spent
    FROM customers c
    JOIN sales s ON c.customer_id = s.sale_customer_id
    WHERE c.customer_loyalty_member_status = 0 -- filter for this column BEFORE the GROUP cluase!
      AND YEAR(s.sale_date) = target_year  
    GROUP BY c.customer_id
    HAVING total_spent >= min_spend
    ORDER BY total_spent DESC; -- Show largest spenders first
END //
DELIMITER ;


-- Ranked Product per Store Procedure:
DELIMITER //
CREATE PROCEDURE get_ranked_products_per_store(IN input_store_id INT)
BEGIN
    SELECT 
        st.store_id,
        st.store_name, 
        p.product_name,
        SUM(s.sale_quantity) AS total_sold,
        RANK() OVER (
            ORDER BY SUM(s.sale_quantity) DESC
        ) AS rank_in_store
    FROM sales s
    JOIN products p ON s.sale_product_id = p.product_id
    JOIN stores st ON s.sale_store_id = st.store_id
    WHERE st.store_id = input_store_id  
    GROUP BY st.store_id, st.store_name, p.product_name;
END //
DELIMITER ;
