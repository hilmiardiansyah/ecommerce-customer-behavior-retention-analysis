-- =====================================================
-- PROJECT: E-Commerce Customer Behavior & Retention
-- FILE: 01_data_validation.sql
-- DATABASE: olist_ecommerce
-- SCHEMA: olist
--
-- OBJECTIVE:
-- Validate data quality, completeness, and consistency
-- after importing the cleaned datasets into PostgreSQL.
--
-- DATA SOURCES:
-- 1. orders.csv          - Cleaned using Python
-- 2. customers.csv       - Cleaned using Python
-- 3. order_items.csv     - Cleaned using Python
-- 4. products.csv        - Cleaned using Python
-- 5. payments.csv        - Cleaned using Python
-- 6. order_reviews.csv   - Original Kaggle dataset
-- =====================================================


-- =====================================================
-- 1. ROW COUNT VALIDATION
-- =====================================================

-- Check the total number of records in each table

SELECT 'orders' AS table_name, COUNT(*) AS total_rows
FROM olist.orders

UNION ALL

SELECT 'customers', COUNT(*)
FROM olist.customers

UNION ALL

SELECT 'order_items', COUNT(*)
FROM olist.order_items

UNION ALL

SELECT 'products', COUNT(*)
FROM olist.products

UNION ALL

SELECT 'payments', COUNT(*)
FROM olist.payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM olist.order_reviews;

-- FINDING:
-- The six imported tables contain the following records:
-- - orders: 99,441 rows.
-- - customers: 99,441 rows.
-- - order_items: 112,650 rows.
-- - products: 32,951 rows.
-- - payments: 103,886 rows.
-- - order_reviews: 99,224 rows.
--
-- DECISION:
-- These row counts are documented as the baseline
-- for subsequent data validation and analysis.


-- =====================================================
-- 2. DUPLICATE REVIEW ID INVESTIGATION
-- =====================================================

-- Check duplicated review IDs

SELECT
    review_id,
    COUNT(*) AS total_occurrences
FROM olist.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY total_occurrences DESC, review_id;


-- Summarize duplicated review IDs

WITH duplicate_summary AS (
    SELECT
        review_id,
        COUNT(*) AS total_occurrences
    FROM olist.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS duplicated_review_ids,
    COUNT(*) FILTER (
        WHERE total_occurrences = 2
    ) AS review_ids_appearing_twice,
    COUNT(*) FILTER (
        WHERE total_occurrences = 3
    ) AS review_ids_appearing_three_times,
    SUM(total_occurrences - 1) AS excess_rows
FROM duplicate_summary;

-- FINDING:
-- 789 review IDs appear more than once.
-- 764 review IDs appear twice.
-- 25 review IDs appear three times.
-- A total of 814 rows are excess occurrences
-- beyond one record per review ID.
--
-- DECISION:
-- Duplicated review IDs are investigated further
-- before any records are removed.


-- Investigate duplicated review IDs and their content

WITH review_content AS (
    SELECT DISTINCT
        review_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    FROM olist.order_reviews
),
content_summary AS (
    SELECT
        review_id,
        COUNT(*) AS unique_review_contents
    FROM review_content
    GROUP BY review_id
)
SELECT
    r.review_id,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT r.order_id) AS unique_orders,
    c.unique_review_contents
FROM olist.order_reviews r
JOIN content_summary c
    ON r.review_id = c.review_id
GROUP BY
    r.review_id,
    c.unique_review_contents
HAVING COUNT(*) > 1
ORDER BY total_rows DESC, r.review_id
LIMIT 20;

-- FINDING:
-- The inspected sample contains duplicated review IDs
-- associated with different order IDs.
-- The sampled records have identical review content
-- across the inspected content attributes.
--
-- INTERPRETATION:
-- The inspected records are not exact row duplicates
-- because their order IDs are different.
--
-- NOTE:
-- These findings are based on the inspected sample
-- of 20 duplicated review IDs only.
-- They do not represent all 789 duplicated review IDs.
--
-- DECISION:
-- No records are deleted.
-- Duplicated review IDs are retained to preserve
-- their original order relationships.

