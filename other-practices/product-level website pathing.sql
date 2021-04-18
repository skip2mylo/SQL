SELECT DISTINCT
    website_pageviews.pageview_url,
    COUNT(DISTINCT website_pageviews.website_session_id) AS seesion,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_pageviews.website_session_id) AS viewed_product_to_order_rate

FROM website_pageviews
     LEFT JOIN orders
           ON orders.website_session_id = website_pageviews. website_session_id
WHERE website_pageviews.created_at BETWEEN '2013-02-01' AND '2013-03-01'
      AND website_pageviews.pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear')
GROUP BY 1;

-- Exercise 1

-- STEP1: find the relevant/products pageviews with website_session_id
-- STEP2: find the next pageview id that occurs AFTER the product pageview
-- STEP3: find the pageview_url associated with any applicable next pageview id
-- STEP4: summarize the data and analy the pre bos post series

-- STEP 1: find the relevant/products pageviews with website_session_id
CREATE TEMPORARY TABLE products_pageviews_tempo
SELECT
website_pageview_id,
website_session_id,
CASE 
   WHEN created_at<'2013-01-06' THEN 'A.Pre_Product_1'
   WHEN created_at>='2013-01-06' THEN 'B.Pre_Product_1'
   ELSE 'uh oh...check you logic'
   END AS time_period
FROM website_pageviews
WHERE created_at >'2012-10-06'
     AND created_at<'2013-04-06'
     AND pageview_url='/products';

-- STEP2: find the next pageview id that occurs AFTER the product pageview
CREATE TEMPORARY TABLE sessions_w_next_pageview_id_demo
SELECT 
products_pageviews_tempo.time_period,
products_pageviews_tempo.website_session_id,
MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id
FROM products_pageviews_tempo
LEFT JOIN website_pageviews
      ON website_pageviews.website_session_id=products_pageviews_tempo.website_session_id
      AND website_pageviews.website_pageview_id>products_pageviews_tempo.website_pageview_id
GROUP BY 1,2;

-- STEP3: find the pageview_url associated with any applicable next pageview id
-- CREATE TEMPORARY TABLE sessions_w_next_pageview_url
SELECT 
sessions_w_next_pageview_id_demo.time_period,
sessions_w_next_pageview_id_demo.website_session_id,
website_pageviews.pageview_url AS next_page_view_url
FROM sessions_w_next_pageview_id_demo
LEFT JOIN website_pageviews
     ON website_pageviews.website_pageview_id= sessions_w_next_pageview_id_demo.min_next_pageview_id;
     
-- STEP4: summarize the data and analy the pre bos post series

SELECT
time_period,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT CASE WHEN next_page_view_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
COUNT(DISTINCT CASE WHEN next_page_view_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)
AS pct_w_next_pg,
COUNT(DISTINCT CASE WHEN next_page_view_url='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
COUNT(DISTINCT CASE WHEN next_page_view_url='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)
AS pct_to_mrfuzzy,
COUNT(DISTINCT CASE WHEN next_page_view_url='/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
COUNT(DISTINCT CASE WHEN next_page_view_url='/the-forever-love-bear' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)
AS pct_to_lovebear
FROM sessions_w_next_pageview_url
GROUP BY 1;

-- Building Product-level Conversion funnels
-- STEP1: select all pageviews for relevant product urls
-- STEP2: figure out whihc pageview urls to look for
-- STEP3: pull all pageviews and identify the funnel steps
-- STEP4: create the session-level conversion funnel view
-- STEP5: aggregate the data the assess funnel performance

CREATE TEMPORARY TABLE session_seeing_product_pages_demo
SELECT 
   website_session_id,
   website_pageview_id,
   pageview_url AS product_page_seen

FROM website_pageviews
WHERE created_at<'2013-04-10'
     AND created_at>'2013-01-06'
     AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear');
     
-- finding the right pageview_urls to build the funnels
SELECT DISTINCT 
    website_pageviews.pageview_url
FROM session_seeing_product_pages_demo
     LEFT JOIN website_pageviews
     ON website_pageviews.website_session_id=session_seeing_product_pages_demo.website_session_id
	 AND website_pageviews. website_pageview_id>session_seeing_product_pages_demo.website_pageview_id;

SELECT 
session_seeing_product_pages_demo.website_session_id,
session_seeing_product_pages_demo.product_page_seen,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing-2' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM session_seeing_product_pages_demo
     LEFT JOIN website_pageviews
          ON session_seeing_product_pages_demo.website_session_id=website_pageviews.website_session_id
          AND session_seeing_product_pages_demo.website_pageview_id<website_pageviews.website_pageview_id
ORDER BY
     session_seeing_product_pages_demo.website_session_id,
     website_pageviews.created_at ;
   
     
CREATE TEMPORARY TABLE session_product_level_made_it_flags_demo
SELECT 
   website_session_id,
   CASE
   WHEN product_page_seen ='/the-forever-love-bear' THEN 'lovebear'
   WHEN product_page_seen ='/the-original-mr-fuzzy' THEN 'mrfuzzy'
   ELSE 'NULL'
   END AS product_seen,
   MAX(cart_page) AS cart_made_it,
   MAX(shipping_page) AS shipping_made_it,
   MAX(billing_page) AS billing_made_it,
   MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT 
session_seeing_product_pages_demo.website_session_id,
session_seeing_product_pages_demo.product_page_seen,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing-2' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM session_seeing_product_pages_demo
     LEFT JOIN website_pageviews
          ON session_seeing_product_pages_demo.website_session_id=website_pageviews.website_session_id
          AND session_seeing_product_pages_demo.website_pageview_id<website_pageviews.website_pageview_id
ORDER BY
     session_seeing_product_pages_demo.website_session_id,
     website_pageviews.created_at
) AS pageview_level
GROUP BY website_session_id;

-- final output part 1
SELECT
   product_seen,
   COUNT(DISTINCT website_session_id) AS sessions,
   COUNT(DISTINCT CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) AS to_cart,
   COUNT(DISTINCT CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) AS to_shipping,
   COUNT(DISTINCT CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) AS to_billing,
   COUNT(DISTINCT CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flags_demo
GROUP BY product_seen;


SELECT 
product_seen,
  COUNT(DISTINCT CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END)/
  COUNT(DISTINCT website_session_id) AS product_page_click_rt,
  COUNT(DISTINCT CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END)/
  COUNT(DISTINCT CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
  COUNT(DISTINCT CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) 
  /COUNT(DISTINCT CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
  COUNT(DISTINCT CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END)/
  COUNT(DISTINCT CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END)  AS billing_click_rt
FROM session_product_level_made_it_flags_demo
GROUP BY product_seen;












