select ad_date,campaign_id,
		sum(spend) as sum_spend,
		sum(impressions) as how_impres,
		sum(clicks) as how_clix,
		sum(value) as total_value,
		
		sum(spend)/sum(clicks) as CPC,
		sum(spend)*1000/sum(value)*100 as CPM,
		sum(clicks)*1000/sum(value)*100 as CTR,
		(sum(value)-sum(spend))/sum(spend)*100 as ROMI		
		
from facebook_ads_basic_daily
where spend>0 and impressions>0 and clicks>0 and value>0
group by ad_date, campaign_id 
order by ad_date desc;

select
	campaign_id,
	sum(spend) as MAXspend,
	(round(sum(value),1) - sum(spend)) / sum (spend)*100  as ROMI
from facebook_ads_basic_daily
group by
	 campaign_id
	 having sum (spend) > 500000
	 order by romi desc
	limit 100