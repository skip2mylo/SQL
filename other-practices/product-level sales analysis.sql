SELECT
   primary_product_id,
   COUNT(order_id) AS orders,
   SUM(price_usd) AS revenue,
   SUM(price_usd-cogs_usd) AS margin,
   AVG(price_usd) AS aov

FROM orders
WHERE order_id BETWEEN 10000 AND 11000 -- arbitary
GROUP BY 1
ORDER BY 2 DESC;

SELECT
YEAR(created_at) AS yr,
MONTH(created_at) AS mo,
COUNT(DISTINCT order_id) AS number_of_sales,
SUM(price_usd) AS total_revenue,
SUM(price_usd-cogs_usd) AS total_margin

FROM orders
WHERE created_at<'2013-01-04'
GROUP BY 1,2;


SELECT
YEAR(website_sessions.created_at) AS yr,
MONTH(website_sessions.created_at) AS mo,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id)  AS revenue_per_session,
COUNT(DISTINCT CASE WHEN primary_product_id=1 THEN order_id ELSE NULL END) AS product_one_orders,
COUNT(DISTINCT CASE WHEN primary_product_id=2 THEN order_id ELSE NULL END) AS product_two_orders

FROM website_sessions
LEFT JOIN orders
      ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at>'2012-04-01'
      AND website_sessions.created_at<'2013-04-05'
GROUP BY 1,2;

