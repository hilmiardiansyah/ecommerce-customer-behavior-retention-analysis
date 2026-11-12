-- =====================================================
-- PROJECT: E-Commerce Customer Behavior & Retention
-- FILE: 02_exploratory_data_analysis.sql
-- DATABASE: olist_ecommerce
-- SCHEMA: olist
--
-- OBJECTIVE:
-- Explore business performance and customer behavior
-- using the validated e-commerce dataset.
-- =====================================================


-- =====================================================
-- 1. BUSINESS OVERVIEW
-- =====================================================


-- 1.1. Total orders by order status
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM olist.orders
GROUP BY order_status
ORDER BY total_orders DESC;
-- FINDING:
-- The dataset contains 99,441 orders across 8 statuses.
--
-- Key observations:
-- - Delivered: 96,478 orders (97.02%).
-- - Shipped: 1,107 orders (1.11%).
-- - Canceled: 625 orders (0.63%).
-- - Unavailable: 609 orders (0.61%).
-- - Invoiced: 314 orders (0.32%).
-- - Processing: 301 orders (0.30%).
-- - Created: 5 orders (0.01%).
-- - Approved: 2 orders (0.00%).
--
-- INSIGHT:
-- Most orders have reached the delivered status,
-- representing 97.02% of all recorded orders.
--
-- DECISION:
-- All order statuses are retained for further analysis.
-- Order status distribution will be used as a baseline
-- for evaluating sales and customer behavior.


-- 1.2. Overall payment performance
SELECT
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT order_id) AS unique_paid_orders,
    SUM(payment_value) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value,
    ROUND(MIN(payment_value), 2) AS minimum_payment_value,
    ROUND(MAX(payment_value), 2) AS maximum_payment_value
FROM olist.payments;
-- FINDING:
-- The payments table contains 103,886 payment records
-- associated with 99,440 unique orders.
--
-- Key observations:
-- - Total payment value: R$16,008,872.12.
-- - Average payment per record: R$154.10.
-- - Minimum payment value: R$0.00.
-- - Maximum payment value: R$13,664.08.
--
-- INSIGHT:
-- The number of payment records exceeds the number
-- of unique paid orders, indicating that some orders
-- may have multiple payment records.
--
-- DECISION:
-- Payment records are retained for further analysis.
-- Zero-value payments and the difference between
-- total orders and paid orders require investigation.


-- 1.3. Identify orders without payment records
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp
FROM olist.orders o
LEFT JOIN olist.payments p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;
-- FINDING:
-- One order was identified without a corresponding
-- payment record.
--
-- Order ID:
-- bfbd0f9bdef84302105ad712db648a6c
--
-- Order status: delivered
-- Purchase timestamp: 2016-09-15 12:16:38
--
-- INTERPRETATION:
-- The order has reached delivered status but has no
-- associated payment record in the payments table.
--
-- DECISION:
-- The record is flagged for further investigation.
-- No payment value is assumed or manually assigned.
-- The original order record is retained.


-- 1.4. Investigate order without payment record
SELECT
    o.order_id,
    o.order_status,
    o.customer_id,
    o.order_purchase_timestamp,
    COUNT(oi.order_item_id) AS total_items,
    SUM(oi.price) AS total_product_value,
    SUM(oi.freight_value) AS total_freight_value,
    SUM(oi.price + oi.freight_value) AS total_order_value
FROM olist.orders o
LEFT JOIN olist.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_id = 'bfbd0f9bdef84302105ad712db648a6c'
GROUP BY
    o.order_id,
    o.order_status,
    o.customer_id,
    o.order_purchase_timestamp;
-- FINDING:
-- The investigated order contains 3 product items
-- with a total product value of R$134.97.
--
-- Additional observations:
-- - Freight value: R$8.49.
-- - Total order value: R$143.46.
-- - Order status: delivered.
-- - No corresponding payment record was found.
--
-- INTERPRETATION:
-- The order fulfillment record indicates that the order
-- was delivered, while the payments table contains
-- no associated payment information.
--
-- INSIGHT:
-- Missing payment records may affect the accuracy
-- of payment and revenue analysis.
--
-- DECISION:
-- The order is flagged as a payment data completeness
-- issue. No payment value is assumed or manually assigned.
-- The original records are retained for further analysis.


-- 1.5. Investigate zero-value payments
SELECT
    payment_type,
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders
FROM olist.payments
WHERE payment_value = 0
GROUP BY payment_type
ORDER BY total_records DESC;
-- FINDING:
-- A total of 9 zero-value payment records were identified
-- across 8 unique orders.
--
-- Key observations:
-- - voucher: 6 records across 5 unique orders.
-- - not_defined: 3 records across 3 unique orders.
--
-- INTERPRETATION:
-- Zero-value payments are recorded under voucher
-- and not_defined payment types.
-- These records may represent specific payment conditions,
-- but their exact business meaning requires further review.
--
-- DECISION:
-- Zero-value payment records are retained.
-- No payment values are modified or removed without
-- additional supporting evidence.


