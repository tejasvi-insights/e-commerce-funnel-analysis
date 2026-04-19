-- ============================================================
-- 03_category_funnel.sql
-- Category-level funnel: which categories convert best and worst?
-- ============================================================

-- Check for category_l1
SELECT COUNT(*),category_l1 FROM events_clean WHERE category_l1 IS NOT NULL GROUP BY category_l1;

-- Step 1: Funnel by category L1 (top level)
SELECT
    category_l1,
	COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS users_viewed,
    COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS users_carted,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchased,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2
    ) AS view_to_cart_rate,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2
    ) AS overall_conversion_rate
FROM events_clean
WHERE category_l1 IS NOT NULL
GROUP BY category_l1
ORDER BY users_viewed DESC;

-- Check for category_l2
SELECT COUNT(*),category_l2 FROM events_clean WHERE category_l2 IS NOT NULL GROUP BY category_l2;

-- Step 2: Best converting category L2
SELECT
    category_l1,
    category_l2,
    COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS total_views,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_purchases,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2
    ) AS conversion_rate
FROM events_clean
WHERE category_l2 IS NOT NULL
GROUP BY category_l1, category_l2
HAVING COUNT(*) FILTER (WHERE event_type = 'view') >= 500
ORDER BY conversion_rate DESC
LIMIT 10;

-- Step 3: Worst converting category L2
SELECT
    category_l1,
    category_l2,
    COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS total_views,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_purchases,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2
    ) AS conversion_rate
FROM events_clean
WHERE category_l2 IS NOT NULL
GROUP BY category_l1, category_l2
HAVING COUNT(*) FILTER (WHERE event_type = 'view') >= 500
ORDER BY conversion_rate ASC
LIMIT 10;

-- Step 4: Category L1 cart abandonment rate
SELECT
    category_l1,
    COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS users_carted,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchased,
    COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) -
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_abandoned,
    ROUND(
        (COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) -
         COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END)) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END), 0), 2
    ) AS cart_abandonment_rate
FROM events_clean
WHERE category_l1 IS NOT NULL
GROUP BY category_l1
ORDER BY cart_abandonment_rate DESC;