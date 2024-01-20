	--MAIN task

with FaGo as(
	select fabd.ad_date, fc.campaign_name, spend, impressions, reach, clicks, leads, value, 'facebook' as add_source
	from facebook_ads_basic_daily fabd
		left join facebook_campaign fc on fabd.campaign_id=fc.campaign_id
		left join facebook_adset fa on fabd.adset_id=fa.adset_id
		union all
	select gabd.ad_date, gabd.campaign_name, spend,impressions, reach, clicks, leads, value, 'google' as ad
	from google_ads_basic_daily gabd)
	
select FaGo.ad_date, FaGo.campaign_name,
	sum(spend) as sum_spend,
	sum(impressions) as how_impres,
	sum(clicks) as how_clix,
	sum(value) as total_value
from FaGo
	group by FaGo.ad_date, FaGo.campaign_name
	having FaGo.campaign_name is not null
	order by 2,1;
	
	--BONUS task
	
with FaGo as(
	select fabd.ad_date, fc.campaign_name, spend, adset_name, value, 'facebook' as add_source
	from facebook_ads_basic_daily fabd
		left join facebook_campaign fc on fabd.campaign_id=fc.campaign_id
		left join facebook_adset fa on fabd.adset_id=fa.adset_id
	union all
	select gabd.ad_date, gabd.campaign_name, spend,adset_name, value, 'google' as ad
	from google_ads_basic_daily gabd)	

select FaGo.campaign_name, FaGo.adset_name,
	--sum(spend) as max_spend,
	round((sum(value)::numeric-sum(spend)::numeric)/sum(spend)*100,2)  as "ROMI"
	
from FaGo
	group by FaGo.campaign_name, FaGo.adset_name
	having sum(spend) > 500000
	order by "ROMI" desc
	limit 1;