-- 1.6. Investigate zero-value payment details
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM olist.payments
WHERE order_id IN (
    SELECT DISTINCT order_id
    FROM olist.payments
    WHERE payment_value = 0
)
ORDER BY order_id, payment_sequential;
-- FINDING:
-- A total of 9 zero-value payment records were identified
-- across 8 unique orders.
--
-- INVESTIGATION RESULTS:
-- - 5 orders contain both zero-value and positive-value
--   payment records.
-- - 3 orders contain only zero-value payment records.
-- - The 3 orders with only zero-value records use
--   the payment type 'not_defined'.
-- - The remaining 5 orders contain positive payment
--   records, mostly involving voucher payments.
--
-- INTERPRETATION:
-- Zero-value payment records do not necessarily mean
-- that an entire order has no recorded payment.
-- Some orders have other payment records with
-- positive values.
--
-- INSIGHT:
-- Payment analysis should be performed at the order level
-- when evaluating whether an order has recorded payments.
-- Looking only at individual zero-value records could
-- lead to incorrect conclusions.
--
-- DECISION:
-- All payment records are retained.
-- Zero-value records are not automatically classified
-- as unpaid orders.
-- The 3 orders containing only zero-value records
-- are flagged for further investigation.


-- 1.7. Payment method distribution
SELECT
    payment_type,
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(
        COUNT(DISTINCT order_id) * 100.0 /
        SUM(COUNT(DISTINCT order_id)) OVER (),
        2
    ) AS order_percentage
FROM olist.payments
GROUP BY payment_type
ORDER BY unique_orders DESC;
-- FINDING:
-- Credit card is the most frequently used payment method,
-- followed by boleto.
--
-- Key observations:
-- - Credit card: 76,505 unique orders (75.24%).
-- - Boleto: 19,784 unique orders (19.46%).
-- - Voucher: 3,866 unique orders (3.80%).
-- - Debit card: 1,528 unique orders (1.50%).
-- - Not defined: 3 unique orders (0.00% payment value).
--
-- INSIGHT:
-- Credit card represents the dominant payment method
-- in the dataset.
-- Boleto also contributes a significant share of
-- recorded orders.
--
-- Voucher has more payment records than unique orders,
-- indicating multiple voucher records within some orders.
--
-- DECISION:
-- All payment methods are retained for further analysis.
-- Payment method performance will be evaluated using
-- both unique orders and total payment value.
--
-- NOTE:
-- Payment percentages may exceed or differ from 100%
-- when summed because an order can have multiple
-- payment methods.


-- 1.8. Payment installment distribution
SELECT
    payment_installments,
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM olist.payments
GROUP BY payment_installments
ORDER BY payment_installments;
-- FINDING:
-- One installment is the most frequently recorded
-- payment installment option, with 49,060 unique orders.
--
-- Key observations:
-- - 1 installment: 49,060 unique orders.
-- - 2 installments: 12,389 unique orders.
-- - 3 installments: 10,443 unique orders.
-- - 10 installments: 5,315 unique orders.
-- - 8 installments: 4,253 unique orders.
--
-- The 10-installment category records a total payment
-- value of R$2,211,577.34.
--
-- DATA QUALITY OBSERVATION:
-- Two payment records have payment_installments = 0,
-- with a combined payment value of R$188.63.
--
-- INSIGHT:
-- Customers predominantly use one-time payments.
-- However, installment options such as 8 and 10
-- installments also contribute substantial payment value.
--
-- DECISION:
-- All installment records are retained.
-- Records with zero installments are flagged
-- for further investigation.
-- No records are modified or removed without
-- additional supporting evidence.


-- 1.9. Investigate zero installment records
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM olist.payments
WHERE payment_installments = 0
ORDER BY order_id;
-- FINDING:
-- Two payment records were identified with
-- payment_installments = 0.
--
-- Key observations:
-- - Both records use credit_card as the payment type.
-- - Both records have payment_sequential = 2.
-- - First record payment value: R$129.94.
-- - Second record payment value: R$58.69.
-- - Combined payment value: R$188.63.
--
-- INTERPRETATION:
-- Both records have positive payment values despite
-- having zero installments.
-- This indicates that zero installments do not mean
-- zero payment value.
--
-- INSIGHT:
-- The installment field contains unusual values
-- that may affect installment behavior analysis.
--
-- DECISION:
-- Both records are flagged for further investigation.
-- The original values are retained.
-- No installment values are manually changed
-- without additional supporting evidence.


-- 1.10. Average payment value by payment method
SELECT
    payment_type,
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(AVG(payment_value), 2) AS average_payment_value,
    ROUND(MIN(payment_value), 2) AS minimum_payment_value,
    ROUND(MAX(payment_value), 2) AS maximum_payment_value
