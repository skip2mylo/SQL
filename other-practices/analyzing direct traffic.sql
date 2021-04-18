-- exercise 1 for analyzing channel portfolios
SELECT 
   MIN(DATE(created_at)) AS week_start_date,
   COUNT(DISTINCT CASE WHEN utm_source='gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_sessions,
   COUNT(DISTINCT CASE WHEN utm_source='bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_sessions
  -- COUNT(DISTINCT orders.order_id) AS orders,
  -- COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conversion_rate
FROM website_sessions
    -- LEFT JOIN orders
         -- ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-22' AND '2012-11-29' AND utm_campaign='nonbrand'
GROUP BY YEARWEEK(created_at)
ORDER BY 1;

-- exercise 2 for comparing channel portfolios

SELECT
utm_source,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT CASE WHEN device_type='mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
COUNT(DISTINCT CASE WHEN device_type='mobile' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_mobile

FROM website_sessions
WHERE created_at >'2012-08-22'
	  AND created_at<'2012-11-30'
	  AND utm_campaign='nonbrand' 

GROUP BY 1;

-- exercise 3 for cross-channel bid optimization

SELECT 
website_sessions.device_type,
website_sessions.utm_source,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM website_sessions
    LEFT JOIN orders
         ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at>'2012-08-22' 
      AND website_sessions.created_at< '2012-09-19' 
      AND website_sessions.utm_campaign='nonbrand'
GROUP BY 1,2;

-- exercise 5 for anlyzing chaneel portfolio trends
SELECT
MIN(DATE(created_at)) AS week_start_date,
COUNT(DISTINCT CASE WHEN device_type='desktop' AND utm_source='gsearch' THEN website_session_id ELSE NULL END) AS g_dtop_sessions,
COUNT(DISTINCT CASE WHEN device_type='desktop' AND utm_source='bsearch' THEN website_session_id ELSE NULL END) AS b_dtop_sessions,
COUNT(DISTINCT CASE WHEN device_type='desktop' AND utm_source='bsearch' THEN website_session_id ELSE NULL END)
/COUNT(DISTINCT CASE WHEN device_type='desktop' AND utm_source='gsearch' THEN website_session_id ELSE NULL END) 
AS b_pct_of_g_dtop,
COUNT(DISTINCT CASE WHEN device_type='mobile' AND utm_source='gsearch' THEN website_session_id ELSE NULL END) AS g_mob_sessions,
COUNT(DISTINCT CASE WHEN device_type='mobile' AND utm_source='bsearch' THEN website_session_id ELSE NULL END) AS b_mob_sessions,
COUNT(DISTINCT CASE WHEN device_type='mobile' AND utm_source='bsearch' THEN website_session_id ELSE NULL END) 
/COUNT(DISTINCT CASE WHEN device_type='mobile' AND utm_source='gsearch' THEN website_session_id ELSE NULL END)
AS b_pct_of_g_mobile
FROM website_sessions
WHERE utm_campaign='nonbrand'
      AND created_at>'2012-11-04' 
      AND created_at< '2012-12-22' 
GROUP BY YEARWEEK(created_at)
ORDER BY 1;


-- Analyzing direct, brand-driven traffic

SELECT 
CASE 
    WHEN http_referer IS NULL THEN 'direct_type_in'
    WHEN http_referer ='http:/www.gsearch.com' AND utm_source IS NULL THEN 'gsearch_organic'
	WHEN http_referer ='http:/www.bsearch.com' AND utm_source IS NULL THEN 'bsearch_organic'
    ELSE 'other'
END AS segment,
COUNT(DISTINCT website_session_id) AS sessions
    
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000
     
GROUP BY 1
ORDER BY 2 desc
     ;

-- exercise 5 analyzing direct traffic
SELECT 
   YEAR(created_at) AS yr,
   MONTH(created_at) AS mo,
   website_session_id,
   created_at,
   CASE 
      WHEN utm_source IS NULL AND http_referer IN('http:/www.gsearch.com','http:/www.bsearch.com') THEN 'organic_search'
      WHEN utm_campaign='nonbrand' THEN 'paid_nonbrand'
      WHEN utm_campaign='brand' THEN 'paid_brand'
      WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	END AS channel_group,
    utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at<'2012-12-23';


