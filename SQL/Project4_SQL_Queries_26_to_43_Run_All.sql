/*
PROJECT 4 - GEO-SPATIAL SUPPLY CHAIN & INVENTORY INTELLIGENCE
SUPPLEMENTARY SQL AUDIT - QUERIES 26 TO 43

This file contains 18 additional SELECT-based queries.
It is separate from the original 25-query analysis file.

HOW TO RUN ALL QUERIES TOGETHER IN MYSQL WORKBENCH:
1. Open this .sql file in MySQL Workbench.
2. Make sure the connection is to your local MySQL server.
3. Click inside the SQL editor.
4. Press Ctrl + Shift + Enter (Execute All or Selection),
   or click the lightning-bolt button for Execute All/Selection.
5. Review the Action Output panel for errors and the Result Grid tabs.

NOTE:
- These queries are read-only SELECT statements (plus USE database).
- They do not insert, update, delete, or alter table data.
- Requires MySQL 8+ because Query 38 uses a recursive CTE and window function.
- Currency values are BRL.
- The dataset does not contain actual stock-on-hand or upstream supplier lead-time data.
*/

-- PROJECT 4: GEO-SPATIAL SUPPLY CHAIN & INVENTORY INTELLIGENCE
-- SUPPLEMENTARY SQL AUDIT (additional to the original 25 analysis queries)
-- Database: geo_supply_chain | MySQL 8+
-- Purpose: validate data quality, dates, keys, joins, and dashboard-ready outputs.
-- Currency is BRL. Seller = marketplace seller, NOT necessarily upstream supplier.
-- Olist does not contain actual inventory/stock-on-hand or upstream supplier lead-time data.

USE geo_supply_chain;

-- 26. DELIVERY DATE QUALITY: detect zero dates and NULLs
SELECT
    COUNT(*) AS total_orders,
    SUM(order_delivered_customer_date IS NULL) AS delivered_date_nulls,
    SUM(CAST(order_delivered_customer_date AS CHAR) LIKE '0000-00-00%') AS delivered_date_zero_values,
    SUM(order_estimated_delivery_date IS NULL) AS estimated_date_nulls,
    SUM(CAST(order_estimated_delivery_date AS CHAR) LIKE '0000-00-00%') AS estimated_date_zero_values
FROM orders;

-- 27. CORRECTED DELIVERY STATUS SUMMARY: explicitly exclude zero dates
SELECT
    CASE
        WHEN order_delivered_customer_date IS NULL
          OR CAST(order_delivered_customer_date AS CHAR) LIKE '0000-00-00%'
            THEN 'Not Delivered / Missing Timestamp'
        WHEN order_estimated_delivery_date IS NULL
          OR CAST(order_estimated_delivery_date AS CHAR) LIKE '0000-00-00%'
            THEN 'Missing Estimated Date'
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY delivery_status
ORDER BY total_orders DESC;

-- 28. CORRECTED LATE DELIVERY RATE: denominator includes only valid actual + estimated dates
SELECT
    COUNT(*) AS valid_delivery_date_orders,
    SUM(order_delivered_customer_date > order_estimated_delivery_date) AS late_orders,
    SUM(order_delivered_customer_date <= order_estimated_delivery_date) AS on_time_orders,
    ROUND(
        100.0 * SUM(order_delivered_customer_date > order_estimated_delivery_date)
        / NULLIF(COUNT(*), 0), 2
    ) AS late_delivery_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND CAST(order_delivered_customer_date AS CHAR) NOT LIKE '0000-00-00%'
  AND CAST(order_estimated_delivery_date AS CHAR) NOT LIKE '0000-00-00%';

-- 29. CORRECTED AVERAGE DELIVERY TIME: exclude zero actual delivery dates
SELECT
    COUNT(*) AS valid_delivered_orders,
    ROUND(AVG(TIMESTAMPDIFF(
        HOUR, order_purchase_timestamp, order_delivered_customer_date
    ) / 24.0), 2) AS average_delivery_days
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND CAST(order_delivered_customer_date AS CHAR) NOT LIKE '0000-00-00%'
  AND order_delivered_customer_date >= order_purchase_timestamp;