FROM olist.payments
GROUP BY payment_type
ORDER BY average_payment_value DESC;
-- FINDING:
-- Credit card has the highest average payment value
-- among all recorded payment methods.
--
-- Key observations:
-- - Credit card: R$163.32 average payment value.
-- - Boleto: R$145.03 average payment value.
-- - Debit card: R$142.57 average payment value.
-- - Voucher: R$65.70 average payment value.
-- - Not defined: R$0.00 average payment value.
--
-- Additional observations:
-- - Credit card has the highest maximum payment value
--   at R$13,664.08.
-- - Voucher has a minimum payment value of R$0.00.
-- - Not defined contains only zero-value records.
--
-- INSIGHT:
-- Credit card transactions have the highest average
-- payment value per payment record.
-- Voucher payments have a lower average value,
-- partly influenced by zero-value payment records.
--
-- DECISION:
-- All payment methods are retained for further analysis.
-- Average payment value is interpreted at the
-- payment-record level, not the order level.
-- Zero-value records are not automatically removed.


-- 1.11. Monthly order distribution
SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS order_year,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders
FROM olist.orders
GROUP BY
    EXTRACT(YEAR FROM order_purchase_timestamp),
    EXTRACT(MONTH FROM order_purchase_timestamp)
ORDER BY
    order_year,
    order_month;
-- FINDING:
-- The dataset contains 99,441 orders across the
-- observed period from September 2016 to October 2018.
--
-- Annual order distribution:
-- - 2016: 329 orders.
-- - 2017: 45,101 orders.
-- - 2018: 54,011 orders.
--
-- Key observations:
-- - November 2017 recorded the highest monthly volume
--   with 7,544 orders.
-- - October 2017 recorded 4,631 orders.
-- - September 2018 recorded only 16 orders.
-- - October 2018 recorded only 4 orders.
--
-- INSIGHT:
-- Order volume increased substantially throughout
-- 2017 and most of 2018.
--
-- The unusually low order counts in September
-- and October 2018 may be related to incomplete
-- dataset coverage rather than an actual decline
-- in customer demand.
--
-- DECISION:
-- Monthly order trends are retained for further analysis.
-- September and October 2018 are treated as incomplete
-- periods and should not be directly compared with
-- full months.


-- 1.12. Monthly order growth (Month-over-Month)
WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
        COUNT(*) AS total_orders
    FROM olist.orders
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
),

monthly_comparison AS (
    SELECT
        order_month,
        total_orders,
        LAG(total_orders) OVER (
            ORDER BY order_month
        ) AS previous_month_orders
    FROM monthly_orders
)

SELECT
    TO_CHAR(order_month, 'YYYY-MM') AS order_month,
    total_orders,
    previous_month_orders,
    total_orders - previous_month_orders AS order_difference,
    ROUND(
        (total_orders - previous_month_orders) * 100.0 /
        NULLIF(previous_month_orders, 0),
        2
    ) AS growth_percentage
FROM monthly_comparison
ORDER BY order_month;
-- FINDING:
-- Monthly order volume fluctuates throughout
-- the observed period.
--
-- Key observations:
-- - January 2017 recorded 79,900% growth,
--   mainly due to the very low previous-month baseline
--   of only 1 order in December 2016.
-- - November 2017 recorded 62.90% growth,
--   increasing by 2,913 orders compared with October 2017.
-- - December 2017 experienced a 24.80% decline.
-- - January 2018 recorded 28.13% growth.
-- - September 2018 recorded a 99.75% decline.
--
-- INSIGHT:
-- Monthly order volume shows substantial fluctuations.
-- November 2017 represents a significant increase
-- in recorded order volume.
--
-- Extremely high growth percentages in early periods
-- are influenced by low previous-month order counts.
--
-- The sharp declines in September and October 2018
-- are affected by incomplete dataset coverage.
-- They should not be interpreted as actual demand declines.
--
-- DECISION:
-- Both absolute order differences and growth percentages
-- are considered when evaluating monthly performance.
-- Incomplete periods and low-volume baseline months
-- are treated carefully during trend interpretation.
-- ADDITIONAL NOTE:
-- September 2016 is the first observed month
-- in the dataset.
--
-- Therefore, LAG() returns NULL for the previous
-- month value because no earlier monthly record exists.
--
-- Order difference and growth percentage are also NULL
-- because no previous-month comparison is available.
--
-- DECISION:
-- NULL values are retained because they represent
-- unavailable comparison data, not zero orders.


-- 1.13. Order distribution by day of week
SELECT
    EXTRACT(DOW FROM order_purchase_timestamp) AS day_number,
    TO_CHAR(order_purchase_timestamp, 'FMDay') AS day_name,
    COUNT(*) AS total_orders
FROM olist.orders
GROUP BY
    EXTRACT(DOW FROM order_purchase_timestamp),
    TO_CHAR(order_purchase_timestamp, 'FMDay')
ORDER BY day_number;
-- FINDING:
-- Monday has the highest order volume with 16,196 orders,
-- representing approximately 16.29% of all orders.
--
-- Key observations:
-- - Monday: 16,196 orders (16.29%).
-- - Tuesday: 15,963 orders (16.06%).
-- - Wednesday: 15,552 orders (15.64%).
-- - Saturday: 10,887 orders (10.95%).
--
-- Saturday records the lowest order volume.
--
-- INSIGHT:
-- Order activity is relatively higher at the beginning
-- of the week, particularly on Monday and Tuesday.
--
-- Weekend order activity is lower, with Saturday
-- recording the fewest orders.
--
-- DECISION:
-- Day-of-week order distribution is retained
-- for further customer behavior analysis.
-- This pattern may support operational planning
-- and promotional scheduling.
--
-- NOTE:
-- This analysis measures orders by purchase date,
-- not order processing or delivery date.


