WITH base AS (
    SELECT *
    FROM events_clean
)

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT user_id) AS unique_users,

    -- NEW (important additions)
    COUNT(DISTINCT brand) AS unique_brands,
    COUNT(DISTINCT category_code) AS unique_categories,

    -- Funnel metrics
    COUNT(*) FILTER (WHERE event_type = 'view') AS total_views,
    COUNT(*) FILTER (WHERE event_type = 'cart') AS total_carts,
    COUNT(*) FILTER (WHERE event_type = 'purchase') AS total_purchases,

    COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS unique_viewers,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS unique_buyers,

    -- Revenue
    ROUND(SUM(price) FILTER (WHERE event_type = 'purchase'), 2) AS total_revenue,

    -- Conversion
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0),
    2) AS overall_conversion_rate,

    -- Missing Data
    COUNT(*) FILTER (WHERE brand IS NULL) AS missing_brand,
    COUNT(*) FILTER (WHERE category_code IS NULL) AS missing_category

FROM base;


WITH base AS (
    SELECT *
    FROM events_clean
)

SELECT 'total_rows' AS metric, COUNT(*) AS value FROM base
UNION ALL
SELECT 'unique_users', COUNT(DISTINCT user_id) FROM base
UNION ALL
SELECT 'unique_brands', COUNT(DISTINCT brand) FROM base
UNION ALL
SELECT 'unique_categories', COUNT(DISTINCT category_code) FROM base
UNION ALL
SELECT 'total_views', COUNT(*) FILTER (WHERE event_type = 'view') FROM base
UNION ALL
SELECT 'total_carts', COUNT(*) FILTER (WHERE event_type = 'cart') FROM base
UNION ALL
SELECT 'total_purchases', COUNT(*) FILTER (WHERE event_type = 'purchase') FROM base
UNION ALL
SELECT 'unique_viewers', COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) FROM base
UNION ALL
SELECT 'unique_buyers', COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) FROM base
UNION ALL
SELECT 'total_revenue', ROUND(SUM(price) FILTER (WHERE event_type = 'purchase'), 2)  FROM base
UNION ALL
SELECT 'overall_conversion_rate',
       ROUND(
         COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
         NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0),
       2)
FROM base
UNION ALL
SELECT 'missing_brand', COUNT(*) FILTER (WHERE brand IS NULL) FROM base
UNION ALL
SELECT 'missing_category', COUNT(*) FILTER (WHERE category_code IS NULL) FROM base;

