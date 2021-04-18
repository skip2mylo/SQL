-- Final project
-- exercise 1 

SELECT 
QUARTER(website_sessions.created_at),
COUNT(DISTINCT website_sessions.website_session_id) AS overall_sessions,
COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
      ON orders.website_session_id=website_sessions.website_session_id
GROUP BY 1;

-- exercise 2
SELECT 
QUARTER(website_sessions.created_at) AS quar,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
SUM(orders.price_usd) AS revenue,
COUNT(DISTINCT orders.order_id) /COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_con_rt,
SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id)  AS revenue_per_order,
SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
      ON orders.website_session_id=website_sessions.website_session_id
GROUP BY 1;


-- exercise 3
SELECT
   QUARTER(website_sessions.created_at) AS quar,
   CASE 
      WHEN utm_source IS NULL AND http_referer IN('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
      WHEN utm_campaign='nonbrand' AND utm_source='gsearch' THEN 'gsearch_nonbrand'
	  WHEN utm_campaign='nonbrand' AND utm_source='bsearch' THEN 'bsearch_nonbrand'
      WHEN utm_campaign='brand' THEN 'overall_brand'
      WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	END AS channel_group,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
     LEFT JOIN orders 
         ON website_sessions.website_session_id=orders.website_session_id
GROUP BY 1,2;

SELECT DISTINCT 
utm_source,
utm_campaign
FROM website_sessions;
