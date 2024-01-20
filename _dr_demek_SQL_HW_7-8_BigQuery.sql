--task 1
SELECT  
        TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
        user_pseudo_id,        
        (SELECT value.int_value FROM UNNEST (event_params) WHERE key = 'ga_session_id') AS session_id,
        event_name,
        geo.country AS contry,
        device.category AS device_category,
        traffic_source.source AS source,
        traffic_source.medium AS medium,
        traffic_source.name AS campaign
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` 
WHERE event_name IN ('session_start', 'view_item', 'add_to_cart', 'begin_checkout', 'add_shipping_info', 'add_payment_info', 'purchase')
AND (_TABLE_SUFFIX BETWEEN '20210101' AND '20210131')
ORDER BY 1,2
LIMIT 1000;

--task 2
WITH count_data AS(
    SELECT  
        DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date,
        traffic_source.source,
        traffic_source.medium,
        traffic_source.name AS campaign,
        COUNT(DISTINCT CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST (event_params) WHERE key = 'ga_session_id') AS STRING))) AS user_sessions_count,
        COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST (event_params) WHERE key = 'ga_session_id') AS STRING))  END) AS session_start,
        COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST (event_params) WHERE key = 'ga_session_id') AS STRING))  END) AS visit_to_cart,
        COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST (event_params) WHERE key = 'ga_session_id') AS STRING))  END) AS visit_to_checkout,
      COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST (event_params) WHERE key = 'ga_session_id') AS STRING))  END) AS visit_to_purchase
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE event_name IN ('session_start','add_to_cart', 'begin_checkout','purchase')
    GROUP BY 1,2,3,4
    ORDER BY 7 DESC
)
SELECT event_date,
       source,
       medium,
       campaign,
       user_sessions_count,
       ROUND((visit_to_cart/session_start),2)*100 AS visit_to_cart,
       ROUND((visit_to_checkout/session_start),2)*100 AS visit_to_checkout,
       ROUND((visit_to_purchase/session_start),2)*100 AS Visit_to_purchase
FROM count_data
ORDER BY 6 DESC
LIMIT 1000
;

--task 3