-- =====================================================
-- 3. NULL VALUE VALIDATION
-- =====================================================


-- -----------------------------------------------------
-- 3.1. ORDERS TABLE
-- -----------------------------------------------------

-- Check NULL values in the orders table

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_timestamp,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_delivered_date,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated_date
FROM olist.orders;

-- FINDING:
-- The orders table contains 99,441 records.
-- No NULL values were found in key identification,
-- order status, purchase timestamp, or estimated
-- delivery timestamp columns.
--
-- NULL values were found in several order processing
-- date columns:
-- - order_approved_at: 160 NULL values.
-- - order_delivered_carrier_date: 1,783 NULL values.
-- - order_delivered_customer_date: 2,965 NULL values.
--
-- INTERPRETATION:
-- These NULL values may be related to incomplete,
-- canceled, or ongoing order processes.
-- Further investigation by order status is required.
--
-- DECISION:
-- NULL values are retained because they may represent
-- valid business conditions.


-- Check NULL delivery dates by order status

SELECT
    order_status,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS null_approved_at,
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS null_carrier_date,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS null_delivered_date
FROM olist.orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- FINDING:
-- NULL delivery dates are mostly associated with orders
-- that have not reached the delivery stage or were canceled.
--
-- Key observations:
-- - All 1,107 shipped orders have no delivery-to-customer date.
-- - Canceled and unavailable orders mostly have missing
--   delivery-related timestamps.
-- - 8 delivered orders have no customer delivery timestamp.
-- - 2 delivered orders have no carrier handover timestamp.
-- - 14 delivered orders have no approval timestamp.
--
-- DECISION:
-- Most NULL values are consistent with the order lifecycle.
-- Missing timestamps in delivered orders are flagged
-- for further investigation.
-- All original records are retained.


-- Investigate delivered orders with missing delivery dates

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM olist.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- FINDING:
-- 8 delivered orders have missing delivery-to-customer dates.
-- - 7 orders have a carrier handover timestamp.
-- - 1 order has neither a carrier handover timestamp
--   nor a delivery-to-customer timestamp.
--
-- All 8 orders have an estimated delivery date.
--
-- DECISION:
-- These records are flagged as data quality anomalies.
-- Missing delivery dates are not replaced with estimated dates.
-- Original records are retained for further analysis.


-- -----------------------------------------------------
-- 3.2. CUSTOMERS TABLE
-- -----------------------------------------------------

-- Check NULL values in the customers table

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS null_customer_id,
    COUNT(*) FILTER (
        WHERE customer_unique_id IS NULL
    ) AS null_customer_unique_id,
    COUNT(*) FILTER (
        WHERE customer_zip_code_prefix IS NULL
    ) AS null_zip_code,
    COUNT(*) FILTER (
        WHERE customer_city IS NULL
    ) AS null_city,
    COUNT(*) FILTER (
        WHERE customer_state IS NULL
    ) AS null_state
FROM olist.customers;

-- FINDING:
-- The customers table contains 99,441 records.
-- No NULL values were found in the inspected columns.
--
-- DECISION:
-- No NULL value treatment is required for this table.
-- All customer records are retained.


-- -----------------------------------------------------
-- 3.3. ORDER_ITEMS TABLE
-- -----------------------------------------------------

-- Check NULL values in the order_items table

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS null_order_id,
    COUNT(*) FILTER (
        WHERE order_item_id IS NULL
    ) AS null_order_item_id,
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS null_product_id,
    COUNT(*) FILTER (
        WHERE seller_id IS NULL
    ) AS null_seller_id,
    COUNT(*) FILTER (
        WHERE shipping_limit_date IS NULL
    ) AS null_shipping_limit_date,
    COUNT(*) FILTER (
        WHERE price IS NULL
    ) AS null_price,
    COUNT(*) FILTER (
        WHERE freight_value IS NULL
    ) AS null_freight_value