-- 1.14. Order distribution by purchase hour
SELECT
    EXTRACT(HOUR FROM order_purchase_timestamp) AS purchase_hour,
    COUNT(*) AS total_orders
FROM olist.orders
GROUP BY
    EXTRACT(HOUR FROM order_purchase_timestamp)
ORDER BY purchase_hour;
-- FINDING:
-- The highest order activity occurs at 16:00,
-- with 6,675 recorded orders.
--
-- Key observations:
-- - 16:00: 6,675 orders (highest).
-- - 14:00: 6,569 orders.
-- - 13:00: 6,518 orders.
-- - 15:00: 6,454 orders.
-- - 21:00: 6,217 orders.
-- - 05:00: 188 orders (lowest).
--
-- INSIGHT:
-- Customers show relatively high purchasing activity
-- during the afternoon, particularly between 13:00
-- and 16:00.
--
-- Evening activity is also relatively high,
-- especially between 19:00 and 21:00.
--
-- Purchasing activity is lowest during early morning
-- hours, particularly between 02:00 and 05:00.
--
-- DECISION:
-- Hourly order distribution is retained for further
-- customer behavior analysis.
-- Afternoon and evening periods may be considered
-- for promotional scheduling.
--
-- NOTE:
-- This analysis measures order purchase time,
-- not payment, processing, or delivery time.


-- 1.15. Order distribution by day and hour
SELECT
    EXTRACT(DOW FROM order_purchase_timestamp) AS day_number,
    TO_CHAR(order_purchase_timestamp, 'FMDay') AS day_name,
    EXTRACT(HOUR FROM order_purchase_timestamp) AS purchase_hour,
    COUNT(*) AS total_orders
FROM olist.orders
GROUP BY
    EXTRACT(DOW FROM order_purchase_timestamp),
    TO_CHAR(order_purchase_timestamp, 'FMDay'),
    EXTRACT(HOUR FROM order_purchase_timestamp)
ORDER BY
    total_orders DESC,
    day_number,
    purchase_hour;
-- FINDING:
-- Tuesday at 14:00 records the highest order volume
-- with 1,124 orders.
--
-- Top observations:
-- - Tuesday at 14:00: 1,124 orders.
-- - Monday at 21:00: 1,118 orders.
-- - Monday at 14:00: 1,096 orders.
-- - Monday at 16:00: 1,094 orders.
-- - Tuesday at 16:00: 1,081 orders.
--
-- Additional observations:
-- - Monday appears frequently among the top
--   order-generating day-hour combinations.
-- - The 11:00-16:00 period shows relatively
--   high order activity.
-- - Monday at 21:00 also records substantial
--   order volume.
--
-- INSIGHT:
-- Order activity is relatively strong during
-- late morning and afternoon hours.
-- Certain evening periods also show high activity.
--
-- Tuesday at 14:00 is the highest-volume
-- day-hour combination in the dataset.
--
-- DECISION:
-- Day-hour combinations are retained for further
-- customer behavior analysis.
-- High-volume periods may be considered as candidates
-- for promotional scheduling.
--
-- NOTE:
-- Results represent accumulated orders across
-- the entire dataset period.
-- They do not establish that the same pattern
-- occurs consistently every week.


-- 1.16. Order status by payment method
SELECT
    o.order_status,
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS unique_orders,
    ROUND(SUM(p.payment_value), 2) AS total_payment_value
FROM olist.orders o
INNER JOIN olist.payments p
    ON o.order_id = p.order_id
GROUP BY
    o.order_status,
    p.payment_type
ORDER BY
    o.order_status,
    unique_orders DESC;
-- FINDING:
-- Credit card is the most frequently recorded payment method
-- across almost all order statuses.
--
-- Key observations:
-- - Delivered: 74,304 credit card orders with a total
--   payment value of R$12,101,094.88.
-- - Canceled: 444 credit card orders, the highest
--   among all payment methods for this status.
-- - Shipped: 848 credit card orders.
-- - Unavailable: 443 credit card orders.
-- - Processing: 222 credit card orders.
-- - Invoiced: 239 credit card orders.
-- - Created: 3 credit card orders and 2 boleto orders.
-- - Approved: 2 credit card orders.
--
-- Additional observations:
-- - The 'not_defined' payment method appears only
--   in canceled orders, with 3 orders and R$0.00
--   in recorded payment value.
-- - Multiple payment methods may be associated
--   with the same order.
--
-- INSIGHT:
-- Credit card is the dominant payment method
-- across the observed order statuses.
--
-- Canceled orders are associated with several
-- different payment methods.
-- Therefore, cancellations are not limited
-- to a single payment method.
--
-- DECISION:
-- All order statuses and payment methods are retained
-- for further analysis.
-- Payment method distribution will be considered
-- alongside order status when evaluating customer
-- payment behavior.
--
-- NOTE:
-- Unique order counts may overlap across payment methods
-- because one order can have multiple payment records.
--
-- Total payment value represents the sum of recorded
-- payment records, not necessarily net revenue
-- or successfully received funds.
-- This query uses INNER JOIN, so orders without
-- payment records are excluded from the results.


