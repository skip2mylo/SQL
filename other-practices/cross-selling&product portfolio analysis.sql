SELECT 
  orders.primary_product_id,
  COUNT(DISTINCT orders.order_id) AS orders,
  COUNT(DISTINCT CASE WHEN order_items.product_id =1 THEN orders.order_id ELSE NULL END) AS x_sell_prod1,
  COUNT(DISTINCT CASE WHEN order_items.product_id =2 THEN orders.order_id ELSE NULL END) AS x_sell_prod2,
  COUNT(DISTINCT CASE WHEN order_items.product_id =3 THEN orders.order_id ELSE NULL END) AS x_sell_prod3,
  COUNT(DISTINCT CASE WHEN order_items.product_id =1 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id) 
  AS x_sell_prod1_rt,
  COUNT(DISTINCT CASE WHEN order_items.product_id =2 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id) 
  AS x_sell_prod2_rt,
  COUNT(DISTINCT CASE WHEN order_items.product_id =3 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id) 
  AS x_sell_prod3_rt
FROM orders
    LEFT JOIN order_items
    ON order_items.order_id=orders.order_id
    AND order_items.is_primary_item=0
WHERE orders.order_id BETWEEN 10000 AND 11000
GROUP BY 1;

-- exercise 1

-- STEP1: Identify the relevant cart page views and their sessions
-- STEP2: See which of those cart sessions clicked through to the shipping page
-- STEP3: Find the orders associated with the cart sessions.Analyze products purchased,aov
-- STEP4: Aggregate and analyze a summary of our findings

CREATE TEMPORARY TABLE sessions_seeing_cart_page
SELECT
website_session_id AS cart_session_id,
website_pageview_id AS cart_pageview_id,
CASE 
   WHEN created_at <'2012-09-25'  THEN 'A.Pre_Cross_sell'
   WHEN created_at > '2012-09-25'  THEN 'B.Pre_Cross_sell'
   ELSE 'uh oh...check you logic'
   END AS time_period
FROM website_pageviews
WHERE pageview_url='/cart'
AND created_at <='2012-10-25'
AND created_at >='2012-08-25';

-- See which of those /cart sessions clicked through to the shipping page

CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT 
time_period,
cart_session_id,
MIN(website_pageviews.website_pageview_id) AS pv_id_after_cart
FROM sessions_seeing_cart_page
LEFT JOIN website_pageviews
     ON sessions_seeing_cart_page.cart_session_id=website_pageviews.website_session_id
     AND website_pageviews.website_pageview_id>sessions_seeing_cart_page.cart_pageview_id
GROUP BY 1,2
HAVING 
MIN(website_pageviews.website_pageview_id) IS NOT NULL;


CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
time_period,
cart_session_id,
order_id,
items_purchased,
price_usd
FROM sessions_seeing_cart_page
INNER JOIN orders 
      ON orders.website_session_id=sessions_seeing_cart_page.cart_session_id;

SELECT
    sessions_seeing_cart_page.time_period,
    sessions_seeing_cart_page.cart_session_id,
    CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS click_to_another_page,
    CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart_page
     LEFT JOIN cart_sessions_seeing_another_page
           ON cart_sessions_seeing_another_page.cart_session_id=sessions_seeing_cart_page.cart_session_id
	LEFT JOIN pre_post_sessions_orders
           ON pre_post_sessions_orders.cart_session_id = sessions_seeing_cart_page.cart_session_id
ORDER BY
cart_session_id;
    
SELECT 
   time_period,
   COUNT(DISTINCT cart_session_id) AS sessions,
   SUM(click_to_another_page) AS clickthroughs,
   SUM(click_to_another_page)/COUNT(DISTINCT cart_session_id) AS cart_ctr,
   SUM(placed_order) AS order_placed,
   SUM(items_purchased) AS products_purchased,
   SUM(items_purchased) /SUM(placed_order) AS products_per_order,
   SUM(price_usd)/SUM(placed_order) AS AOV,
   SUM(price_usd)/ COUNT(DISTINCT cart_session_id)  AS rev_per_cart_session
