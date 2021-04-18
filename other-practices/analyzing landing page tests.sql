-- step 0: find out when the new page/lander launched
-- step 1: finding the first website_pageview_id for relevant sessions
-- step 2: identifyting the landing page of each session
-- step 3: counting pageviews for each session, to identify "bounces"
-- step 4: summarizing total sessions and bounced sessions, by LP

-- finding the first instance of /lander-1 to set analysis timeframe
SELECT 
MIN(created_at) AS first_created_at,
MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE website_pageviews.pageview_url='/lander-1'
   AND created_at IS NOT NULL ;
   
-- first created at = '2012-06-19'
-- first pageview id= 23504

CREATE TEMPORARY TABLE first_test_pageviews
SELECT 
  website_pageviews. website_session_id,
  MIN(website_pageviews. website_pageview_id) AS min_pv_id
FROM website_pageviews
     INNER JOIN website_sessions
           ON website_sessions.website_session_id = website_pageviews. website_session_id
           AND website_sessions.created_at <'2012-07-28' -- prescribed by the assignment
           AND website_pageviews.website_pageview_id > 23504 -- the min_pageview_id we found 
           AND utm_source ='gsearch'
           AND utm_campaign='nonbrand'
GROUP BY website_session_id;

-- next, we'll bring in the landing page to the session, like last time, but restricting to home or lander-1 this time

CREATE TEMPORARY TABLE nonbrand_test_session_w_landing_page
SELECT
   first_test_pageviews.website_session_id,
   website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
   LEFT JOIN website_pageviews
        ON first_test_pageviews.min_pv_id= website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url IN('/home', '/lander-1') ;

-- then a table to have count of pageviews per session
  -- then limit it to just bounced_sessions
CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
SELECT 
nonbrand_test_session_w_landing_page.website_session_id,
nonbrand_test_session_w_landing_page.landing_page,
COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM nonbrand_test_session_w_landing_page
LEFT JOIN website_pageviews
     ON website_pageviews.website_session_id=nonbrand_test_session_w_landing_page.website_session_id
GROUP BY 
     nonbrand_test_session_w_landing_page.website_session_id,
	 session_w_ab_landing_page.landing_page
HAVING
  COUNT(website_pageviews.website_pageview_id) =1;

-- DO THIS FIRST TO SHOW, THEN COUNT THEM AFTER
SELECT 
nonbrand_test_session_w_landing_page.landing_page,
nonbrand_test_session_w_landing_page.website_session_id,
nonbrand_test_bounced_sessions.website_session_id AS bounced_website_session_id
FROM nonbrand_test_session_w_landing_page
LEFT JOIN nonbrand_test_bounced_sessions
     ON nonbrand_test_bounced_sessions.website_session_id=nonbrand_test_session_w_landing_page.website_session_id
ORDER BY 
     nonbrand_test_session_w_landing_page.website_session_id;

-- COUNT THEM
SELECT 
     nonbrand_test_session_w_landing_page.landing_page,
    COUNT(DISTINCT nonbrand_test_session_w_landing_page. website_session_id) AS total_sessions,
    COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) AS bounced_sessions,
	COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id)/COUNT(DISTINCT nonbrand_test_session_w_landing_page. website_session_id) AS bounce_rate
FROM nonbrand_test_session_w_landing_page
	LEFT JOIN nonbrand_test_bounced_sessions
         ON nonbrand_test_session_w_landing_page. website_session_id= nonbrand_test_bounced_sessions.website_session_id
GROUP BY 
     nonbrand_test_session_w_landing_page.landing_page;

	

  