-- =====================================================
-- 1.17. Customer Distribution by State
-- Objective:
-- Identify customer distribution across different states.
-- =====================================================
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id)
        AS total_customers,
    COUNT(DISTINCT o.order_id)
        AS total_delivered_orders
FROM olist.orders o
JOIN olist.customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY
    c.customer_state
ORDER BY
    total_customers DESC;
-- FINDING:
-- São Paulo (SP) has the highest customer distribution,
-- with 39,156 unique customers and 40,501 delivered orders.
--
-- Top 3 states by unique customers:
-- - SP: 39,156 customers.
-- - RJ: 11,917 customers.
-- - MG: 11,001 customers.
--
-- Additional observations:
-- - RR has the lowest customer count,
--   with only 40 unique customers.
-- - Delivered order counts are higher than unique
--   customer counts across all states.
--
-- INSIGHT:
-- Customer distribution is heavily concentrated
-- in São Paulo, followed by Rio de Janeiro
-- and Minas Gerais.
--
-- These states represent important customer markets
-- within the observed dataset.
--
-- DECISION:
-- Customer state is retained as a dimension
-- for further geographical analysis.
-- High-customer-volume states may be considered
-- for marketing and customer retention strategies.
--
-- NOTE:
-- This analysis includes delivered orders only.
-- The number of unique customers and delivered orders
-- may differ because one customer can place
-- multiple orders.
-- Customer concentration does not automatically
-- indicate higher spending or customer retention.


-- =====================================================
-- 1.18. Sales Performance by Customer State
-- Objective:
-- Identify states with the highest delivered sales value.
-- =====================================================
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id)
        AS total_customers,
    COUNT(DISTINCT o.order_id)
        AS total_delivered_orders,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_sales
FROM olist.orders o
JOIN olist.customers c
    ON o.customer_id = c.customer_id
JOIN olist.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    c.customer_state
ORDER BY
    total_sales DESC;
-- FINDING:
-- São Paulo (SP) records the highest delivered sales value,
-- with a total of R$5,769,703.15.
--
-- Top 3 states by total sales:
-- - SP: R$5,769,703.15.
-- - RJ: R$2,055,401.57.
-- - MG: R$1,818,891.67.
--
-- Additional observations:
-- - RR records the lowest sales value,
--   with R$9,039.52.
-- - Bahia (BA) has fewer customers than Santa Catarina (SC),
--   but records a slightly higher total sales value.
--
-- INSIGHT:
-- São Paulo is the largest customer market
-- and the highest sales contributor in the dataset.
--
-- Customer volume alone does not fully explain
-- differences in sales performance across states.
--
-- DECISION:
-- Customer state is retained as a dimension
-- for geographical sales performance analysis.
-- Further analysis of average spending per customer
-- is needed to compare customer value across states.
--
-- NOTE:
-- Sales value is calculated from product prices
-- plus freight values for delivered orders.
-- This metric does not represent net company revenue.


-- =====================================================
-- 1.19. Average Customer Spending by State
-- Objective:
-- Compare average customer spending across states.
-- =====================================================
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id)
        AS total_customers,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_sales,
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT c.customer_unique_id),
        2
    ) AS average_spending_per_customer
FROM olist.orders o
JOIN olist.customers c
    ON o.customer_id = c.customer_id
JOIN olist.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    c.customer_state
ORDER BY
    average_spending_per_customer DESC;
-- FINDING:
-- PB (Paraíba) has the highest average spending per customer
-- at R$273.49, followed by AC at R$257.57
-- and RO at R$246.61.
--
-- SP (São Paulo) has the largest customer base
-- (39,156 customers) and the highest total sales
-- (R$5,769,703.15), but the lowest average spending
-- per customer at R$147.35.
--
-- INSIGHT:
-- States with the largest customer base do not necessarily
-- have the highest average spending per customer.
-- SP generates the highest total sales due to its large
-- customer base, while PB has higher average customer spending.
--
-- DECISION:
-- Regional performance should be evaluated using both
-- total sales to measure sales contribution and average
-- spending per customer to compare customer spending value.
--
-- NOTE:
-- Average spending per customer is calculated by dividing
-- total delivered sales (item price + freight value)
-- by the number of unique customers in each state.
-- This metric is not the same as Average Order Value (AOV).
-- A customer_unique_id may appear in multiple states if
-- the customer has multiple customer_id records associated
-- with different locations.
-- Total sales do not represent net profit or net revenue.