FROM olist.order_items;

-- FINDING:
-- The order_items table contains 112,650 records.
-- No NULL values were found in the inspected columns.
--
-- DECISION:
-- No NULL value treatment is required for this table.
-- All order item records are retained.


-- -----------------------------------------------------
-- 3.4. PRODUCTS TABLE
-- -----------------------------------------------------

-- Check NULL values in the products table

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS null_product_id,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS null_product_category,
    COUNT(*) FILTER (
        WHERE product_name_lenght IS NULL
    ) AS null_product_name_length,
    COUNT(*) FILTER (
        WHERE product_description_lenght IS NULL
    ) AS null_product_description_length,
    COUNT(*) FILTER (
        WHERE product_photos_qty IS NULL
    ) AS null_product_photos_qty,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS null_product_weight,
    COUNT(*) FILTER (
        WHERE product_length_cm IS NULL
    ) AS null_product_length,
    COUNT(*) FILTER (
        WHERE product_height_cm IS NULL
    ) AS null_product_height,
    COUNT(*) FILTER (
        WHERE product_width_cm IS NULL
    ) AS null_product_width
FROM olist.products;

-- FINDING:
-- The products table contains 32,951 records.
-- NULL values were found in the following attributes:
-- - product_category_name: 610.
-- - product_name_lenght: 610.
-- - product_description_lenght: 610.
-- - product_photos_qty: 610.
-- - product_weight_g: 2.
-- - product_length_cm: 2.
-- - product_height_cm: 2.
-- - product_width_cm: 2.
-- DECISION:
-- Missing product attributes are retained at this stage.
-- No values are replaced or deleted during this validation.
-- Further investigation is conducted to understand
-- the distribution of missing attributes.


-- Investigate products with missing attributes

SELECT
    COUNT(*) AS total_incomplete_products,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
          AND product_name_lenght IS NULL
          AND product_description_lenght IS NULL
          AND product_photos_qty IS NULL
    ) AS missing_all_four_attributes,

    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
          AND product_length_cm IS NULL
          AND product_height_cm IS NULL
          AND product_width_cm IS NULL
    ) AS missing_all_physical_attributes

FROM olist.products
WHERE product_category_name IS NULL
   OR product_name_lenght IS NULL
   OR product_description_lenght IS NULL
   OR product_photos_qty IS NULL
   OR product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL;

-- FINDING:
-- 611 products have at least one missing attribute.
--
-- Key observations:
-- - 610 products have NULL values in all four descriptive
--   attributes: category, name length, description length,
--   and photo quantity.
-- - 2 products have NULL values in all four physical
--   attributes: weight, length, height, and width.
--
-- NOTE:
-- The two groups overlap by one product.
-- Therefore, the total number of incomplete products
-- is 611 rather than 612.
--
-- DECISION:
-- Missing product attributes are retained at this stage.
-- No values are replaced with estimates because the
-- original product information is unavailable.
-- Further investigation may be required before using
-- these attributes in category or logistics analysis.


-- -----------------------------------------------------
-- 3.5. PAYMENTS TABLE
-- -----------------------------------------------------

-- Check NULL values in the payments table

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS null_order_id,
    COUNT(*) FILTER (
        WHERE payment_sequential IS NULL
    ) AS null_payment_sequential,
    COUNT(*) FILTER (
        WHERE payment_type IS NULL
    ) AS null_payment_type,
    COUNT(*) FILTER (
        WHERE payment_installments IS NULL
    ) AS null_payment_installments,
    COUNT(*) FILTER (
        WHERE payment_value IS NULL
    ) AS null_payment_value
FROM olist.payments;

-- FINDING:
-- The payments table contains 103,886 records.
-- No NULL values were found in the inspected columns.
--
-- DECISION:
-- No NULL value treatment is required for this table.
-- All payment records are retained.


