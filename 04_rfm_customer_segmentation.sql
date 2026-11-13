
-- =====================================================
-- RFM ANALYSIS
-- Step 1: Improved RFM Scoring & Segmentation
-- =====================================================

WITH analysis_date AS (
    SELECT
        MAX(order_purchase_timestamp)::DATE + 1 AS analysis_date
    FROM olist.orders
    WHERE order_status = 'delivered'
),

customer_rfm AS (
    SELECT
        c.customer_unique_id,

        (a.analysis_date -
            MAX(o.order_purchase_timestamp)::DATE
        ) AS recency,

        COUNT(DISTINCT o.order_id) AS frequency,

        ROUND(
            SUM(oi.price + oi.freight_value)::NUMERIC,
            2
        ) AS monetary

    FROM olist.orders o

    JOIN olist.customers c
        ON o.customer_id = c.customer_id

    JOIN olist.order_items oi
        ON o.order_id = oi.order_id

    CROSS JOIN analysis_date a

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id,
        a.analysis_date
),

rfm_percentiles AS (
    SELECT
        *,

        PERCENT_RANK() OVER (
            ORDER BY recency DESC
        ) AS recency_percentile,

        PERCENT_RANK() OVER (
            ORDER BY monetary ASC
        ) AS monetary_percentile

    FROM customer_rfm
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,

        CASE
            WHEN recency_percentile <= 0.2 THEN 1
            WHEN recency_percentile <= 0.4 THEN 2
            WHEN recency_percentile <= 0.6 THEN 3
            WHEN recency_percentile <= 0.8 THEN 4
            ELSE 5
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency BETWEEN 3 AND 5 THEN 3
            WHEN frequency BETWEEN 6 AND 10 THEN 4
            ELSE 5
        END AS f_score,

        CASE
            WHEN monetary_percentile <= 0.2 THEN 1
            WHEN monetary_percentile <= 0.4 THEN 2
            WHEN monetary_percentile <= 0.6 THEN 3
            WHEN monetary_percentile <= 0.8 THEN 4
            ELSE 5
        END AS m_score

    FROM rfm_percentiles
),

rfm_segments AS (
    SELECT
        *,

        CONCAT(r_score, f_score, m_score) AS rfm_score,

        CASE
            WHEN r_score >= 4
             AND f_score >= 4
             AND m_score >= 4
                THEN 'Champions'

            WHEN r_score >= 3
             AND f_score >= 3
             AND m_score >= 3
                THEN 'Loyal Customers'

            WHEN r_score >= 4
             AND f_score <= 2
                THEN 'New / Recent Customers'

            WHEN r_score <= 2
             AND f_score >= 3
                THEN 'At Risk'

            WHEN r_score <= 2
             AND f_score <= 2
                THEN 'Hibernating'

            ELSE 'Potential Loyalists'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS total_customers,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    ROUND(
        AVG(frequency),
        2
    ) AS average_frequency,

    ROUND(
        AVG(monetary),
        2
    ) AS average_monetary

FROM rfm_segments

GROUP BY customer_segment

ORDER BY total_customers DESC;
-- FINDING:
-- Hibernating is the largest customer segment, consisting of
-- 37,318 customers (39.97%).
--
-- Recent / Low-Frequency Customers account for 37,198 customers
-- (39.84%), while Potential Loyalists represent 18,614 customers
-- (19.94%).
--
-- Loyal Customers account for only 151 customers (0.16%),
-- followed by 71 At Risk customers (0.08%) and
-- 6 Champions (0.01%).
--
-- Champions have the highest average frequency
-- at 7.83 orders and the highest average monetary value
-- at R$860.24.
--
-- INSIGHT:
-- Approximately 79.81% of customers belong to the
-- Hibernating and Recent / Low-Frequency segments.
-- This indicates that the customer base is heavily
-- concentrated in low-frequency purchasing segments.
--
-- Only a small proportion of customers qualify as
-- Loyal Customers or Champions under the current
-- RFM scoring and segmentation rules.
--
-- DECISION:
-- Consider customer retention initiatives for the
-- Hibernating segment and engagement strategies
-- for Recent / Low-Frequency Customers.
--
-- Further investigate the purchasing behavior of
-- Potential Loyalists to identify opportunities
-- for increasing repeat purchases.
--
-- NOTE:
-- RFM analysis uses delivered orders only.
-- Recency is measured in days since the customer's
-- latest delivered order, using the latest delivered
-- purchase date plus one day as the analysis date.
--
-- Frequency represents the number of distinct delivered orders.
-- Monetary represents the total of item prices and freight values,
-- not net revenue or profit.
--
-- Recency and Monetary scores are assigned using
-- PERCENT_RANK(), while Frequency scores use
-- predefined purchase-count ranges.
--
-- Segment labels are assigned using rule-based conditions.
-- Recent / Low-Frequency Customers does not necessarily mean
-- newly acquired customers because customer acquisition date
-- is not measured in this analysis.
--
-- Results describe historical customer behavior and
-- do not establish the causes of customer purchasing patterns.