-- =====================================================
-- 1.20. Sales Performance by City
-- Objective:
-- Identify cities with the highest customer count
-- and delivered sales value.
-- =====================================================
SELECT
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id)
        AS total_customers,
    COUNT(DISTINCT o.order_id)
        AS total_delivered_orders,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_sales
  
FROM olist.orders o
JOIN olist.customers c
    ON o.customer_id = c.customer_id
JOIN olist.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  
GROUP BY
    c.customer_city,
    c.customer_state
ORDER BY
    total_sales DESC
LIMIT 20;
-- FINDING:
-- Sao Paulo (SP) ranks first with total delivered sales
-- of R$2,107,960.17, followed by Rio de Janeiro (RJ)
-- with R$1,111,732.21 and Belo Horizonte (MG)
-- with R$405,950.51.
--
-- Sao Paulo also has the highest customer count
-- (14,528 customers) and delivered order count
-- (15,045 orders) among the top 20 cities.
--
-- Several cities in Sao Paulo state appear in the top 20,
-- including Campinas, Guarulhos, Santos, Sao Bernardo do Campo,
-- Santo Andre, Osasco, and Jundiai.
--
-- INSIGHT:
-- Sao Paulo is the strongest city-level contributor
-- to delivered sales in this dataset.
-- The difference between delivered orders and unique customers
-- indicates that some customers placed multiple orders.
--
-- DECISION:
-- Prioritize high-contributing cities when evaluating
-- regional sales performance and potential business opportunities.
-- Consider customer count and order volume together
-- when assessing each city's contribution.
--
-- NOTE:
-- The analysis includes delivered orders only.
-- Total sales are calculated as item price + freight value.
-- The top 20 cities are ranked by total sales.
-- Customer and order counts represent distinct customers
-- and distinct delivered orders, respectively.
-- Total sales do not represent net profit or net revenue.


-- =====================================================
-- 1.21. Repeat Customer Distribution by State
-- Objective:
-- Identify states with the highest number
-- of repeat customers.
-- =====================================================
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist.orders o
    JOIN olist.customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id,
        c.customer_state
)
SELECT
    customer_state,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE total_orders > 1
    ) AS repeat_customers,
    ROUND(
        COUNT(*) FILTER (
            WHERE total_orders > 1
        ) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_rate

FROM customer_orders
GROUP BY customer_state
ORDER BY repeat_customer_rate DESC;
-- FINDING:
-- AC (Acre) has the highest repeat customer rate at 5.26%,
-- with 4 repeat customers out of 76 total customers.
--
-- SP (Sao Paulo) has the largest number of repeat customers
-- at 1,213 customers, representing a repeat customer rate of 3.10%.
--
-- RJ (Rio de Janeiro) ranks second in repeat customer count
-- with 387 customers and a repeat customer rate of 3.25%.
--
-- AP (Amapa) has the lowest repeat customer rate at 1.52%,
-- with 1 repeat customer out of 66 total customers.
--
-- INSIGHT:
-- The state with the highest repeat customer rate does not
-- necessarily have the largest repeat customer population.
-- States with smaller customer bases may show higher rates
-- despite having relatively few repeat customers.
--
-- DECISION:
-- Consider both repeat customer count and repeat customer rate
-- when evaluating customer retention across states.
-- Further investigation may focus on states with large customer
-- bases but relatively low repeat customer rates.
--
-- NOTE:
-- A repeat customer is defined as a customer_unique_id
-- with more than one delivered order within the same state.
-- Repeat customer rate is calculated as repeat customers
-- divided by total customers in each state.
-- A customer_unique_id may be counted in multiple states
-- if their orders are associated with different customer states.
-- Results are descriptive and do not establish the reasons
-- behind repeat purchasing behavior.


-- =====================================================
-- 1.22. Average Orders per Customer by State
-- Objective:
-- Compare the average number of delivered orders
-- per customer across states.
-- =====================================================
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist.orders o
    JOIN olist.customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id,
        c.customer_state
)
  
SELECT
    customer_state,
    COUNT(*) AS total_customers,
    SUM(total_orders) AS total_delivered_orders,
    ROUND(
        AVG(total_orders),
        2
    ) AS average_orders_per_customer

FROM customer_orders
GROUP BY customer_state
ORDER BY average_orders_per_customer DESC;
-- FINDING:
-- RO (Rondonia) and AC (Acre) have the highest average
-- delivered orders per customer at 1.05.
--
-- RN, AP, MA, SE, and CE have the lowest average
-- at 1.02 delivered orders per customer.
--
-- SP (Sao Paulo) records 40,501 delivered orders
-- from 39,156 customers, resulting in an average
-- of approximately 1.03 orders per customer.
--
-- INSIGHT:
-- Average delivered orders per customer are relatively
-- consistent across all states, ranging from 1.02 to 1.05.
-- This indicates that the overall purchasing frequency
-- is relatively low across the customer base.
--
-- DECISION:
-- Use average orders per customer together with repeat
-- customer rate to evaluate purchasing frequency.
-- Further retention analysis may help identify opportunities
-- to encourage customers to make additional purchases.
--
-- NOTE:
-- Average orders per customer is calculated by dividing
-- the total number of distinct delivered orders by
-- the number of unique customers in each state.
-- The calculation is based on delivered orders only.
-- A customer_unique_id may be counted in multiple states
-- if their orders are associated with different customer states.
-- Rounded averages may hide small differences between states.


