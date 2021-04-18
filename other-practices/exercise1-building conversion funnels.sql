-- STEP 1: select all pageviews for relevant sessions
-- STEP 2: identify each relevant pageview as the specific funnel step
-- STEP 3: create the session-level conversion funnel view
-- STEP 4: aggregate the data to assess funnel performance

SELECT
pageview_url,
COUNT(DISTINCT website_session_id) AS type
from website_pageviews
GROUP BY pageview_url;

SELECT 
  website_sessions.website_session_id,
  website_pageviews.pageview_url,
  website_pageviews.created_at AS pageview_created_at,
  CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS products_page,
  CASE WHEN pageview_url='/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
  CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
  CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
  CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_page,
  CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
    LEFT JOIN website_pageviews
      ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.utm_source='gsearch'
  AND website_sessions.utm_campaign='nonbrand'
  AND website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05' -- random timeframe for demo
ORDER BY 
website_sessions.website_session_id,
website_pageviews.created_at;


CREATE TEMPORARY TABLE  session_level_made_it_flags
SELECT 
website_session_id,
MAX(products_page) AS product_made_it,
MAX(mrfuzzy_page) AS mrfuzzy_made_it,
MAX(cart_page) AS cart_made_it,
MAX(shipping_page) AS shipping_made_it,
MAX(billing_page) AS billing_made_it,
MAX(thankyou_page) AS thankyou_made_it

FROM(
SELECT 
  website_sessions.website_session_id,
  website_pageviews.pageview_url,
  website_pageviews.created_at AS pageview_created_at,
  CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS products_page,
  CASE WHEN pageview_url='/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
  CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
  CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
  CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_page,
  CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
    LEFT JOIN website_pageviews
      ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.utm_source='gsearch'
  AND website_sessions.utm_campaign='nonbrand'
  AND website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05' -- random timeframe for demo
ORDER BY 
website_sessions.website_session_id,
website_pageviews.created_at
) AS pageview_level

GROUP BY website_session_id;

SELECT * FROM session_level_made_it_flags;

-- then this would produce the final output
SELECT 
  COUNT(DISTINCT website_session_id) AS sessions,
  COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END) AS to_products,
  COUNT(DISTINCT CASE WHEN mrfuzzy_made_it =1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
  COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) AS to_cart,
  COUNT(DISTINCT CASE WHEN shipping_made_it =1 THEN website_session_id ELSE NULL END) AS to_shipping,
  COUNT(DISTINCT CASE WHEN billing_made_it =1 THEN website_session_id ELSE NULL END) AS to_billing,
  COUNT(DISTINCT CASE WHEN thankyou_made_it =1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it_flags;

-- -- translate those counts to click rates for final output part 2(click rates)

SELECT 
  COUNT(DISTINCT website_session_id) AS sessions,
  COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END)
  /COUNT(DISTINCT website_session_id)
  AS lander_clickthrough_rate,
  COUNT(DISTINCT CASE WHEN mrfuzzy_made_it =1 THEN website_session_id ELSE NULL END) 
  /COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END)
  AS products_clickthrough_rate,
  COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END)
  /COUNT(DISTINCT CASE WHEN mrfuzzy_made_it =1 THEN website_session_id ELSE NULL END) 
  AS mr_fuzzy_clickthrough_rate,
  COUNT(DISTINCT CASE WHEN shipping_made_it =1 THEN website_session_id ELSE NULL END)
  /COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END)
  AS cart_clickthrough_shipping,
  COUNT(DISTINCT CASE WHEN billing_made_it =1 THEN website_session_id ELSE NULL END) 
  /COUNT(DISTINCT CASE WHEN shipping_made_it =1 THEN website_session_id ELSE NULL END)
  AS shipping_clickthrough_billing,
  COUNT(DISTINCT CASE WHEN thankyou_made_it =1 THEN website_session_id ELSE NULL END) 
  /COUNT(DISTINCT CASE WHEN billing_made_it =1 THEN website_session_id ELSE NULL END)
  AS billing_clickthrough_thankyou
  
FROM session_level_made_it_flags;


