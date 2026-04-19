-- ============================================================
-- 05_session_analysis.sql
-- Session analysis: user journey, time between events,
-- repeat behaviour using window functions
-- ============================================================

-- Step 1: Average session duration and events per session
WITH session_stats AS (
    SELECT
        user_session,
        user_id,
        COUNT(*)                                    AS events_in_session,
        MIN(event_time)                             AS session_start,
        MAX(event_time)                             AS session_end,
        EXTRACT(EPOCH FROM (MAX(event_time) 
                - MIN(event_time))) / 60            AS session_duration_mins,
        COUNT(DISTINCT event_type)                  AS unique_event_types,
        MAX(CASE WHEN event_type = 'purchase' 
                 THEN 1 ELSE 0 END)                 AS converted
    FROM events_clean
    GROUP BY user_session, user_id
)
SELECT
    ROUND(AVG(session_duration_mins), 2)            AS avg_session_duration_mins,
    ROUND(AVG(events_in_session), 2)                AS avg_events_per_session,
    ROUND(AVG(CASE WHEN converted = 1 
              THEN session_duration_mins END), 2)   AS avg_duration_converted,
    ROUND(AVG(CASE WHEN converted = 0 
              THEN session_duration_mins END), 2)   AS avg_duration_not_converted,
    COUNT(*)                                        AS total_sessions,
    SUM(converted)                                  AS converted_sessions,
    ROUND(SUM(converted) * 100.0 
          / NULLIF(COUNT(*), 0), 2)                 AS session_conversion_rate
FROM session_stats;

-- Check session duration distribution
WITH session_stats AS (
    SELECT
        user_session,
        EXTRACT(EPOCH FROM (MAX(event_time) 
                - MIN(event_time))) / 60 AS duration_mins
    FROM events_clean
    GROUP BY user_session
)
SELECT
    COUNT(*) FILTER (WHERE duration_mins = 0)      AS instant_sessions,
    COUNT(*) FILTER (WHERE duration_mins <= 30)    AS under_30mins,
    COUNT(*) FILTER (WHERE duration_mins <= 60)    AS under_1hr,
    COUNT(*) FILTER (WHERE duration_mins <= 1440)  AS under_24hrs,
    COUNT(*) FILTER (WHERE duration_mins > 1440)   AS over_24hrs,
    COUNT(*)                                       AS total_sessions
FROM session_stats;

-- Step 1 revised: cap session duration at 1440 mins (24 hours)
-- 10,362 sessions (2.1%) exceed 24hrs and are outliers
WITH session_stats AS (
    SELECT
        user_session,
        user_id,
        COUNT(*)                                     AS events_in_session,
        MIN(event_time)                              AS session_start,
        MAX(event_time)                              AS session_end,
        LEAST(
            EXTRACT(EPOCH FROM (MAX(event_time)
                    - MIN(event_time))) / 60, 1440
        )                                            AS session_duration_mins,
        MAX(CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END)                  AS converted
    FROM events_clean
    GROUP BY user_session, user_id
)
SELECT
    ROUND(AVG(session_duration_mins), 2)             AS avg_session_duration_mins,
    ROUND(AVG(events_in_session), 2)                 AS avg_events_per_session,
    ROUND(AVG(CASE WHEN converted = 1
              THEN session_duration_mins END), 2)    AS avg_duration_converted,
    ROUND(AVG(CASE WHEN converted = 0
              THEN session_duration_mins END), 2)    AS avg_duration_not_converted,
    COUNT(*)                                         AS total_sessions,
    SUM(converted)                                   AS converted_sessions,
    ROUND(SUM(converted) * 100.0
          / NULLIF(COUNT(*), 0), 2)                  AS session_conversion_rate
FROM session_stats;
-- Output
-- avg_session_duration_mins  - 43.27
-- avg_events_per_session - 1.80
-- avg_duration_converted - 152.96
-- avg_duration_not_converted - 37.55
-- total_sessions - 490633
-- converted_sessions - 24348
-- session_conversion_rate - 4.96

