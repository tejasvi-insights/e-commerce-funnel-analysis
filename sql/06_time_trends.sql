-- ============================================================
-- 06_time_trends.sql
-- Time-based trends: monthly, weekly, hourly patterns
-- ============================================================

-- Step 1: Monthly funnel performance
SELECT
    DATE_TRUNC('month', event_time)                  AS month,
    COUNT(*) FILTER (WHERE event_type = 'view')      AS total_views,
    COUNT(*) FILTER (WHERE event_type = 'cart')      AS total_carts,
    COUNT(*) FILTER (WHERE event_type = 'purchase')  AS total_purchases,
    COUNT(DISTINCT CASE WHEN event_type = 'view'
          THEN user_id END)                          AS unique_viewers,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'
          THEN user_id END)                          AS unique_buyers,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase'
              THEN user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view'
              THEN user_id END), 0), 2)              AS conversion_rate,
    ROUND(SUM(price) FILTER 
          (WHERE event_type = 'purchase'), 2)        AS monthly_revenue
FROM events_clean
GROUP BY DATE_TRUNC('month', event_time)
ORDER BY month;

-- Step 2: Day of week performance
SELECT
    TO_CHAR(event_time, 'Day')                       AS day_name,
    EXTRACT(DOW FROM event_time)                     AS day_num,
    COUNT(*) FILTER (WHERE event_type = 'view')      AS total_views,
    COUNT(*) FILTER (WHERE event_type = 'purchase')  AS total_purchases,
    ROUND(
        COUNT(*) FILTER (WHERE event_type = 'purchase') * 100.0 /
        NULLIF(COUNT(*) FILTER (WHERE event_type = 'view'), 0), 2
    )                                                AS conversion_rate,
   COALESCE(
	    ROUND(SUM(price) FILTER (WHERE event_type = 'purchase'), 2), 
	    0
	) AS total_revenue
FROM events_clean
GROUP BY day_name, day_num
ORDER BY day_num;

-- Step 3: Hourly conversion patterns
SELECT
    EXTRACT(HOUR FROM event_time)                    AS hour_of_day,
    COUNT(*) FILTER (WHERE event_type = 'view')      AS total_views,
    COUNT(*) FILTER (WHERE event_type = 'purchase')  AS total_purchases,
    ROUND(
        COUNT(*) FILTER (WHERE event_type = 'purchase') * 100.0 /
        NULLIF(COUNT(*) FILTER (WHERE event_type = 'view'), 0), 2
    )                                                AS conversion_rate,
    ROUND(SUM(price) FILTER
          (WHERE event_type = 'purchase'), 2)        AS total_revenue
FROM events_clean
GROUP BY hour_of_day
ORDER BY hour_of_day;



-- Step 4: Monthly revenue by category
SELECT
    TO_CHAR(DATE_TRUNC('month', event_time), 'YYYY-MM') AS month,
    category_l1,
    COUNT(*) FILTER (WHERE event_type = 'purchase')     AS total_purchases,
    COALESCE(
        ROUND(SUM(price) FILTER (WHERE event_type = 'purchase'), 2),
        0
    )                                                   AS monthly_revenue
FROM events_clean
WHERE category_l1 IS NOT NULL AND category_l1 <> ''
GROUP BY month, category_l1
ORDER BY month, monthly_revenue DESC;

-- Step 5: Week over week growth
WITH weekly_stats AS (
    SELECT
        DATE_TRUNC('week', event_time)               AS week_start,
        COUNT(*) FILTER (WHERE event_type = 'view')      AS views,
        COUNT(*) FILTER (WHERE event_type = 'purchase')  AS purchases,
        ROUND(SUM(price) FILTER
              (WHERE event_type = 'purchase'), 2)    AS revenue
    FROM events_clean
    GROUP BY DATE_TRUNC('week', event_time)
)
SELECT
    week_start,
    views,
    purchases,
    revenue,
    LAG(revenue) OVER (ORDER BY week_start)          AS prev_week_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY week_start)) * 100.0 /
        NULLIF(LAG(revenue) OVER (ORDER BY week_start), 0), 2
    )                                                AS revenue_growth_pct
FROM weekly_stats
ORDER BY week_start;
