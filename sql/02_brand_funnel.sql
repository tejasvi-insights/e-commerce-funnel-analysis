-- ============================================================
-- 02_brand_funnel.sql
-- Brand-level funnel: which brands convert best and worst?
-- ============================================================
-- cehck for NULL brand
SELECT COUNT(*) from events_clean where brand IS NULL group by brand ;
-- Output : 212194

-- Step 1: Total events per brand,-
SELECT
    brand,
    COUNT(*) FILTER (WHERE event_type = 'view')     AS total_views,
    COUNT(*) FILTER (WHERE event_type = 'cart')     AS total_carts,
    COUNT(*) FILTER (WHERE event_type = 'purchase') AS total_purchases
FROM events_clean
WHERE brand IS NOT NULL
GROUP BY brand
ORDER BY total_views DESC
LIMIT 20;

-- Step 2: Brand conversion rates (min 1000 views to filter noise)
WITH brand_funnel AS (
    SELECT
        brand,
        COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS users_viewed,
        COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS users_carted,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchased
    FROM events_clean
    WHERE brand IS NOT NULL
    GROUP BY brand
    HAVING COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) >= 1000
)
SELECT
    brand,
    users_viewed,
    users_carted,
    users_purchased,
    ROUND(users_carted    * 100.0 / NULLIF(users_viewed, 0), 2) AS view_to_cart_rate,
    ROUND(users_purchased * 100.0 / NULLIF(users_carted, 0), 2) AS cart_to_purchase_rate,
    ROUND(users_purchased * 100.0 / NULLIF(users_viewed, 0), 2) AS overall_conversion_rate
FROM brand_funnel
ORDER BY overall_conversion_rate DESC
LIMIT 20;

-- Step 3: Top 10 best converting brands
WITH brand_funnel AS (
    SELECT
        brand,
        COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS users_viewed,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchased
    FROM events_clean
    WHERE brand IS NOT NULL
    GROUP BY brand
    HAVING COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) >= 1000
)
SELECT
    brand,
    users_viewed,
    users_purchased,
    ROUND(users_purchased * 100.0 / NULLIF(users_viewed, 0), 2) AS conversion_rate
FROM brand_funnel
ORDER BY conversion_rate DESC
LIMIT 10;

-- Step 4: Top 10 worst converting brands (high views, low conversion)
WITH brand_funnel AS (
    SELECT
        brand,
        COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS users_viewed,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchased
    FROM events_clean
    WHERE brand IS NOT NULL
    GROUP BY brand
    HAVING COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) >= 1000
)
SELECT
    brand,
    users_viewed,
    users_purchased,
    ROUND(users_purchased * 100.0 / NULLIF(users_viewed, 0), 2) AS conversion_rate
FROM brand_funnel
ORDER BY conversion_rate ASC
LIMIT 10;