-- Step 2: Time between view and purchase using LAG
WITH user_events AS (
    SELECT
        user_id,
        product_id,
        event_type,
        event_time,
        LAG(event_time) OVER (
            PARTITION BY user_id, product_id 
            ORDER BY event_time
        )                                           AS prev_event_time,
        LAG(event_type) OVER (
            PARTITION BY user_id, product_id 
            ORDER BY event_time
        )                                           AS prev_event_type
    FROM events_clean
)
SELECT
    prev_event_type                                 AS from_event,
    event_type                                      AS to_event,
    COUNT(*)                                        AS transitions,
    ROUND(AVG(EXTRACT(EPOCH FROM 
        (event_time - prev_event_time)) / 60), 2)  AS avg_mins_between_events,
    ROUND(MIN(EXTRACT(EPOCH FROM 
        (event_time - prev_event_time)) / 60), 2)  AS min_mins,
    ROUND(MAX(EXTRACT(EPOCH FROM 
        (event_time - prev_event_time)) / 60), 2)  AS max_mins
FROM user_events
WHERE prev_event_type IS NOT NULL
  AND event_time > prev_event_time
GROUP BY prev_event_type, event_type
ORDER BY transitions DESC;

-- Step 3: Repeat user behaviour
WITH user_purchases AS (
    SELECT
        user_id,
        COUNT(*) FILTER (WHERE event_type = 'purchase') AS total_purchases,
        COUNT(*) FILTER (WHERE event_type = 'view')     AS total_views,
        COUNT(*) FILTER (WHERE event_type = 'cart')     AS total_carts,
        MIN(event_time)                                  AS first_event,
        MAX(event_time)                                  AS last_event
    FROM events_clean
    GROUP BY user_id
)
SELECT
    CASE
        WHEN total_purchases = 0 THEN '0 purchases'
        WHEN total_purchases = 1 THEN '1 purchase'
        WHEN total_purchases = 2 THEN '2 purchases'
        WHEN total_purchases BETWEEN 3 AND 5 THEN '3-5 purchases'
        WHEN total_purchases > 5             THEN '6+ purchases'
    END                                             AS purchase_segment,
    COUNT(*)                                        AS total_users,
    ROUND(AVG(total_views), 2)                      AS avg_views,
    ROUND(AVG(total_carts), 2)                      AS avg_carts,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) 
          OVER(), 2)                                AS pct_of_users
FROM user_purchases
GROUP BY purchase_segment
ORDER BY purchase_segment;

-- Step 4: Top 10 most active users (power users)
WITH user_stats AS (
    SELECT
        user_id,
        COUNT(*)                                         AS total_events,
        COUNT(*) FILTER (WHERE event_type = 'view')     AS views,
        COUNT(*) FILTER (WHERE event_type = 'cart')     AS carts,
        COUNT(*) FILTER (WHERE event_type = 'purchase') AS purchases,
        COUNT(DISTINCT user_session)                     AS total_sessions,
        MIN(event_time)                                  AS first_seen,
        MAX(event_time)                                  AS last_seen,
        ROUND(AVG(price) FILTER 
              (WHERE event_type = 'purchase'), 2)        AS avg_purchase_value
    FROM events_clean
    GROUP BY user_id
)
SELECT *
FROM user_stats
ORDER BY purchases DESC
LIMIT 10;

-- Step 5: Multi-session conversion analysis
-- Do users who come back in multiple sessions convert more?
WITH user_sessions AS (
    SELECT
        user_id,
        COUNT(DISTINCT user_session)                     AS total_sessions,
        MAX(CASE WHEN event_type = 'purchase' 
                 THEN 1 ELSE 0 END)                      AS ever_purchased
    FROM events_clean
    GROUP BY user_id
)
SELECT
    CASE
        WHEN total_sessions = 1  THEN '1 session'
        WHEN total_sessions = 2  THEN '2 sessions'
        WHEN total_sessions BETWEEN 3 AND 5 THEN '3-5 sessions'
        WHEN total_sessions > 5             THEN '6+ sessions'
    END                                                  AS session_segment,
    COUNT(*)                                             AS total_users,
    SUM(ever_purchased)                                  AS converted_users,
    ROUND(SUM(ever_purchased) * 100.0 
          / NULLIF(COUNT(*), 0), 2)                      AS conversion_rate
FROM user_sessions
GROUP BY session_segment
ORDER BY session_segment;