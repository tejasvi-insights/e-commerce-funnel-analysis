-- ============================================================
-- 01_funnel_dropoff.sql
-- Core funnel: view → cart → purchase
-- Conversion rates and drop-off at each stage
-- ============================================================

-- Step 1: Overall funnel counts
SELECT
    COUNT(*) FILTER (WHERE event_type = 'view')     AS total_views,
    COUNT(*) FILTER (WHERE event_type = 'cart')     AS total_carts,
    COUNT(*) FILTER (WHERE event_type = 'purchase') AS total_purchases
FROM events_clean;
-- Output
-- total_views  total_carts total_purchases
-- 792943       54026        37343

-- Step 2: Unique users at each funnel stage
SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS users_viewed,
    COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS users_carted,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchased
FROM events_clean;
-- Output
-- users_viewed  users_carted  users_purchased
-- 406817        36948         21304

-- Step 3: Conversion rates between each step
WITH funnel AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS users_viewed,
        COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS users_carted,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchased
    FROM events_clean
)
SELECT
    users_viewed,
    users_carted,
    users_purchased,
    ROUND(users_carted     * 100.0 / NULLIF(users_viewed,  0), 2) AS view_to_cart_rate,
    ROUND(users_purchased  * 100.0 / NULLIF(users_carted,  0), 2) AS cart_to_purchase_rate,
    ROUND(users_purchased  * 100.0 / NULLIF(users_viewed,  0), 2) AS overall_conversion_rate
FROM funnel;
-- Output
-- users_viewed  406817   view_to_cart_rate         9.08
-- users_carted	 36948	  cart_to_purchase_rate     57.66
-- users_purchased 21304  overall_conversion_rate   5.24
	

-- Step 4: Cart abandonment rate
WITH funnel AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS users_carted,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchased
    FROM events_clean
)
SELECT
    users_carted,
    users_purchased,
    users_carted - users_purchased                              AS users_abandoned,
    ROUND((users_carted - users_purchased) * 100.0 
          / users_carted, 2)                                    AS cart_abandonment_rate
FROM funnel;
-- Output
-- users_carted users_purchased users_abandoned cart_abandonment_rate
-- 36948        21304           15644           42.34