-- -----------------------------------------------------
-- 3.6. ORDER_REVIEWS TABLE
-- -----------------------------------------------------

-- Check NULL values in the order_reviews table

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE review_id IS NULL
    ) AS null_review_id,
    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS null_order_id,
    COUNT(*) FILTER (
        WHERE review_score IS NULL
    ) AS null_review_score,
    COUNT(*) FILTER (
        WHERE review_comment_title IS NULL
    ) AS null_review_comment_title,
    COUNT(*) FILTER (
        WHERE review_comment_message IS NULL
    ) AS null_review_comment_message,
    COUNT(*) FILTER (
        WHERE review_creation_date IS NULL
    ) AS null_review_creation_date,
    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NULL
    ) AS null_review_answer_timestamp
FROM olist.order_reviews;

-- FINDING:
-- The order_reviews table contains 99,224 records.
-- No NULL values were found in review identifiers,
-- review scores, or review timestamps.
--
-- Missing values were found in comment attributes:
-- - review_comment_title: 87,656 NULL values (88.34%).
-- - review_comment_message: 58,247 NULL values (58.70%).
--
-- DECISION:
-- NULL comment values are considered acceptable because
-- customers can submit ratings without writing comments.
-- No NULL values are replaced or removed.
-- All review records are retained.


-- Analyze review comment completeness

SELECT
    CASE
        WHEN review_comment_title IS NULL
         AND review_comment_message IS NULL
            THEN 'No Title and No Message'

        WHEN review_comment_title IS NOT NULL
         AND review_comment_message IS NULL
            THEN 'Title Only'

        WHEN review_comment_title IS NULL
         AND review_comment_message IS NOT NULL
            THEN 'Message Only'

        ELSE 'Title and Message'
    END AS comment_status,
    COUNT(*) AS total_reviews
FROM olist.order_reviews
GROUP BY comment_status
ORDER BY total_reviews DESC;

-- FINDING:
-- Review comment completeness analysis shows:
-- - 56,518 reviews (56.96%) have neither title nor message.
-- - 31,138 reviews (31.38%) contain a message only.
-- - 9,839 reviews (9.92%) contain both title and message.
-- - 1,729 reviews (1.74%) contain a title only.
--
-- INSIGHT:
-- Most customers provide ratings without writing comments.
-- When customers write comments, they are more likely
-- to provide a message than a title.
--
-- DECISION:
-- Missing comment fields are treated as acceptable
-- business conditions rather than data quality errors.
-- All review records are retained.


-- =====================================================
-- 4. REFERENTIAL INTEGRITY VALIDATION
-- =====================================================

-- Check order_items references to orders

SELECT
    COUNT(*) AS orphan_order_items
FROM olist.order_items oi
LEFT JOIN olist.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- FINDING:
-- No orphan order items were found.
-- All order_items records reference existing orders.
--
-- DECISION:
-- Referential integrity between order_items and orders
-- is maintained based on this validation.


-- Check order_items references to products

SELECT
    COUNT(*) AS orphan_order_items
FROM olist.order_items oi
LEFT JOIN olist.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- FINDING:
-- No orphan order items were found.
-- All order_items records reference existing products.
--
-- DECISION:
-- Referential integrity between order_items and products
-- is maintained based on this validation.


-- Check orders references to customers

SELECT
    COUNT(*) AS orphan_orders
FROM olist.orders o
LEFT JOIN olist.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- FINDING:
-- No orphan orders were found.
-- All orders reference existing customer records.
--
-- DECISION:
-- Referential integrity between orders and customers
-- is maintained based on this validation.


-- Check payments references to orders

SELECT
    COUNT(*) AS orphan_payments
FROM olist.payments p
LEFT JOIN olist.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- FINDING:
-- No orphan payment records were found.
-- All payment records reference existing orders.
--
-- DECISION:
-- Referential integrity between payments and orders
-- is maintained based on this validation.