-- =====================================================
-- 1.23. Customer Purchase Frequency Distribution
-- Objective:
-- Analyze the distribution of customers based on
-- their number of delivered orders.
-- =====================================================
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist.orders o
    JOIN olist.customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
)

SELECT
    total_orders,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;
-- FINDING:
-- 90,557 customers (97.00%) made only one delivered purchase.
-- Only 2,801 customers (approximately 3.00%) made
-- more than one delivered purchase.
--
-- Customers with two delivered orders represent
-- the largest repeat customer group, with 2,573 customers
-- or 2.76% of the total customer base.
--
-- Only a small number of customers made four or more
-- delivered purchases. The highest observed frequency
-- was 15 delivered orders by one customer.
--
-- INSIGHT:
-- The customer base is heavily dominated by one-time buyers.
-- Repeat purchasing represents only a small proportion
-- of overall customer activity in this dataset.
--
-- DECISION:
-- Customer retention should be an important focus
-- for further analysis.
-- Investigate customer behavior, purchase intervals,
-- and customer segments to identify potential opportunities
-- to encourage repeat purchases.
--
-- NOTE:
-- Purchase frequency is calculated using distinct delivered
-- orders grouped by customer_unique_id.
-- Customers are classified according to their total number
-- of delivered orders across the dataset.
-- Percentages are calculated from the total unique customer count.
-- Small percentages may appear as 0.00% due to rounding.
-- The analysis does not establish why customers did or did not
-- make repeat purchases.


-- =====================================================
-- 1.24. Overall Repeat Purchase Rate
-- Objective:
-- Calculate the overall repeat purchase rate
-- across all customers.
-- =====================================================
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist.orders o
    JOIN olist.customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE total_orders = 1
    ) AS one_time_customers,
    COUNT(*) FILTER (
        WHERE total_orders > 1
    ) AS repeat_customers,
    ROUND(
        COUNT(*) FILTER (
            WHERE total_orders > 1
        ) * 100.0 / COUNT(*),
        2
    ) AS repeat_purchase_rate

FROM customer_orders;
-- FINDING:
-- The dataset contains 93,358 unique customers.
-- 90,557 customers (97.00%) made only one delivered purchase,
-- while 2,801 customers (3.00%) made more than one purchase.
--
-- The overall repeat purchase rate is 3.00%.
--
-- INSIGHT:
-- The customer base is heavily dominated by one-time buyers.
-- Only a small proportion of customers made repeat purchases,
-- indicating a potential customer retention challenge.
--
-- DECISION:
-- Use the repeat purchase rate as a key customer retention KPI.
-- Further analysis should explore customer purchase behavior,
-- purchase intervals, and customer segments to identify
-- potential opportunities to improve repeat purchasing.
--
-- NOTE:
-- Repeat purchase rate is calculated as the percentage
-- of unique customers with more than one delivered order
-- divided by the total number of unique customers.
-- Customer identification uses customer_unique_id.
-- Only delivered orders are included in this analysis.
-- This metric describes purchasing behavior and does not
-- establish the reasons behind customer retention.


-- =====================================================
-- 1.25. Average Days Between Purchases
-- Objective:
-- Calculate the average time interval between
-- consecutive delivered purchases for repeat customers.
-- =====================================================
WITH customer_purchases AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS previous_purchase_date
    FROM olist.orders o
    JOIN olist.customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),

purchase_intervals AS (
    SELECT
        customer_unique_id,
        EXTRACT(
            EPOCH FROM (
                order_purchase_timestamp - previous_purchase_date
            )
        ) / 86400 AS days_between_purchases
    FROM customer_purchases
    WHERE previous_purchase_date IS NOT NULL
)

SELECT
    COUNT(*) AS total_purchase_intervals,
    COUNT(DISTINCT customer_unique_id) AS repeat_customers,
    ROUND(
        AVG(days_between_purchases)::numeric,
        2
    ) AS average_days_between_purchases,
    ROUND(
        MIN(days_between_purchases)::numeric,
        2
    ) AS minimum_days_between_purchases,
    ROUND(
        MAX(days_between_purchases)::numeric,
        2
    ) AS maximum_days_between_purchases
FROM purchase_intervals;
-- FINDING:
-- The average interval between consecutive delivered purchases
-- is 79.15 days across 3,120 purchase intervals.
--
-- The analysis identifies 2,801 repeat customers.
-- The minimum observed interval is 0.00 days,
-- while the maximum interval is 608.98 days.
--
-- INSIGHT:
-- Repeat purchases are separated by an average interval
-- of approximately 79 days.
-- However, the wide range between the minimum and maximum
-- suggests substantial variation in customer purchasing behavior.
--
-- DECISION:
-- Further investigate the distribution of purchase intervals
-- using the median and percentiles to understand typical
-- customer repurchase timing more accurately.
--
-- NOTE:
-- Purchase intervals are calculated between consecutive
-- delivered orders for each customer_unique_id.
-- Customers with more than two delivered orders contribute
-- multiple purchase intervals.
-- The average is calculated across all observed intervals,
-- not as an average of each customer's individual average.
-- A value of 0.00 days may indicate purchases made
-- within a very short time interval on the same day.
-- The analysis does not establish a fixed repurchase cycle.


