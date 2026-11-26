-- PROJECT 4: GEO-SPATIAL SUPPLY CHAIN & INVENTORY INTELLIGENCE
-- Olist Brazilian E-Commerce Dataset | Database: geo_supply_chain
-- Currency values are in original dataset currency (BRL), not INR.
-- This dataset has no actual stock-on-hand, stock-out, warehouse inventory
-- snapshots, or upstream supplier lead-time data. Do not invent these metrics.
-- Seller means Olist marketplace seller, not necessarily upstream supplier.

USE geo_supply_chain;

-- 01. OVERALL BUSINESS PERFORMANCE (aggregate payments before joining)
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS customer_accounts,
    ROUND(SUM(COALESCE(p.order_payment_total, 0)), 2) AS total_payment_value_brl,
    ROUND(AVG(p.order_payment_total), 2) AS average_payment_per_order_brl
FROM orders o
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS order_payment_total
    FROM payments GROUP BY order_id
) p ON o.order_id = p.order_id;

-- 02. MONTHLY PAYMENT VALUE AND ORDER TREND
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(COALESCE(p.order_payment_total, 0)), 2) AS monthly_payment_value_brl
FROM orders o
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS order_payment_total
    FROM payments GROUP BY order_id
) p ON o.order_id = p.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- 03. TOP 10 PRODUCT CATEGORIES BY PRODUCT VALUE
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS item_rows,
    ROUND(SUM(oi.price), 2) AS product_value_brl
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY product_category
ORDER BY product_value_brl DESC
LIMIT 10;

-- 04. TOP 10 PRODUCTS BY PRODUCT VALUE
SELECT
    oi.product_id,
    COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS item_rows,
    ROUND(SUM(oi.price), 2) AS product_value_brl
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY oi.product_id, product_category
ORDER BY product_value_brl DESC
LIMIT 10;

-- 05. TOP 10 MARKETPLACE SELLERS BY PRODUCT VALUE
SELECT
    s.seller_id, s.seller_city, s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_value_brl
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY product_value_brl DESC
LIMIT 10;

-- 06. SELLER DISTRIBUTION BY STATE
SELECT seller_state, COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers
GROUP BY seller_state
ORDER BY total_sellers DESC;

-- 07. CUSTOMER DISTRIBUTION BY STATE
SELECT
    customer_state,
    COUNT(DISTINCT customer_id) AS customer_accounts,
    COUNT(DISTINCT customer_unique_id) AS unique_people
FROM customers
GROUP BY customer_state
ORDER BY customer_accounts DESC;

-- 08. PAYMENT METHOD ANALYSIS (payment record counts)
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS orders_using_method,
    ROUND(SUM(payment_value), 2) AS total_payment_value_brl,
    ROUND(AVG(payment_value), 2) AS average_payment_record_brl
FROM payments
GROUP BY payment_type
ORDER BY total_payment_value_brl DESC;

-- 09. AVERAGE ORDER VALUE (one summed payment amount per order)
SELECT
    COUNT(*) AS orders_with_payment,
    ROUND(SUM(order_payment_total), 2) AS total_payment_value_brl,
    ROUND(AVG(order_payment_total), 2) AS average_order_value_brl
FROM (
    SELECT order_id, SUM(payment_value) AS order_payment_total
    FROM payments GROUP BY order_id
) x;

-- 10. DELIVERY STATUS SUMMARY
SELECT
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered / No Timestamp'
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY delivery_status
ORDER BY total_orders DESC;

-- 11. LATE DELIVERY RATE (only rows with both actual and estimated dates)
SELECT
    COUNT(*) AS orders_with_delivery_dates,
    SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders,
    ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 2) AS late_delivery_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- 12. AVERAGE DELIVERY TIME IN DAYS
SELECT
    COUNT(*) AS delivered_orders_with_purchase_date,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, order_purchase_timestamp, order_delivered_customer_date) / 24.0), 2)
        AS average_delivery_days
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date >= order_purchase_timestamp;

-- 13. MONTHLY ORDER GROWTH (MySQL 8 window function)
WITH monthly AS (
    SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month, COUNT(*) AS total_orders
    FROM orders
    WHERE order_purchase_timestamp IS NOT NULL
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
),
with_previous AS (
    SELECT order_month, total_orders,
           LAG(total_orders) OVER (ORDER BY order_month) AS previous_month_orders
    FROM monthly
)
SELECT order_month, total_orders, previous_month_orders,
       ROUND(100.0 * (total_orders - previous_month_orders) / NULLIF(previous_month_orders, 0), 2)
           AS growth_percentage