-- Check order_reviews references to orders

SELECT
    COUNT(*) AS orphan_reviews
FROM olist.order_reviews r
LEFT JOIN olist.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- FINDING:
-- No orphan review records were found.
-- All review records reference existing orders.
--
-- DECISION:
-- Referential integrity between order_reviews and orders
-- is maintained based on this validation.


-- Referential integrity validation summary

-- FINDING:
-- All five tested table relationships passed validation.
-- No orphan records were found in any tested relationship.
--
-- DECISION:
-- Referential integrity is maintained across the
-- validated relationships.
-- No records were removed or modified during this process.


-- =====================================================
-- 5. ORDER STATUS VALIDATION
-- =====================================================

-- Check order status distribution

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM olist.orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- FINDING:
-- The orders table contains 8 distinct order statuses.
--
-- Key observations:
-- - Delivered orders: 96,478.
-- - Shipped orders: 1,107.
-- - Canceled orders: 625.
-- - Unavailable orders: 609.
-- - Invoiced orders: 314.
-- - Processing orders: 301.
-- - Created orders: 5.
-- - Approved orders: 2.
--
-- INSIGHT:
-- Most orders in the dataset have reached the delivered stage.
-- However, order status alone does not guarantee that all
-- delivery-related timestamps are complete.
--
-- DECISION:
-- All order status categories are retained.
-- No records are removed based on order status.



-- Check leading and trailing spaces in order status

SELECT
    COUNT(*) AS inconsistent_status_format
FROM olist.orders
WHERE order_status <> BTRIM(order_status);

-- FINDING:
-- No leading or trailing spaces were found
-- in the order_status values.
--
-- The validation returned 0 inconsistent records.
--
-- DECISION:
-- No trimming is required based on this validation.
-- All records are retained.


-- =====================================================
-- 6. DATE VALIDATION
-- =====================================================

-- Check order purchase date range

SELECT
    MIN(order_purchase_timestamp) AS earliest_purchase_date,
    MAX(order_purchase_timestamp) AS latest_purchase_date,
    COUNT(*) AS total_orders
FROM olist.orders;

-- FINDING:
-- The order purchase timestamps range from
-- September 4, 2016 to October 17, 2018.
-- The orders table contains 99,441 records.
--
-- INSIGHT:
-- The dataset covers more than two years of
-- e-commerce transaction activity.
--
-- DECISION:
-- The purchase date range is recorded for further
-- time-based sales and customer behavior analysis.


-- Check chronological consistency of order timestamps

SELECT
    COUNT(*) FILTER (
        WHERE order_approved_at < order_purchase_timestamp
    ) AS invalid_approval_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_purchase_timestamp
    ) AS invalid_carrier_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_purchase_timestamp
    ) AS invalid_delivery_dates

FROM olist.orders;

-- FINDING:
-- No approval timestamps were found before purchase timestamps.
-- No customer delivery timestamps were found before purchase.
-- However, 166 orders have carrier handover timestamps
-- earlier than their purchase timestamps.
--
-- DECISION:
-- The 166 records are flagged for further investigation.
-- No timestamps are modified or removed at this stage.


-- Investigate invalid carrier handover timestamps

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM olist.orders
WHERE order_delivered_carrier_date < order_purchase_timestamp
ORDER BY order_purchase_timestamp
LIMIT 20;

-- FINDING:
-- All 20 inspected records have carrier handover timestamps
-- earlier than their purchase timestamps.
--
-- NOTE:
-- This query returns only 20 records and does not represent
-- all 166 identified anomalies.
--
-- INTERPRETATION:
-- These records indicate chronological inconsistencies
-- in the order timestamps.
-- The underlying cause cannot be determined from
-- the available data alone.
--
-- DECISION:
-- The affected records are retained without modification.
-- Further investigation is required before any correction.


-- Summarize invalid carrier handover timestamps

