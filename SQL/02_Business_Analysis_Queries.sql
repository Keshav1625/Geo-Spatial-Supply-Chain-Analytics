-- MySQL 8.0+ | Olist historical analysis
-- IMPORTANT: Olist has no actual inventory stock snapshots, reorder points or supplier lead-time master data.
-- Seller is used as marketplace fulfillment partner proxy; do not call it a verified upstream supplier.

-- 01 Total historical order items (proxy for units ordered)
SELECT SUM(order_item_id IS NOT NULL) AS total_order_item_rows FROM olist_order_items;

-- 02 Distinct orders
SELECT COUNT(DISTINCT order_id) AS total_orders FROM olist_orders;

-- 03 Product-wise historical item count
SELECT product_id, COUNT(*) AS items_ordered FROM olist_order_items GROUP BY product_id ORDER BY items_ordered DESC;

-- 04 Top products by item revenue
SELECT product_id, SUM(price) AS item_revenue FROM olist_order_items GROUP BY product_id ORDER BY item_revenue DESC LIMIT 20;

-- 05 Seller-wise item volume
SELECT seller_id, COUNT(*) AS items_fulfilled FROM olist_order_items GROUP BY seller_id ORDER BY items_fulfilled DESC;

-- 06 Seller-wise gross item value
SELECT seller_id, SUM(price) AS item_value FROM olist_order_items GROUP BY seller_id ORDER BY item_value DESC;

-- 07 Average customer delivery time in days
SELECT AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS avg_delivery_days FROM olist_orders WHERE order_delivered_customer_date IS NOT NULL;

-- 08 Average delivery difference vs estimate (positive = late)
SELECT AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)) AS avg_days_vs_estimate FROM olist_orders WHERE order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL;

-- 09 Late-delivered order count
SELECT COUNT(*) AS late_orders FROM olist_orders WHERE order_delivered_customer_date > order_estimated_delivery_date;

-- 10 On-time delivery rate among delivered orders
SELECT 100.0 * SUM(order_delivered_customer_date <= order_estimated_delivery_date) / COUNT(*) AS on_time_pct FROM olist_orders WHERE order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL;

-- 11 Monthly order volume
SELECT DATE_FORMAT(order_purchase_timestamp,'%Y-%m') AS order_month, COUNT(*) AS orders FROM olist_orders GROUP BY DATE_FORMAT(order_purchase_timestamp,'%Y-%m') ORDER BY order_month;

-- 12 Category-wise ordered items
SELECT COALESCE(t.product_category_name_english,p.product_category_name) AS category, COUNT(*) AS items_ordered FROM olist_order_items i JOIN olist_products p ON i.product_id=p.product_id LEFT JOIN product_category_translation t ON p.product_category_name=t.product_category_name GROUP BY category ORDER BY items_ordered DESC;

-- 13 Seller state-wise distribution
SELECT seller_state, COUNT(*) AS sellers FROM olist_sellers GROUP BY seller_state ORDER BY sellers DESC;

-- 14 Customer state-wise order count
SELECT c.customer_state, COUNT(*) AS orders FROM olist_orders o JOIN olist_customers c ON o.customer_id=c.customer_id GROUP BY c.customer_state ORDER BY orders DESC;

-- 15 Freight as a share of item price by category
SELECT p.product_category_name, SUM(i.freight_value)/NULLIF(SUM(i.price),0) AS freight_to_price_ratio FROM olist_order_items i JOIN olist_products p ON i.product_id=p.product_id GROUP BY p.product_category_name ORDER BY freight_to_price_ratio DESC;

-- 16 Products with missing category
SELECT COUNT(*) AS products_missing_category FROM olist_products WHERE product_category_name IS NULL OR TRIM(product_category_name)='';

-- 17 Order status distribution
SELECT order_status, COUNT(*) AS order_count FROM olist_orders GROUP BY order_status ORDER BY order_count DESC;

-- 18 Seller delivery performance ranking (seller-attributed order lines)
WITH seller_orders AS (SELECT DISTINCT seller_id, order_id FROM olist_order_items), seller_delivery AS (SELECT so.seller_id, so.order_id, DATEDIFF(o.order_delivered_customer_date,o.order_estimated_delivery_date) AS days_vs_estimate FROM seller_orders so JOIN olist_orders o ON so.order_id=o.order_id WHERE o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL) SELECT seller_id, COUNT(*) AS delivered_orders, AVG(days_vs_estimate) AS avg_days_vs_estimate, SUM(days_vs_estimate<=0)/COUNT(*)*100 AS on_time_pct, DENSE_RANK() OVER (ORDER BY SUM(days_vs_estimate<=0)/COUNT(*) DESC) AS performance_rank FROM seller_delivery GROUP BY seller_id ORDER BY performance_rank;

-- 19 Product demand by month
SELECT i.product_id, DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS order_month, COUNT(*) AS items_ordered FROM olist_order_items i JOIN olist_orders o ON i.order_id=o.order_id GROUP BY i.product_id, DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') ORDER BY order_month, items_ordered DESC;

-- 20 Customer delivery delay buckets
SELECT CASE WHEN DATEDIFF(order_delivered_customer_date,order_estimated_delivery_date)<=0 THEN 'On or before estimate' WHEN DATEDIFF(order_delivered_customer_date,order_estimated_delivery_date)<=7 THEN '1-7 days late' ELSE 'More than 7 days late' END AS delivery_bucket, COUNT(*) AS orders FROM olist_orders WHERE order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL GROUP BY delivery_bucket;

-- 21 Average product dimensions and weight by category
SELECT product_category_name, AVG(product_weight_g) AS avg_weight_g, AVG(product_length_cm) AS avg_length_cm, AVG(product_height_cm) AS avg_height_cm, AVG(product_width_cm) AS avg_width_cm FROM olist_products GROUP BY product_category_name ORDER BY avg_weight_g DESC;

-- 22 Revenue by seller state
SELECT s.seller_state, SUM(i.price) AS item_revenue FROM olist_order_items i JOIN olist_sellers s ON i.seller_id=s.seller_id GROUP BY s.seller_state ORDER BY item_revenue DESC;

-- 23 Payment type mix
SELECT payment_type, COUNT(*) AS payment_records, SUM(payment_value) AS payment_value FROM olist_order_payments GROUP BY payment_type ORDER BY payment_value DESC;

-- 24 Orders with multiple sellers
SELECT order_id, COUNT(DISTINCT seller_id) AS seller_count FROM olist_order_items GROUP BY order_id HAVING COUNT(DISTINCT seller_id)>1 ORDER BY seller_count DESC;

-- 25 Review score by delivery-delay group
SELECT CASE WHEN o.order_delivered_customer_date<=o.order_estimated_delivery_date THEN 'On time/early' ELSE 'Late' END AS delivery_group, AVG(r.review_score) AS avg_review_score, COUNT(*) AS review_records FROM olist_orders o JOIN olist_order_reviews r ON o.order_id=r.order_id WHERE o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL GROUP BY delivery_group;