-- =====================================================
-- 1.26. Purchase Interval Distribution
-- Objective:
-- Analyze the distribution of time intervals
-- between consecutive delivered purchases.
-- =====================================================
WITH customer_purchases AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS previous_purchase_date
    FROM olist.orders o
    JOIN olist.customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),

purchase_intervals AS (
    SELECT
        EXTRACT(
            EPOCH FROM (
                order_purchase_timestamp - previous_purchase_date
            )
        ) / 86400 AS days_between_purchases
    FROM customer_purchases
    WHERE previous_purchase_date IS NOT NULL
)

SELECT
    COUNT(*) AS total_purchase_intervals,
    ROUND(
        PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY days_between_purchases)::numeric,
        2
    ) AS percentile_25_days,
    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY days_between_purchases)::numeric,
        2
    ) AS median_days,
    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY days_between_purchases)::numeric,
        2
    ) AS percentile_75_days,
    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY days_between_purchases)::numeric,
        2
    ) AS percentile_90_days
FROM purchase_intervals;
-- FINDING:
-- A total of 3,120 purchase intervals were analyzed.
-- The 25th percentile (P25) is 0.01 days.
-- The median purchase interval (P50) is 29.46 days.
-- The 75th percentile (P75) is 121.47 days.
-- The 90th percentile (P90) is 240.28 days.
--
-- INSIGHT:
-- The median interval (29.46 days) is substantially lower
-- than the average interval (79.15 days).
-- This indicates a right-skewed distribution, where
-- relatively long purchase intervals increase the average.
--
-- DECISION:
-- Use the median as a more representative measure
-- of the typical purchase interval.
-- Consider percentile analysis when evaluating
-- customer repurchase timing and retention opportunities.
--
-- NOTE:
-- Percentiles are calculated across all consecutive
-- delivered purchase intervals.
-- P50 represents the median, while P25, P75, and P90
-- represent the 25th, 75th, and 90th percentiles.
-- These values describe the distribution of intervals,
-- not a guaranteed repurchase schedule for individual customers.


-- =====================================================
-- 1.27. Purchase Interval Distribution by Time Range
-- Objective:
-- Group purchase intervals into time ranges
-- to understand customer repurchase patterns.
-- =====================================================
WITH customer_purchases AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS previous_purchase_date
    FROM olist.orders o
    JOIN olist.customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),

purchase_intervals AS (
    SELECT
        EXTRACT(
            EPOCH FROM (
                order_purchase_timestamp - previous_purchase_date
            )
        ) / 86400 AS days_between_purchases
    FROM customer_purchases
    WHERE previous_purchase_date IS NOT NULL
),

interval_groups AS (
    SELECT
        CASE
            WHEN days_between_purchases <= 30
                THEN '0-30 Days'
            WHEN days_between_purchases <= 60
                THEN '31-60 Days'
            WHEN days_between_purchases <= 90
                THEN '61-90 Days'
            WHEN days_between_purchases <= 180
                THEN '91-180 Days'
            ELSE 'Above 180 Days'
        END AS purchase_interval_range
    FROM purchase_intervals
)

SELECT
    purchase_interval_range,
    COUNT(*) AS total_intervals,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS interval_percentage
FROM interval_groups
GROUP BY purchase_interval_range
ORDER BY
    CASE purchase_interval_range
        WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '91-180 Days' THEN 4
        WHEN 'Above 180 Days' THEN 5
    END;
-- FINDING:
-- The 0-30 days interval group has the largest share,
-- accounting for 1,564 intervals (50.13%).
--
-- The 31-60 days group accounts for 359 intervals (11.51%),
-- while the 61-90 days group accounts for 225 intervals (7.21%).
--
-- Longer purchase intervals are also observed:
-- 457 intervals (14.65%) fall within 91-180 days,
-- and 515 intervals (16.51%) exceed 180 days.
--
-- INSIGHT:
-- Approximately 68.85% of all purchase intervals
-- occur within 90 days.
-- However, a considerable proportion of intervals
-- exceed 180 days, indicating variation in repurchase timing.
--
-- DECISION:
-- Consider different customer retention approaches
-- based on observed purchase interval patterns.
-- Further analysis can explore whether purchase timing
-- varies across customer segments or product categories.
--
-- NOTE:
-- The distribution is based on 3,120 consecutive
-- delivered purchase intervals, not unique customers.
-- A customer may contribute multiple intervals
-- to the same or different time ranges.
-- Percentages are calculated from total purchase intervals.
-- The results describe historical purchasing behavior
-- and do not establish future repurchase timing.