SELECT
    COUNT(*) AS total_invalid_records,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date::DATE =
              order_purchase_timestamp::DATE
    ) AS same_calendar_date,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date::DATE <>
              order_purchase_timestamp::DATE
    ) AS different_calendar_date,

    ROUND(
        MIN(EXTRACT(EPOCH FROM (
            order_purchase_timestamp - order_delivered_carrier_date
        )) / 60)::NUMERIC,
        2
    ) AS minimum_difference_minutes,

    ROUND(
        MAX(EXTRACT(EPOCH FROM (
            order_purchase_timestamp - order_delivered_carrier_date
        )) / 60)::NUMERIC,
        2
    ) AS maximum_difference_minutes,

    ROUND(
        AVG(EXTRACT(EPOCH FROM (
            order_purchase_timestamp - order_delivered_carrier_date
        )) / 60)::NUMERIC,
        2
    ) AS average_difference_minutes

FROM olist.orders
WHERE order_delivered_carrier_date < order_purchase_timestamp;

-- FINDING:
-- A total of 166 records have carrier handover timestamps
-- earlier than their purchase timestamps.
--
-- Key observations:
-- - 164 records (98.80%) occur on the same calendar date.
-- - 2 records (1.20%) occur on different calendar dates.
-- - Minimum difference: approximately 0.40 minutes.
-- - Maximum difference: approximately 246,545.88 minutes.
-- - Average difference: approximately 1,562.37 minutes.
--
-- INSIGHT:
-- Most identified anomalies involve timestamps on the
-- same calendar date. However, two records have substantially
-- larger date differences and require further investigation.
--
-- DECISION:
-- All affected records are retained without modification.
-- No timestamp corrections are applied without additional
-- evidence from the original data source.


-- Investigate carrier timestamp anomalies across different dates

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,

    ROUND(
        (
            EXTRACT(EPOCH FROM (
                order_purchase_timestamp -
                order_delivered_carrier_date
            )) / 86400
        )::NUMERIC,
        2
    ) AS difference_days

FROM olist.orders
WHERE order_delivered_carrier_date < order_purchase_timestamp
  AND order_delivered_carrier_date::DATE <>
      order_purchase_timestamp::DATE
ORDER BY difference_days DESC;

-- FINDING:
-- Two records have carrier handover timestamps on
-- different calendar dates from their purchase timestamps.
--
-- Key observations:
-- - One record has a carrier timestamp approximately
--   171.21 days before the purchase timestamp.
-- - One record has a carrier timestamp approximately
--   4.23 days before the purchase timestamp.
-- - Both records have a delivered order status.
--
-- INTERPRETATION:
-- These records show significant chronological
-- inconsistencies in the order processing timestamps.
-- The root cause cannot be determined from the
-- available dataset alone.
--
-- DECISION:
-- Both records are retained without modification.
-- No timestamps are corrected or deleted without
-- supporting evidence from the original data source.


-- Check carrier handover timestamps against approval timestamps
-- and customer delivery timestamps against carrier timestamps

SELECT
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_approved_at
    ) AS carrier_before_approval,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date <
              order_delivered_carrier_date
    ) AS delivery_before_carrier

FROM olist.orders;

-- FINDING:
-- A total of 1,359 records have carrier handover
-- timestamps earlier than approval timestamps.
-- Additionally, 23 records have customer delivery
-- timestamps earlier than carrier handover timestamps.
--
-- NOTE:
-- These counts represent separate validation conditions.
-- They may overlap with other timestamp anomalies.
--
-- INTERPRETATION:
-- These records indicate chronological inconsistencies
-- in the order processing timestamps.
--
-- DECISION:
-- The affected records are retained without modification.
-- No timestamps are corrected or deleted without
-- supporting evidence from the original data source.


-- Investigate delivery timestamps earlier than carrier timestamps

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM olist.orders
WHERE order_delivered_customer_date <
      order_delivered_carrier_date
ORDER BY order_purchase_timestamp
LIMIT 20;

