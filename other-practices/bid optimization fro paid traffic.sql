USE mavenfuzzyfactory;
SELECT
   MIN(DATE(website_sessions.created_at)) AS week_start_date,
   -- COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
   -- COUNT(DISTINCT orders.order_id) AS orders,
   COUNT(DISTINCT CASE WHEN website_sessions. device_type='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mob_sessions,
   COUNT(DISTINCT CASE WHEN website_sessions. device_type='desktop' THEN website_sessions.website_session_id ELSE NULL END) AS dtop_sessions
   -- COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions. website_session_id) AS session_to_order_conv_rt
FROM website_sessions
    LEFT JOIN orders
           ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-06-09'
AND  website_sessions.created_at> '2012-04-15'
AND utm_source ='gsearch'
AND utm_campaign='nonbrand'
GROUP BY 
    YEAR(website_sessions.created_at),
    WEEK(website_sessions.created_at)


