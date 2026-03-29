-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- SAFETY SETTINGS:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Safe Updates in case the user needs to perform an update:
SET SQL_SAFE_UPDATES = 0;
SET SQL_SAFE_UPDATES = 1;


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- TABLE SELECTS:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
SELECT * FROM sales;     
SELECT * FROM products;  
SELECT * FROM customers; 
SELECT * FROM stores;    


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- DATA INSERTION:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- sales table INSERT (usually the only INSERT needed unless adding a new customer, product, or store):
INSERT INTO sales ( 
    sale_product_id,       -- KEY: Current Range: 1 to 200 products
    sale_store_id,         -- KEY: Current Range: 1 to 100 stores
    sale_customer_id,      -- KEY: Current Range: 1 to 50,000 customers
    sale_quantity, 
    sale_discount_percent, -- Range: 0.00 to 1.00 (DEFAULT 0.00)
    sale_cost              -- Can't Exceed 'sale_revenue' (Check Constraint). Cost to make/deliver/produce product
) 
VALUES (200, 10, 45583, 5, 0.15, 10.46);

-- products table INSERT ('product_name' is automatically generated based on other INSERT values):
INSERT INTO products (
    product_brand, 
    product_category, 
    product_cocoa_percent, 
    product_weight_grams, 
    product_unit_price
) 
VALUES ('Lindt', 'Dark', 85, 100, 9.50);

-- customers table INSERT:
INSERT INTO customers (
    customer_age, 
    customer_gender, 
    customer_loyalty_member_status -- join date is determined by this value (tigger)
) 
VALUES (28, 'Female', 1);

-- stores table INSERT:
INSERT INTO stores (
	store_name, -- Use "Chocolate Store " + next 'store_id' value for consistency with dataset
    store_city, 
    store_country, 
    store_type
)
VALUES ('Chocolate Store 101', 'Paris', 'France', 'Boutique');


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- VIEWS: (each view should answer a business question, so after each VIEW comment what question it answers):
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- sales views:
SELECT * FROM sales_summary; -- CORE VIEW: Connects all tables. Shows all the inforamtion associated with a sale
SELECT * FROM monthly_sales; -- To see the rank of most to least profitable months for sales
SELECT * FROM yearly_sales; -- To see the rank of most to least profitable years for sales

-- product views:
SELECT * FROM product_performance; -- To see rank of most to least profitable products with aggregate values 
SELECT * FROM product_brand_performance; -- To see rank of specific product brands by total profits with aggregate values
SELECT * FROM product_category_performance; -- To see rank of specific product categories by total profits with aggregate values

-- customer views:
SELECT * FROM customer_lifetime_value; -- To see rank of most to least profitable customers
SELECT * FROM loyalty_member_analysis; -- To see the difference in transaction data between loyalty and non-loyalty members


-- store views:
SELECT * FROM store_performance; -- To see rank of most to least profitable stores with aggregate values (Store v Store)
SELECT * FROM ranked_products_per_store; -- To see rank of all products per store based on amount of units sold (prod v prod per store)



-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- STORED PROCEDURES (each stored procedure should answer a more specific business question than the views above):
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- VIEW Filters:
-- sales procedures:
CALL get_sales_by_date('2023-06-21', '2023-09-23'); -- Get the 'sales summary' for the summer of 2023 (Filter for 'sales_summary' VIEW)

-- product procedures:
CALL get_product_by_category('Milk'); -- Get the 'product_performance' for a specific category (Filter for the 'product_performance' VIEW)

-- customer procedures:
CALL get_top_non_loyal_customers_by_year(299.99, 2024); -- Could give a loyalty member status to customers who spend over a certain amount per year

-- store procedures:
CALL get_ranked_products_per_store(3); -- To see rank of all products for a given store (Filter for 'ranked_products_per_store' VIEW)








