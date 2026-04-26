-- =========================================
-- 📊 E-Commerce Sales Analysis (MySQL)
-- Dataset: Olist Brazilian E-commerce
-- Author: Shubham Pathak
-- =========================================

-- =========================
-- 1. CREATE TABLES
-- =========================

CREATE TABLE orders (
order_id VARCHAR(50) PRIMARY KEY,
customer_id VARCHAR(50),
order_status VARCHAR(20),
order_purchase_timestamp DATETIME,
order_approved_at DATETIME,
order_delivered_carrier_date DATETIME,
order_delivered_customer_date DATETIME,
order_estimated_delivery_date DATETIME,
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
order_id VARCHAR(50),
order_item_id INT,
product_id VARCHAR(50),
seller_id VARCHAR(50),
shipping_limit_date DATETIME,
price DECIMAL(10,2),
freight_value DECIMAL(10,2),
PRIMARY KEY (order_id, order_item_id),
FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE products (
product_id VARCHAR(50) PRIMARY KEY,
product_category_name VARCHAR(100),
product_name_length INT,
product_description_length INT,
product_photos_qty INT,
product_weight_g INT,
product_length_cm INT,
product_height_cm INT,
product_width_cm INT
);

CREATE TABLE order_payments (
order_id VARCHAR(50),
payment_sequential INT,
payment_type VARCHAR(50),
payment_installments INT,
payment_value DECIMAL(10,2),
PRIMARY KEY (order_id, payment_sequential)
);

-- =========================
-- 2. DATA LOADING
-- =========================

SET FOREIGN_KEY_CHECKS = 0;

-- Orders
LOAD DATA INFILE 'path/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
order_id,
customer_id,
order_status,
@order_purchase_timestamp,
@order_approved_at,
@order_delivered_carrier_date,
@order_delivered_customer_date,
@order_estimated_delivery_date
)
SET
order_purchase_timestamp = NULLIF(@order_purchase_timestamp, ''),
order_approved_at = NULLIF(@order_approved_at, ''),
order_delivered_carrier_date = NULLIF(@order_delivered_carrier_date, ''),
order_delivered_customer_date = NULLIF(@order_delivered_customer_date, ''),
order_estimated_delivery_date = NULLIF(@order_estimated_delivery_date, '');

-- Products
LOAD DATA INFILE 'path/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
product_id,
product_category_name,
@product_name_length,
@product_description_length,
@product_photos_qty,
@product_weight_g,
@product_length_cm,
@product_height_cm,
@product_width_cm
)
SET
product_name_length = NULLIF(@product_name_length, ''),
product_description_length = NULLIF(@product_description_length, ''),
product_photos_qty = NULLIF(@product_photos_qty, ''),
product_weight_g = NULLIF(@product_weight_g, ''),
product_length_cm = NULLIF(@product_length_cm, ''),
product_height_cm = NULLIF(@product_height_cm, ''),
product_width_cm = NULLIF(@product_width_cm, '');

-- Order Items
LOAD DATA INFILE 'path/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Payments
LOAD DATA INFILE 'path/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- =========================
-- 3. BUSINESS ANALYSIS
-- =========================

-- 🔹 Total Revenue
SELECT SUM(payment_value) AS Total_Revenue
FROM order_payments;

-- 🔹 Monthly Orders
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
COUNT(*) AS total_orders
FROM orders
GROUP BY month
ORDER BY month;

-- 🔹 Monthly Revenue
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
SUM(op.payment_value) AS revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY month
ORDER BY month;

-- 🔹 Top 10 Product Categories by Sales
SELECT p.product_category_name,
COUNT(oi.order_id) AS total_sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_sales DESC
LIMIT 10;

-- 🔹 Top 10 Customers by Revenue
SELECT c.customer_unique_id,
SUM(op.payment_value) AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY c.customer_unique_id
ORDER BY total_revenue DESC
LIMIT 10;

-- 🔹 Repeat Customers
SELECT customer_id,
COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) > 1;

-- 🔹 Average Order Value (AOV)
SELECT SUM(payment_value) / COUNT(DISTINCT order_id) AS AOV
FROM order_payments;

-- 🔹 Revenue by Category
SELECT p.product_category_name,
SUM(oi.price) AS revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue DESC
LIMIT 10;
