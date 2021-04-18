/* we can analyze our pageviews data and GROUP BY url to see which pages are viewed most. 
To find top entry pages, we will limit to just to just the first page a user sees during a given session, using a temporary table */

USE mavenfuzzyfactory;

CREATE TEMPORARY TABLE first_pv_session
SELECT 
  website_session_id,
  MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
WHERE created_at <'2012-06-14'
GROUP BY website_session_id;

CREATE TEMPORARY TABLE session_w_home_landing_page
SELECT
   first_pv_session.website_session_id,
   website_pageviews.pageview_url AS landing_page
FROM first_pv_session
   LEFT JOIN website_pageviews
        ON first_pv_session.min_pv_id= website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url='/home' ;

CREATE TEMPORARY TABLE bounced_sessions_home_only
SELECT 
session_w_home_landing_page.website_session_id,
session_w_home_landing_page.landing_page,
COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM session_w_home_landing_page
LEFT JOIN website_pageviews
     ON website_pageviews.website_session_id=session_w_home_landing_page.website_session_id
GROUP BY 
     session_w_home_landing_page.website_session_id,
	 session_w_home_landing_page.landing_page
HAVING
	COUNT(website_pageviews.website_pageview_id) =1;

SELECT * FROM bounced_sessions_home_only;

SELECT 
   session_w_home_landing_page.landing_page,
   session_w_home_landing_page.website_session_id,
   bounced_sessions_home_only.website_session_id AS bounced_website_session_id
FROM session_w_home_landing_page
LEFT JOIN bounced_sessions_home_only
     ON session_w_home_landing_page.website_session_id=bounced_sessions_home_only.website_session_id
ORDER BY 
      session_w_home_landing_page.website_session_id;
      
SELECT 
   session_w_home_landing_page.landing_page,
   COUNT(DISTINCT session_w_home_landing_page.website_session_id) AS sessions,
   COUNT(DISTINCT bounced_sessions_home_only.website_session_id) AS bounced_sessions,
   COUNT(DISTINCT bounced_sessions_home_only.website_session_id)/COUNT(DISTINCT session_w_home_landing_page.website_session_id) AS bounced_rate
   
FROM session_w_home_landing_page
LEFT JOIN bounced_sessions_home_only
     ON session_w_home_landing_page.website_session_id=bounced_sessions_home_only.website_session_id
GROUP BY
      session_w_home_landing_page.landing_page;



/*SELECT 
    website_pageviews.pageview_url AS landing_page, -- aka "entry page"
    COUNT(DISTINCT first_pageview. website_session_id) AS sessions_hitting_this_lander
FROM first_pageview
    LEFT JOIN website_pageviews
          ON first_pageview.min_pv_id = website_pageviews. website_pageview_id
GROUP BY
     website_pageviews.pageview_url;*/

 /*SELECT 
pageview_url,
COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews
-- LEFT JOIN website_sessions
	 -- ON website_pageviews. website_session_id=website_sessions.website_session_id
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY pvs DESC*/
