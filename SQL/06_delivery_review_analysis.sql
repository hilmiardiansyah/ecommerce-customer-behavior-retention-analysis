-- =====================================================
-- DELIVERY PERFORMANCE VS REVIEW SCORE
-- Step 1: Delivery Performance and Average Review Score
-- =====================================================

WITH review_per_order AS (
    SELECT
        order_id,
        AVG(review_score)::NUMERIC AS average_review_score,
        COUNT(*) AS review_count
    FROM olist.order_reviews
    GROUP BY order_id
),

delivery_analysis AS (
    SELECT
        o.order_id,
        o.order_delivered_customer_date::DATE AS delivered_date,
        o.order_estimated_delivery_date::DATE AS estimated_date,
        (
            o.order_delivered_customer_date::DATE -
            o.order_estimated_delivery_date::DATE
        ) AS delay_days,
        r.average_review_score
    FROM olist.orders o
    LEFT JOIN review_per_order r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),

delivery_category AS (
    SELECT *,
        CASE
            WHEN delay_days > 0 THEN 'Late Delivery'
            ELSE 'On Time / Early'
        END AS delivery_status
    FROM delivery_analysis
)

SELECT
    delivery_status,
    COUNT(*) AS total_orders,
    COUNT(average_review_score) AS orders_with_review,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(AVG(delay_days::NUMERIC), 2) AS average_delay_days
FROM delivery_category
GROUP BY delivery_status
ORDER BY average_review_score DESC;
-- FINDING:
-- A total of 89,936 orders (93.23%) were delivered on time or early,
-- while 6,534 orders (6.77%) were delivered late.
-- On Time / Early orders recorded an average review score of 4.29,
-- compared with 2.27 for Late Delivery orders.
-- On Time / Early orders were delivered an average of 13.51 days
-- before the estimated delivery date.
-- Late Delivery orders exceeded the estimated delivery date
-- by an average of 10.62 days.
-- Review coverage reached 99.45% for On Time / Early orders
-- and 97.66% for Late Delivery orders.

-- INSIGHT:
-- Orders delivered late are associated with substantially lower
-- average review scores than orders delivered on time or early.
-- The 2.02-point difference in average review scores highlights
-- a notable relationship between delivery performance
-- and customer satisfaction ratings.

-- DECISION:
-- Consider prioritizing delivery monitoring and improving
-- the handling of orders at risk of missing their estimated dates.
-- Further investigate late delivery cases to identify
-- potential areas for operational improvement.

-- NOTE:
-- The analysis includes delivered orders with both actual
-- and estimated delivery dates available.
-- Delivery delay is calculated using calendar dates.
-- Negative delay values indicate early delivery.
-- Review scores are averaged at the order level.
-- Orders without review records are excluded from the
-- average review score calculation.
-- Eight delivered orders were excluded because at least
-- one required delivery date was unavailable.
-- The results describe an association and do not establish
-- that delivery delays directly cause lower review scores.


-- =====================================================
-- Step 2: Review Score Distribution by Delivery Status
-- =====================================================

-- OBJECTIVE:
-- Analyze the distribution of review scores for orders
-- delivered on time or early compared with late deliveries.

WITH delivery_analysis AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_delivered_customer_date::DATE >
                 o.order_estimated_delivery_date::DATE
            THEN 'Late Delivery'
            ELSE 'On Time / Early'
        END AS delivery_status
    FROM olist.orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),

review_distribution AS (
    SELECT
        d.delivery_status,
        r.review_score,
        COUNT(*) AS total_reviews
    FROM delivery_analysis d
    JOIN olist.order_reviews r
        ON d.order_id = r.order_id
    GROUP BY
        d.delivery_status,
        r.review_score
)

SELECT
    delivery_status,
    review_score,
    total_reviews,
    ROUND(
        total_reviews * 100.0 /
        SUM(total_reviews) OVER (
            PARTITION BY delivery_status
        ),
        2
    ) AS review_percentage
FROM review_distribution
ORDER BY
    delivery_status,
    review_score;
-- FINDING:
-- Late Delivery orders recorded the highest proportion
-- of review score 1, accounting for 3,444 reviews (53.74%).
-- On Time / Early orders recorded the highest proportion
-- of review score 5, accounting for 55,999 reviews (62.26%).
-- Low review scores (1-2) accounted for 62.42% of
-- Late Delivery reviews, compared with 9.28% for
-- On Time / Early reviews.
-- High review scores (4-5) accounted for 26.71% of
-- Late Delivery reviews, compared with 82.64% for
-- On Time / Early reviews.

