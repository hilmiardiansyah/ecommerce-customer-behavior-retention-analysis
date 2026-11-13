
-- =====================================================
-- E-COMMERCE CUSTOMER BEHAVIOR & RETENTION ANALYSIS
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Database: olist_ecommerce
-- Schema: olist
-- File: 04_cohort_retention_analysis.sql
-- =====================================================

-- =====================================================
-- COHORT RETENTION ANALYSIS
-- Step 1: Customer Cohort Assignment and Cohort Size
-- =====================================================

-- OBJECTIVE:
-- Identify each customer's first delivered purchase month
-- and calculate the number of customers in each cohort.

WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS purchase_month

    FROM olist.orders o

    JOIN olist.customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),

customer_cohort AS (
    SELECT
        customer_unique_id,
        MIN(purchase_month) AS cohort_month

    FROM delivered_orders

    GROUP BY customer_unique_id
)

SELECT
    cohort_month,
    COUNT(*) AS total_customers

FROM customer_cohort

GROUP BY cohort_month

ORDER BY cohort_month;
-- FINDING:
-- A total of 93,358 unique customers were assigned to 23 monthly cohorts.
-- November 2017 recorded the largest cohort, with 7,060 customers.
-- January 2018 recorded the second-largest cohort, with 6,842 customers.
-- September and December 2016 had the smallest cohorts, with 1 customer each.

-- INSIGHT:
-- Customer acquisition, measured by the first delivered purchase,
-- increased substantially throughout 2017 and remained relatively high in 2018.

-- NOTE:
-- Cohort assignment is based on each customer's first delivered order.
-- Customers are identified using customer_unique_id.
-- The dataset covers an incomplete period in the first and last months.
-- Cohort size alone does not explain the reasons behind customer growth.



-- =====================================================
-- Step 2: Monthly Active Customers by Cohort
-- =====================================================
-- OBJECTIVE:
-- Calculate the number of distinct customers making
-- delivered purchases in each month relative to their cohort month.

WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS purchase_month

    FROM olist.orders o

    JOIN olist.customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),

customer_cohort AS (
    SELECT
        customer_unique_id,
        MIN(purchase_month) AS cohort_month

    FROM delivered_orders

    GROUP BY customer_unique_id
),

cohort_data AS (
    SELECT
        d.customer_unique_id,
        c.cohort_month,
        d.purchase_month,

        (
            EXTRACT(YEAR FROM d.purchase_month) * 12
            + EXTRACT(MONTH FROM d.purchase_month)
        ) -
        (
            EXTRACT(YEAR FROM c.cohort_month) * 12
            + EXTRACT(MONTH FROM c.cohort_month)
        ) AS cohort_index

    FROM delivered_orders d

    JOIN customer_cohort c
        ON d.customer_unique_id = c.customer_unique_id
)

SELECT
    cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_unique_id) AS active_customers

FROM cohort_data

GROUP BY
    cohort_month,
    cohort_index

ORDER BY
    cohort_month,
    cohort_index;
-- FINDING:
-- Cohort activity is highest in Month 0, representing the initial
-- delivered purchase month.
-- Subsequent months show substantially fewer active customers
-- compared with the initial cohort size.
-- November 2017 recorded 7,060 customers in Month 0,
-- followed by 40 active customers in Month 1 and 26 in Month 2.

-- INSIGHT:
-- Repeat purchasing activity is relatively low across the observed cohorts.
-- Some customers return to make purchases several months after
-- their initial delivered purchase.

-- NOTE:
-- Active customers are counted using distinct customer_unique_id.
-- Cohort index represents the number of calendar months since cohort entry.
-- Missing cohort index values indicate no recorded active customers
-- for that cohort and period in the query output.
-- Later cohorts have shorter observation periods.
-- Activity in one month does not imply continuous activity
-- in the preceding months.


-- =====================================================
-- Step 3: Cohort Retention Rate
-- =====================================================
-- OBJECTIVE:
-- Calculate the percentage of customers who make
-- delivered purchases in each month relative to their
-- initial cohort size.

WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS purchase_month

    FROM olist.orders o

    JOIN olist.customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),

customer_cohort AS (
    SELECT
        customer_unique_id,
        MIN(purchase_month) AS cohort_month

    FROM delivered_orders

    GROUP BY customer_unique_id
),

cohort_data AS (
    SELECT
        d.customer_unique_id,
        c.cohort_month,

        (
            EXTRACT(YEAR FROM d.purchase_month) * 12
            + EXTRACT(MONTH FROM d.purchase_month)
        ) -
        (
            EXTRACT(YEAR FROM c.cohort_month) * 12
            + EXTRACT(MONTH FROM c.cohort_month)
        ) AS cohort_index

    FROM delivered_orders d

    JOIN customer_cohort c
        ON d.customer_unique_id = c.customer_unique_id
),

cohort_size AS (
    SELECT
        cohort_month,
        COUNT(*) AS total_customers

    FROM customer_cohort

    GROUP BY cohort_month
),

retention AS (
    SELECT
        cd.cohort_month,
        cd.cohort_index,

        COUNT(DISTINCT cd.customer_unique_id)
            AS active_customers,

        cs.total_customers

    FROM cohort_data cd

    JOIN cohort_size cs
        ON cd.cohort_month = cs.cohort_month

    GROUP BY
        cd.cohort_month,
        cd.cohort_index,
        cs.total_customers
)