FROM (
SELECT
    sessions_seeing_cart_page.time_period,
    sessions_seeing_cart_page.cart_session_id,
    CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS click_to_another_page,
    CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart_page
     LEFT JOIN cart_sessions_seeing_another_page
           ON cart_sessions_seeing_another_page.cart_session_id=sessions_seeing_cart_page.cart_session_id
	LEFT JOIN pre_post_sessions_orders
           ON pre_post_sessions_orders.cart_session_id = sessions_seeing_cart_page.cart_session_id
ORDER BY
cart_session_id
) AS full_data

GROUP BY 1;


-- exercise 2

SELECT 
CASE
    WHEN website_sessions.created_at<'2013-12-12' THEN 'A.Pre_Birthday_Bear'
    WHEN website_sessions.created_at>='2013-12-12' THEN 'B.Post_Birthday_Bear'
    ELSE 'uh oh...check logic'
END AS time_period,
-- COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
-- COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id)
AS conv_rate,
SUM(orders.price_usd) AS total_revenue,
-- SUM(orders.items_purchased) AS total_products_sold,
SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS average_order_value,
SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) AS products_per_order,
SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session

FROM website_sessions
LEFT JOIN orders
     ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;

SELECT 
    order_items.order_id,
    order_items.order_item_id,
    order_items.price_usd AS price_paid_usd,
    order_items.created_at,
    order_item_refunds.order_item_refund_id,
    order_item_refunds.refund_amount_usd,
    order_item_refunds.created_at
FROM order_items
    LEFT JOIN order_item_refunds
         ON order_item_refunds.order_item_id=order_items.order_item_id
WHERE order_items.order_id IN(3489,32049,27061);


-- Refund rates

SELECT 
YEAR(order_items.created_at) AS yr,
MONTH(order_items.created_at) AS mo,
COUNT(DISTINCT CASE WHEN order_items.product_id=1 THEN order_items.order_item_id ELSE NULL END) AS p1_orders,
COUNT(DISTINCT CASE WHEN order_items.product_id=1 THEN order_item_refunds.order_item_id ELSE NULL END) AS p1_refunds,
COUNT(DISTINCT CASE WHEN order_items.product_id=1 THEN order_item_refunds.order_item_id ELSE NULL END)
/COUNT(DISTINCT CASE WHEN order_items.product_id=1 THEN order_items.order_item_id ELSE NULL END) AS p1_refund_rt,
COUNT(DISTINCT CASE WHEN order_items.product_id=2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,
COUNT(DISTINCT CASE WHEN order_items.product_id=2 THEN order_item_refunds.order_item_id ELSE NULL END) AS p2_refunds,
COUNT(DISTINCT CASE WHEN order_items.product_id=2 THEN order_item_refunds.order_item_id ELSE NULL END)
/COUNT(DISTINCT CASE WHEN order_items.product_id=2 THEN order_items.order_item_id ELSE NULL END) AS p2_refund_rt,
COUNT(DISTINCT CASE WHEN order_items.product_id=3 THEN order_items.order_item_id ELSE NULL END) AS p3_orders,
COUNT(DISTINCT CASE WHEN order_items.product_id=3 THEN order_item_refunds.order_item_id ELSE NULL END) AS p3_refunds,
COUNT(DISTINCT CASE WHEN order_items.product_id=3 THEN order_item_refunds.order_item_id ELSE NULL END)
/COUNT(DISTINCT CASE WHEN order_items.product_id=3 THEN order_items.order_item_id ELSE NULL END) AS p3_refund_rt,
COUNT(DISTINCT CASE WHEN order_items.product_id=4 THEN order_items.order_item_id ELSE NULL END) AS p4_orders,
COUNT(DISTINCT CASE WHEN order_items.product_id=4 THEN order_item_refunds.order_item_id ELSE NULL END) AS p4_refunds,
COUNT(DISTINCT CASE WHEN order_items.product_id=4 THEN order_item_refunds.order_item_id ELSE NULL END)
/COUNT(DISTINCT CASE WHEN order_items.product_id=4 THEN order_items.order_item_id ELSE NULL END) AS p4_refund_rt

FROM order_items
LEFT JOIN order_item_refunds
         ON order_item_refunds.order_item_id=order_items.order_item_id
WHERE order_items.created_at<'2014-10-15'
GROUP BY 1,2;
         