-- INSIGHT:
-- Review score distributions differ substantially
-- between Late Delivery and On Time / Early orders.
-- Late deliveries are associated with a higher proportion
-- of negative reviews, while on-time or early deliveries
-- are associated with a higher proportion of positive reviews.

-- DECISION:
-- Consider prioritizing late delivery prevention
-- and monitoring customer feedback for delayed orders.
-- Further investigate other factors that may contribute
-- to low customer review scores.

-- NOTE:
-- Review percentages are calculated within each
-- delivery status category.
-- Each review record is counted as one observation.
-- Orders with multiple review records may contribute
-- more than one observation.
-- Review scores range from 1 (lowest) to 5 (highest).
-- Low scores refer to scores 1-2, while high scores
-- refer to scores 4-5.
-- The results describe an association and do not establish
-- a causal relationship between delivery delays and review scores.


-- =====================================================
-- Step 3: Average Review Score by Delivery Delay Range
-- =====================================================

-- OBJECTIVE:
-- Analyze average customer review scores across different
-- delivery delay ranges to identify rating patterns.

WITH review_per_order AS (
    SELECT
        order_id,
        AVG(review_score)::NUMERIC AS average_review_score
    FROM olist.order_reviews
    GROUP BY order_id
),

delivery_analysis AS (
    SELECT
        o.order_id,
        (
            o.order_delivered_customer_date::DATE -
            o.order_estimated_delivery_date::DATE
        ) AS delay_days,
        r.average_review_score
    FROM olist.orders o
    LEFT JOIN review_per_order r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),

delay_categories AS (
    SELECT
        order_id,
        delay_days,
        average_review_score,
        CASE
            WHEN delay_days <= -30 THEN '30+ Days Early'
            WHEN delay_days BETWEEN -29 AND -8 THEN '8-29 Days Early'
            WHEN delay_days BETWEEN -7 AND 0 THEN '0-7 Days Early'
            WHEN delay_days BETWEEN 1 AND 7 THEN '1-7 Days Late'
            WHEN delay_days BETWEEN 8 AND 14 THEN '8-14 Days Late'
            WHEN delay_days BETWEEN 15 AND 30 THEN '15-30 Days Late'
            ELSE 'More Than 30 Days Late'
        END AS delay_range
    FROM delivery_analysis
)

SELECT
    delay_range,
    COUNT(*) AS total_orders,
    COUNT(average_review_score) AS orders_with_review,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(AVG(delay_days::NUMERIC), 2) AS average_delay_days
FROM delay_categories
GROUP BY delay_range
ORDER BY
    CASE delay_range
        WHEN '30+ Days Early' THEN 1
        WHEN '8-29 Days Early' THEN 2
        WHEN '0-7 Days Early' THEN 3
        WHEN '1-7 Days Late' THEN 4
        WHEN '8-14 Days Late' THEN 5
        WHEN '15-30 Days Late' THEN 6
        WHEN 'More Than 30 Days Late' THEN 7
    END;
-- FINDING:
-- Orders delivered 8-29 days early recorded the highest
-- average review score at 4.32.
-- Orders delivered 1-7 days late recorded an average
-- review score of 2.72.
-- Orders delivered 8-14 days late recorded an average
-- review score of 1.67.
-- Orders delivered 15-30 days late recorded the lowest
-- average review score at 1.62.
-- Orders delivered more than 30 days late recorded
-- an average review score of 2.06, based on 345 orders.

-- INSIGHT:
-- Orders delivered earlier than their estimated dates
-- generally received higher average review scores.
-- Late delivery categories recorded substantially lower
-- average review scores.
-- However, the relationship is not strictly linear,
-- as orders delayed by more than 30 days recorded
-- a higher average score than the 8-30 day delay groups.

-- DECISION:
-- Consider prioritizing delivery performance monitoring,
-- particularly for orders at risk of being delayed.
-- Further investigate the factors behind late deliveries
-- and their relationship with customer feedback.

-- NOTE:
-- Each order is counted once in the analysis.
-- Multiple reviews for an order are aggregated
-- using the average review score.
-- Delivery delay is calculated using calendar dates.
-- Negative values indicate early delivery.
-- Delay categories are based on predefined day ranges.
-- The more than 30 days late category contains
-- a relatively small number of orders.
-- Results are descriptive and do not establish causality.