SELECT
    cohort_month,
    cohort_index,
    active_customers,
    total_customers,

    ROUND(
        active_customers::NUMERIC
        / total_customers * 100,
        2
    ) AS retention_rate

FROM retention

ORDER BY
    cohort_month,
    cohort_index;

-- FINDING:
-- All cohorts recorded a 100% retention rate in Month 0.
-- October 2017 recorded the highest Month 1 retention rate
-- among the cohorts with recorded Month 1 activity, at 0.72%.
-- September 2017 followed at 0.70%, while August 2017
-- recorded 0.69%.
-- Most cohorts recorded Month 1 retention rates below 1%.

-- INSIGHT:
-- Monthly repeat purchasing activity is relatively low
-- compared with the initial cohort size.
-- Some customers continue to make delivered purchases
-- several months after their initial purchase.

-- NOTE:
-- Retention rate is calculated by dividing active customers
-- in each cohort month by the initial cohort size.
-- Month 0 represents the initial purchase month and has
-- a retention rate of 100%.
-- Missing cohort index rows are not displayed by this query.
-- They must be distinguished from periods outside
-- the available observation window.
-- Retention measures monthly purchasing activity,
-- not continuous customer activity.



-- =====================================================
-- Step 4: Cohort Retention Matrix (Month 0-3)
-- =====================================================

-- OBJECTIVE:
-- Create a cohort retention matrix showing monthly
-- customer retention rates from Month 0 to Month 3.
-- Observed periods without active customers are represented
-- as 0%, while unobserved future periods remain NULL.

WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS purchase_month

    FROM olist.orders o

    JOIN olist.customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),

customer_cohort AS (
    SELECT
        customer_unique_id,
        MIN(purchase_month) AS cohort_month

    FROM delivered_orders

    GROUP BY customer_unique_id
),

cohort_data AS (
    SELECT DISTINCT
        d.customer_unique_id,
        c.cohort_month,

        (
            EXTRACT(YEAR FROM d.purchase_month) * 12
            + EXTRACT(MONTH FROM d.purchase_month)
        ) -
        (
            EXTRACT(YEAR FROM c.cohort_month) * 12
            + EXTRACT(MONTH FROM c.cohort_month)
        ) AS cohort_index

    FROM delivered_orders d

    JOIN customer_cohort c
        ON d.customer_unique_id = c.customer_unique_id
),

cohort_size AS (
    SELECT
        cohort_month,
        COUNT(*) AS total_customers

    FROM customer_cohort

    GROUP BY cohort_month
),

observation_period AS (
    SELECT
        MAX(purchase_month) AS last_observed_month
    FROM delivered_orders
),

cohort_activity AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS active_customers

    FROM cohort_data

    GROUP BY
        cohort_month,
        cohort_index
),

cohort_calendar AS (
    SELECT
        cs.cohort_month,
        cs.total_customers,
        generate_series(
            0,
            (
                EXTRACT(YEAR FROM op.last_observed_month) * 12
                + EXTRACT(MONTH FROM op.last_observed_month)
            ) -
            (
                EXTRACT(YEAR FROM cs.cohort_month) * 12
                + EXTRACT(MONTH FROM cs.cohort_month)
            )
        ) AS cohort_index

    FROM cohort_size cs
    CROSS JOIN observation_period op
),

retention_matrix AS (
    SELECT
        cc.cohort_month,
        cc.cohort_index,

        COALESCE(ca.active_customers, 0)
            AS active_customers,

        cc.total_customers,

        ROUND(
            COALESCE(ca.active_customers, 0)::NUMERIC
            / cc.total_customers * 100,
            2
        ) AS retention_rate

    FROM cohort_calendar cc

    LEFT JOIN cohort_activity ca
        ON cc.cohort_month = ca.cohort_month
       AND cc.cohort_index = ca.cohort_index
)

SELECT
    cohort_month,

    MAX(retention_rate) FILTER (
        WHERE cohort_index = 0
    ) AS month_0,

    MAX(retention_rate) FILTER (
        WHERE cohort_index = 1
    ) AS month_1,

    MAX(retention_rate) FILTER (
        WHERE cohort_index = 2
    ) AS month_2,

    MAX(retention_rate) FILTER (
        WHERE cohort_index = 3
    ) AS month_3

FROM retention_matrix

GROUP BY cohort_month

ORDER BY cohort_month;
-- FINDING:
-- All cohorts recorded a 100% retention rate in Month 0.
-- October 2017 recorded the highest Month 1 retention rate at 0.72%.
-- September 2017 recorded the highest Month 2 retention rate at 0.55%.
-- December 2017 recorded the highest Month 3 retention rate at 0.34%.
-- Recent cohorts have fewer observed months due to the dataset's
-- observation period ending in 2018.

-- INSIGHT:
-- Customer retention remains low across the observed cohorts,
-- with monthly retention rates generally below 1% after Month 0.
-- Retention patterns vary across cohorts and observation months.
-- The results indicate limited repeat purchasing activity
-- within the observed monthly periods.

-- NOTE:
-- Month 0 represents the initial delivered purchase month.
-- Retention rate is calculated using the initial cohort size
-- as the denominator.
-- A value of 0% indicates an observed month with no active customers.
-- NULL indicates a future month outside the observation period.
-- Retention measures monthly purchasing activity, not continuous activity.
-- Results are descriptive and do not establish the causes
-- of low customer retention.