-- 30. PRIMARY-KEY CANDIDATE CHECK: duplicate IDs in core tables
SELECT 'orders.order_id' AS checked_key, COUNT(*) AS duplicate_groups
FROM (SELECT order_id FROM orders GROUP BY order_id HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'customers.customer_id', COUNT(*)
FROM (SELECT customer_id FROM customers GROUP BY customer_id HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'products.product_id', COUNT(*)
FROM (SELECT product_id FROM products GROUP BY product_id HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'sellers.seller_id', COUNT(*)
FROM (SELECT seller_id FROM sellers GROUP BY seller_id HAVING COUNT(*) > 1) d;

-- 31. NULL / EMPTY KEY CHECKS
SELECT 'orders.order_id' AS checked_key,
       SUM(order_id IS NULL OR TRIM(order_id) = '') AS null_or_empty_keys
FROM orders
UNION ALL
SELECT 'order_items.order_id',
       SUM(order_id IS NULL OR TRIM(order_id) = '')
FROM order_items
UNION ALL
SELECT 'order_items.product_id',
       SUM(product_id IS NULL OR TRIM(product_id) = '')
FROM order_items
UNION ALL
SELECT 'order_items.seller_id',
       SUM(seller_id IS NULL OR TRIM(seller_id) = '')
FROM order_items;

-- 32. ORPHAN RECORD CHECK: order items without a matching order
SELECT COUNT(*) AS order_items_without_matching_order
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 33. ORPHAN RECORD CHECK: order items without matching product or seller
SELECT
    SUM(p.product_id IS NULL) AS items_without_matching_product,
    SUM(s.seller_id IS NULL) AS items_without_matching_seller
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN sellers s ON oi.seller_id = s.seller_id;

-- 34. PAYMENT COVERAGE: orders with and without payment records
SELECT
    COUNT(*) AS total_orders,
    SUM(p.order_id IS NOT NULL) AS orders_with_payment,
    SUM(p.order_id IS NULL) AS orders_without_payment
FROM orders o
LEFT JOIN (
    SELECT DISTINCT order_id FROM payments
) p ON o.order_id = p.order_id;

-- 35. REVIEW COVERAGE: orders with and without review records
SELECT
    COUNT(*) AS total_orders,
    SUM(r.order_id IS NOT NULL) AS orders_with_review,
    SUM(r.order_id IS NULL) AS orders_without_review
FROM orders o
LEFT JOIN (
    SELECT DISTINCT order_id FROM reviews
) r ON o.order_id = r.order_id;

-- 36. REVIEW ID DUPLICATE AUDIT: inspect repeated review_id values; do not delete blindly
SELECT
    COUNT(*) AS review_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(*) - COUNT(DISTINCT review_id) AS extra_rows_beyond_distinct_ids
FROM reviews;

-- 37. SAFE JOIN VALIDATION: compare row counts before/after one-to-many joins
-- These joins can multiply rows; use pre-aggregated tables for order-level dashboard KPIs.
SELECT
    (SELECT COUNT(*) FROM orders) AS base_order_rows,
    (SELECT COUNT(*) FROM orders o JOIN order_items oi ON o.order_id = oi.order_id) AS rows_after_items_join,
    (SELECT COUNT(*) FROM orders o JOIN payments p ON o.order_id = p.order_id) AS rows_after_payments_join,
    (SELECT COUNT(*) FROM orders o JOIN reviews r ON o.order_id = r.order_id) AS rows_after_reviews_join;

-- 38. MONTH CALENDAR WITH ZERO-ORDER MONTHS: correct month-over-month growth
WITH RECURSIVE months AS (
    SELECT DATE_FORMAT(MIN(order_purchase_timestamp), '%Y-%m-01') AS month_start
    FROM orders
    WHERE order_purchase_timestamp IS NOT NULL
    UNION ALL
    SELECT DATE_FORMAT(DATE_ADD(STR_TO_DATE(month_start, '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m-01')
    FROM months
    WHERE STR_TO_DATE(month_start, '%Y-%m-%d') <
          (SELECT DATE_FORMAT(MAX(order_purchase_timestamp), '%Y-%m-01') FROM orders)
),
monthly_orders AS (
    SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01') AS month_start,
           COUNT(*) AS total_orders
    FROM orders
    WHERE order_purchase_timestamp IS NOT NULL
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01')
),
filled_months AS (
    SELECT m.month_start, COALESCE(mo.total_orders, 0) AS total_orders
    FROM months m
    LEFT JOIN monthly_orders mo ON mo.month_start = m.month_start
),
growth AS (
    SELECT month_start, total_orders,
           LAG(total_orders) OVER (ORDER BY month_start) AS previous_month_orders
    FROM filled_months
)
SELECT
    DATE_FORMAT(STR_TO_DATE(month_start, '%Y-%m-%d'), '%Y-%m') AS order_month,
    total_orders,
    previous_month_orders,
    ROUND(
        100.0 * (total_orders - previous_month_orders)
        / NULLIF(previous_month_orders, 0), 2
    ) AS month_over_month_growth_pct
FROM growth
ORDER BY month_start;

-- 39. DASHBOARD OUTPUT: monthly order + payment summary (payments aggregated per order first)
WITH payment_per_order AS (
    SELECT order_id, SUM(payment_value) AS order_payment_total
    FROM payments
    GROUP BY order_id
)
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(COALESCE(p.order_payment_total, 0)), 2) AS payment_value_brl,
    ROUND(AVG(p.order_payment_total), 2) AS average_order_value_brl
FROM orders o
LEFT JOIN payment_per_order p ON o.order_id = p.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- 40. DASHBOARD OUTPUT: category summary
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS product_category,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT oi.order_id) AS distinct_orders,
    ROUND(SUM(oi.price), 2) AS product_value_brl,
    ROUND(SUM(oi.freight_value), 2) AS freight_value_brl
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY product_category
ORDER BY product_value_brl DESC;

-- 41. DASHBOARD OUTPUT: seller performance summary
SELECT
    s.seller_id, s.seller_city, s.seller_state,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT oi.order_id) AS distinct_orders,
    ROUND(SUM(oi.price), 2) AS product_value_brl,
    ROUND(SUM(oi.freight_value), 2) AS freight_value_brl
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY product_value_brl DESC;

-- 42. DASHBOARD OUTPUT: customer-state summary
SELECT
    customer_state,
    COUNT(DISTINCT customer_id) AS customer_accounts,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers
GROUP BY customer_state
ORDER BY unique_customers DESC;

-- 43. DASHBOARD OUTPUT: payment method summary
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(SUM(payment_value), 2) AS payment_value_brl,
    ROUND(AVG(payment_value), 2) AS average_payment_record_brl
FROM payments
GROUP BY payment_type
ORDER BY payment_value_brl DESC;

-- END OF SUPPLEMENTARY AUDIT
