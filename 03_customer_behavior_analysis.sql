
-- =====================================================
-- PROJECT: E-COMMERCE CUSTOMER BEHAVIOR & RETENTION ANALYSIS
-- DATASET: Brazilian E-Commerce Public Dataset by Olist
-- DATABASE: olist_ecommerce
-- SCHEMA: olist
--
-- FILE: 03_customer_behavior_analysis.sql
--
-- DESCRIPTION:
-- Analyze customer purchasing behavior, repeat purchase
-- patterns, and time intervals between purchases.
--
-- KEY ANALYSIS:
-- 1. Repeat Customer Distribution by State
-- 2. Average Orders per Customer by State
-- 3. Customer Purchase Frequency Distribution
-- 4. Overall Repeat Purchase Rate
-- 5. Average Days Between Purchases
-- 6. Purchase Interval Distribution
-- 7. Purchase Interval Distribution by Time Range
--
-- NOTE:
-- Customer-level analysis uses customer_unique_id
-- to identify customers across multiple orders.
-- Only delivered orders are included unless stated otherwise.
-- =====================================================


-- =====================================================
-- 1.1. Repeat Customer Distribution by State
-- OBJECTIVE:
-- Identify states with the highest number and rate
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
-- 1.2. Average Orders per Customer by State
-- OBJECTIVE:
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
-- 1.3. Customer Purchase Frequency Distribution
-- OBJECTIVE:
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
-- 1.4. Overall Repeat Purchase Rate
-- OBJECTIVE:
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
-- 1.5. Average Days Between Purchases
-- OBJECTIVE:
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
-- 1.6. Purchase Interval Distribution
-- OBJECTIVE:
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
-- 1.7. Purchase Interval Distribution by Time Range
-- OBJECTIVE:
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
