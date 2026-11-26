-- Geo-Spatial Supply Chain & Inventory Intelligence
-- MySQL 8.0+ recommended. Import CSVs into tables with these names:
-- olist_orders, olist_order_items, olist_products, olist_sellers,
-- olist_customers, olist_geolocation, olist_order_payments,
-- olist_order_reviews, product_category_translation.
-- Use MySQL Workbench Table Data Import Wizard; retain source columns.

CREATE DATABASE IF NOT EXISTS geospatial_supply_chain;
USE geospatial_supply_chain;

-- Suggested data types for table creation before CSV import.
CREATE TABLE IF NOT EXISTS olist_orders (
  order_id VARCHAR(40) PRIMARY KEY,
  customer_id VARCHAR(40),
  order_status VARCHAR(30),
  order_purchase_timestamp DATETIME,
  order_approved_at DATETIME NULL,
  order_delivered_carrier_date DATETIME NULL,
  order_delivered_customer_date DATETIME NULL,
  order_estimated_delivery_date DATETIME NULL
);
CREATE TABLE IF NOT EXISTS olist_order_items (
  order_id VARCHAR(40), order_item_id INT, product_id VARCHAR(40), seller_id VARCHAR(40),
  shipping_limit_date DATETIME, price DECIMAL(12,2), freight_value DECIMAL(12,2)
);
CREATE TABLE IF NOT EXISTS olist_products (
  product_id VARCHAR(40) PRIMARY KEY, product_category_name VARCHAR(120),
  product_name_lenght INT, product_description_lenght INT, product_photos_qty INT,
  product_weight_g DECIMAL(12,2), product_length_cm DECIMAL(12,2),
  product_height_cm DECIMAL(12,2), product_width_cm DECIMAL(12,2)
);
CREATE TABLE IF NOT EXISTS olist_sellers (
  seller_id VARCHAR(40) PRIMARY KEY, seller_zip_code_prefix VARCHAR(10),
  seller_city VARCHAR(120), seller_state VARCHAR(10)
);
CREATE TABLE IF NOT EXISTS olist_customers (
  customer_id VARCHAR(40) PRIMARY KEY, customer_unique_id VARCHAR(40),
  customer_zip_code_prefix VARCHAR(10), customer_city VARCHAR(120), customer_state VARCHAR(10)
);
CREATE TABLE IF NOT EXISTS olist_geolocation (
  geolocation_zip_code_prefix VARCHAR(10), geolocation_lat DECIMAL(10,7),
  geolocation_lng DECIMAL(10,7), geolocation_city VARCHAR(120), geolocation_state VARCHAR(10)
);
CREATE TABLE IF NOT EXISTS olist_order_payments (
  order_id VARCHAR(40), payment_sequential INT, payment_type VARCHAR(40),
  payment_installments INT, payment_value DECIMAL(12,2)
);
CREATE TABLE IF NOT EXISTS olist_order_reviews (
  review_id VARCHAR(40), order_id VARCHAR(40), review_score INT,
  review_comment_title TEXT, review_comment_message TEXT,
  review_creation_date DATETIME, review_answer_timestamp DATETIME
);
CREATE TABLE IF NOT EXISTS product_category_translation (
  product_category_name VARCHAR(120), product_category_name_english VARCHAR(120)
);