FROM with_previous
ORDER BY order_month;

-- 14. CATEGORY-WISE PRODUCT VALUE AND FREIGHT
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS product_category,
    COUNT(*) AS item_rows,
    ROUND(SUM(oi.price), 2) AS product_value_brl,
    ROUND(SUM(oi.freight_value), 2) AS freight_value_brl,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS item_plus_freight_brl
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY product_category
ORDER BY product_value_brl DESC;

-- 15. REVIEW SCORE DISTRIBUTION
SELECT review_score, COUNT(*) AS review_records,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM reviews), 2) AS percentage
FROM reviews
GROUP BY review_score
ORDER BY review_score;

-- 16. AVERAGE REVIEW SCORE BY CATEGORY (reviews may repeat across categories in an order)
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS product_category,
    COUNT(r.review_id) AS joined_review_records,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM reviews r
JOIN order_items oi ON r.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY product_category
ORDER BY average_review_score ASC;

-- 17. FREIGHT COST BY SELLER STATE
SELECT
    s.seller_state,
    COUNT(*) AS item_rows,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_brl,
    ROUND(AVG(oi.freight_value), 2) AS average_freight_per_item_brl
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY total_freight_brl DESC;

-- 18. SELLER CONTRIBUTION TO TOTAL PRODUCT VALUE
SELECT
    s.seller_id, s.seller_state,
    ROUND(SUM(oi.price), 2) AS seller_product_value_brl,
    ROUND(100.0 * SUM(oi.price) / NULLIF((SELECT SUM(price) FROM order_items), 0), 2)
        AS percentage_of_total_product_value
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_state
ORDER BY seller_product_value_brl DESC
LIMIT 20;

-- 19. ORDER STATUS DISTRIBUTION
SELECT order_status, COUNT(*) AS total_orders,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 20. PAYMENT INSTALLMENT ANALYSIS
SELECT
    payment_installments,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(SUM(payment_value), 2) AS payment_value_brl,
    ROUND(AVG(payment_value), 2) AS average_payment_record_brl
FROM payments
GROUP BY payment_installments
ORDER BY payment_installments;

-- 21. REPEAT CUSTOMER ANALYSIS (customer_unique_id identifies repeat people)
WITH customer_orders AS (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS unique_customers,
    SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_order_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2)
        AS repeat_customer_percentage
FROM customer_orders;

-- 22. TOP 20 SELLER CITIES
SELECT seller_state, seller_city, COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers
GROUP BY seller_state, seller_city
ORDER BY total_sellers DESC
LIMIT 20;

-- 23. PRODUCT PRICE BAND ANALYSIS (BRL)
SELECT
    CASE
        WHEN price < 50 THEN 'Under 50'
        WHEN price < 100 THEN '50 to 99.99'
        WHEN price < 250 THEN '100 to 249.99'
        WHEN price < 500 THEN '250 to 499.99'
        ELSE '500 and above'
    END AS price_band_brl,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(SUM(price), 2) AS product_value_brl,
    ROUND(AVG(price), 2) AS average_item_price_brl
FROM order_items
GROUP BY price_band_brl
ORDER BY MIN(price);

-- 24. MONTHLY PAYMENT VALUE TREND
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS payment_value_brl
FROM orders o
JOIN payments p ON o.order_id = p.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- 25. BUSINESS PERFORMANCE SUMMARY (separate subqueries prevent join fan-out)
SELECT
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(DISTINCT customer_unique_id) FROM customers) AS unique_customers,
    (SELECT COUNT(DISTINCT seller_id) FROM sellers) AS marketplace_sellers,
    (SELECT ROUND(SUM(payment_value), 2) FROM payments) AS total_payment_value_brl,
    (SELECT ROUND(SUM(price), 2) FROM order_items) AS total_product_value_brl,
    (SELECT ROUND(SUM(freight_value), 2) FROM order_items) AS total_freight_value_brl,
    (SELECT ROUND(AVG(review_score), 2) FROM reviews) AS average_review_score;

-- END OF PROJECT 4 SQL ANALYSIS