-- FINDING:
-- The inspected sample shows customer delivery timestamps
-- occurring before carrier handover timestamps.
--
-- Key observations:
-- - All 20 inspected records have inconsistent delivery
--   and carrier timestamp sequences.
-- - The customer delivery timestamps are earlier than
--   the corresponding carrier handover timestamps.
-- - The inspected records have a delivered order status.
--
-- NOTE:
-- This query returns only 20 records and does not represent
-- all 23 identified anomalies.
--
-- INTERPRETATION:
-- These records indicate chronological inconsistencies
-- in the delivery process timestamps.
-- The root cause cannot be determined from the
-- available dataset alone.
--
-- DECISION:
-- All affected records are retained without modification.
-- No timestamps are corrected or deleted without
-- supporting evidence from the original data source.


-- Summarize invalid delivery timestamps

SELECT
    COUNT(*) AS total_invalid_records,

    ROUND(
        MIN(EXTRACT(EPOCH FROM (
            order_delivered_carrier_date -
            order_delivered_customer_date
        )) / 3600)::NUMERIC,
        2
    ) AS minimum_difference_hours,

    ROUND(
        MAX(EXTRACT(EPOCH FROM (
            order_delivered_carrier_date -
            order_delivered_customer_date
        )) / 3600)::NUMERIC,
        2
    ) AS maximum_difference_hours,

    ROUND(
        AVG(EXTRACT(EPOCH FROM (
            order_delivered_carrier_date -
            order_delivered_customer_date
        )) / 3600)::NUMERIC,
        2
    ) AS average_difference_hours

FROM olist.orders
WHERE order_delivered_customer_date <
      order_delivered_carrier_date;

-- FINDING:
-- A total of 23 orders have customer delivery timestamps
-- earlier than their carrier handover timestamps.
--
-- Key observations:
-- - Minimum difference: approximately 0.39 hours.
-- - Maximum difference: approximately 386.31 hours.
-- - Average difference: approximately 78.46 hours.
--
-- INSIGHT:
-- These records show inconsistencies in the chronological
-- sequence of delivery process timestamps.
-- Some records have differences exceeding 16 days.
--
-- DECISION:
-- All affected records are retained without modification.
-- No timestamps are corrected or deleted without
-- supporting evidence from the original data source.


-- Check estimated delivery dates before purchase dates

SELECT
    COUNT(*) AS invalid_estimated_delivery_dates
FROM olist.orders
WHERE order_estimated_delivery_date <
      order_purchase_timestamp;

-- FINDING:
-- No orders were found with estimated delivery dates
-- earlier than their purchase timestamps.
--
-- INSIGHT:
-- Estimated delivery dates are chronologically consistent
-- with purchase timestamps based on this validation.
--
-- DECISION:
-- No data correction is required for this check.
-- All records are retained.


-- =====================================================
-- DATE VALIDATION SUMMARY
-- =====================================================

-- FINDING:
-- The purchase timestamps range from September 4, 2016
-- to October 17, 2018.
--
-- No records were found with approval timestamps
-- earlier than their purchase timestamps.
--
-- However, several chronological inconsistencies
-- were identified in delivery process timestamps:
-- - 166 orders have carrier timestamps before purchase.
-- - 1,359 orders have carrier timestamps before approval.
-- - 23 orders have customer delivery timestamps
--   before carrier handover timestamps.
--
-- No estimated delivery dates were found before
-- purchase timestamps.
--
-- DECISION:
-- Identified timestamp anomalies are retained
-- without modification.
-- No records or timestamps are deleted or corrected
-- without supporting evidence from the original source.
--
-- Overall, the date validation identified several
-- delivery timestamp inconsistencies that should be
-- considered in subsequent delivery performance analysis.
--
-- NOTE:
-- The anomaly counts represent individual validation
-- conditions and may overlap across multiple checks.
-- They should not be added together as unique affected orders.
--
-- =====================================================
-- END OF DATA VALIDATION
-- =====================================================
