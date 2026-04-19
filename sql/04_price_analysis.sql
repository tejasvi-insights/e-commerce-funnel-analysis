-- ============================================================
-- 04_price_analysis.sql
-- Price segments: how does price affect conversion?
-- ============================================================

-- Step 1: Price distribution overview
SELECT
    MIN(price)                                    AS min_price,
    MAX(price)                                    AS max_price,
    ROUND(AVG(price), 2)                          AS avg_price,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP 
          (ORDER BY price)::NUMERIC, 2)           AS p25_price,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP 
          (ORDER BY price)::NUMERIC, 2)           AS median_price,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP 
          (ORDER BY price)::NUMERIC, 2)           AS p75_price
FROM events_clean
WHERE event_type = 'view';
-- Output
-- min_price max_price avg_price p25_price median_price p75_price
-- 0.22      64771.06  145.84    26.19     64.92        186.76

-- Step 2: Conversion rate by price segment
WITH price_segments AS (
    SELECT *,
        CASE
            WHEN price < 50 THEN '1. Budget (<$50)'
            WHEN price >= 50 AND price < 200 THEN '2. Mid ($50–$199)'
            WHEN price >= 200 AND price < 500 THEN '3. Upper-mid ($200–$499)'
            ELSE '4. Premium ($500+)'
        END AS price_segment
    FROM events_clean
)
SELECT
    price_segment,
    COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS users_viewed,
    COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS users_carted,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchased,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2
    ) AS view_to_cart_rate,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2
    ) AS overall_conversion_rate,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END), 0), 2
    ) AS cart_to_purchase_rate
FROM price_segments
GROUP BY price_segment
ORDER BY price_segment;

-- Step 3: Average order value (AOV) by price segment
SELECT
    CASE
        WHEN price < 50 THEN '1. Budget (<$50)'
        WHEN price >= 50 AND price < 200 THEN '2. Mid ($50–$199)'
        WHEN price >= 200 AND price < 500 THEN '3. Upper-mid ($200–$499)'
		WHEN price >= 2000 THEN '5. Enterprise ($2000+)'
        ELSE '4. Premium ($500+)'
    END AS price_segment,

    COUNT(*) AS total_purchases,
    ROUND(AVG(price), 2) AS avg_purchase_value,
    ROUND(SUM(price), 2) AS total_revenue

FROM events_clean
WHERE event_type = 'purchase'
GROUP BY price_segment
ORDER BY price_segment;

-- Step 4: Sweet spot — highest converting price ranges
WITH price_buckets AS (
    SELECT *,
        FLOOR(price / 50) * 50 AS price_bucket
    FROM events_clean
    WHERE price <= 2000
)
SELECT
    CONCAT(price_bucket, '-', price_bucket + 50) AS price_range,

    COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'view') AS users_viewed,
    COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'cart') AS users_carted,
    COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'purchase') AS users_purchased,

    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'cart') * 100.0 /
        NULLIF(COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'view'), 0), 2
    ) AS view_to_cart_rate,

    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'purchase') * 100.0 /
        NULLIF(COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'view'), 0), 2
    ) AS overall_conversion_rate,

    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'purchase') * 100.0 /
        NULLIF(COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'cart'), 0), 2
    ) AS cart_to_purchase_rate

FROM price_buckets
GROUP BY price_bucket
HAVING COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'view') >= 500
ORDER BY overall_conversion_rate DESC
LIMIT 15;

-- How many events are above $2000?
SELECT
    COUNT(*) FILTER (WHERE event_type = 'view')     AS views,
    COUNT(*) FILTER (WHERE event_type = 'cart')     AS carts,
    COUNT(*) FILTER (WHERE event_type = 'purchase') AS purchases,
    ROUND(AVG(price), 2)                            AS avg_price,
    MIN(price)                                      AS min_price,
    MAX(price)                                      AS max_price,
    COUNT(*)                                        AS total_rows
FROM events_clean
WHERE price > 2000;

-- Note: 1,424 rows (0.16% of data) have price > $2,000
-- These are excluded from bucket analysis as statistical outliers
-- (enterprise/server equipment, avg $3,683, only 9 purchases)
-- They are captured in the '$500+' segment of Step 2 price segment analysis