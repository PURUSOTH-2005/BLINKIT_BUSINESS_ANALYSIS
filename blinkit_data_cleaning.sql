-- =============================================================
-- Blinkit Data Cleaning Project
-- Author: [Your Name]
-- Date: 2024
-- Description: SQL cleaning scripts for all 8 Blinkit tables
-- =============================================================


-- =============================================================
-- Table 1: customers
-- Issues fixed:
--   1. phone column stored as integer → convert to string with +91 prefix
--   2. registration_date stored as string → convert to DATE
-- =============================================================

CREATE TABLE customers_cleaned AS
SELECT
    customer_id,
    customer_name,
    email,
    CONCAT('+', CAST(phone AS VARCHAR)) AS phone,  -- was integer like 912987579691
    address,
    area,
    pincode,
    CAST(registration_date AS DATE) AS registration_date,
    customer_segment,
    total_orders,
    avg_order_value
FROM customers;


-- =============================================================
-- Table 2: orders
-- Issues fixed:
--   1. order_date, promised_delivery_time, actual_delivery_time
--      were stored as plain strings → convert to TIMESTAMP
-- =============================================================

CREATE TABLE orders_cleaned AS
SELECT
    order_id,
    customer_id,
    CAST(order_date             AS TIMESTAMP) AS order_date,
    CAST(promised_delivery_time AS TIMESTAMP) AS promised_delivery_time,
    CAST(actual_delivery_time   AS TIMESTAMP) AS actual_delivery_time,
    delivery_status,
    order_total,
    payment_method,
    delivery_partner_id,
    store_id
FROM orders;


-- =============================================================
-- Table 3: order_items
-- No issues found. Copied as-is.
-- =============================================================

CREATE TABLE order_items_cleaned AS
SELECT * FROM order_items;


-- =============================================================
-- Table 4: products
-- No issues found. Copied as-is.
-- =============================================================

CREATE TABLE products_cleaned AS
SELECT * FROM products;


-- =============================================================
-- Table 5: delivery_performance
-- Issues fixed:
--   1. delivery_time_minutes had 1563 negative values (early arrivals)
--      → clipped to 0 (early delivery = on time, not negative)
--   2. reasons_if_delayed had 1902 NULLs for On Time orders
--      → filled with 'N/A - On Time'
--   3. promised_time, actual_time stored as strings → TIMESTAMP
-- =============================================================

CREATE TABLE delivery_performance_cleaned AS
SELECT
    order_id,
    delivery_partner_id,
    CAST(promised_time AS TIMESTAMP) AS promised_time,
    CAST(actual_time   AS TIMESTAMP) AS actual_time,
    CASE
        WHEN delivery_time_minutes < 0 THEN 0
        ELSE delivery_time_minutes
    END AS delivery_time_minutes,
    distance_km,
    delivery_status,
    CASE
        WHEN reasons_if_delayed IS NULL THEN 'N/A - On Time'
        ELSE reasons_if_delayed
    END AS reasons_if_delayed
FROM delivery_performance;


-- =============================================================
-- Table 6: customer_feedback
-- Issues fixed:
--   1. feedback_date stored as string → convert to DATE
-- =============================================================

CREATE TABLE customer_feedback_cleaned AS
SELECT
    feedback_id,
    order_id,
    customer_id,
    rating,
    feedback_text,
    feedback_category,
    sentiment,
    CAST(feedback_date AS DATE) AS feedback_date
FROM customer_feedback;


-- =============================================================
-- Table 7: marketing_performance
-- Issues fixed:
--   1. roas column: 5380 values were wrong (didn't match revenue/spend)
--      → recalculated as revenue_generated / spend
--   2. date column stored as string → convert to DATE
-- =============================================================

CREATE TABLE marketing_performance_cleaned AS
SELECT
    campaign_id,
    campaign_name,
    CAST(date AS DATE) AS date,
    target_audience,
    channel,
    impressions,
    clicks,
    conversions,
    spend,
    revenue_generated,
    ROUND(revenue_generated / NULLIF(spend, 0), 2) AS roas  -- recalculated
FROM marketing_performance;


-- =============================================================
-- Table 8: inventory
-- Issues fixed:
--   1. date was in DD-MM-YYYY format, all other tables use YYYY-MM-DD
--      → standardised to DATE type
-- =============================================================

-- PostgreSQL:
CREATE TABLE inventory_cleaned AS
SELECT
    product_id,
    TO_DATE(date, 'DD-MM-YYYY') AS date,
    stock_received,
    damaged_stock
FROM inventory;

-- MySQL (uncomment if using MySQL instead):
-- CREATE TABLE inventory_cleaned AS
-- SELECT
--     product_id,
--     STR_TO_DATE(date, '%d-%m-%Y') AS date,
--     stock_received,
--     damaged_stock
-- FROM inventory;


-- =============================================================
-- Quick row count check after cleaning
-- =============================================================

SELECT 'customers_cleaned'             AS table_name, COUNT(*) AS rows FROM customers_cleaned
UNION ALL
SELECT 'orders_cleaned',                              COUNT(*) FROM orders_cleaned
UNION ALL
SELECT 'order_items_cleaned',                         COUNT(*) FROM order_items_cleaned
UNION ALL
SELECT 'products_cleaned',                            COUNT(*) FROM products_cleaned
UNION ALL
SELECT 'delivery_performance_cleaned',                COUNT(*) FROM delivery_performance_cleaned
UNION ALL
SELECT 'customer_feedback_cleaned',                   COUNT(*) FROM customer_feedback_cleaned
UNION ALL
SELECT 'marketing_performance_cleaned',               COUNT(*) FROM marketing_performance_cleaned
UNION ALL
SELECT 'inventory_cleaned',                           COUNT(*) FROM inventory_cleaned;


-- =============================================================
-- Referential integrity checks
-- =============================================================

-- orders should only have valid customer_ids
SELECT COUNT(*) AS orders_with_invalid_customer
FROM orders_cleaned o
WHERE NOT EXISTS (
    SELECT 1 FROM customers_cleaned c WHERE c.customer_id = o.customer_id
);
-- expected: 0

-- order_items should only have valid order_ids
SELECT COUNT(*) AS items_with_invalid_order
FROM order_items_cleaned oi
WHERE NOT EXISTS (
    SELECT 1 FROM orders_cleaned o WHERE o.order_id = oi.order_id
);
-- expected: 0

-- order_items should only have valid product_ids
SELECT COUNT(*) AS items_with_invalid_product
FROM order_items_cleaned oi
WHERE NOT EXISTS (
    SELECT 1 FROM products_cleaned p WHERE p.product_id = oi.product_id
);
-- expected: 0

-- feedback should only have valid order_ids
SELECT COUNT(*) AS feedback_with_invalid_order
FROM customer_feedback_cleaned f
WHERE NOT EXISTS (
    SELECT 1 FROM orders_cleaned o WHERE o.order_id = f.order_id
);
-- expected: 0
