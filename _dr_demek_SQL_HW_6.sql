--MAIN task

CREATE OR REPLACE FUNCTION decode_url_part(p varchar) RETURNS varchar AS $$
SELECT convert_from(CAST(E'\\x' || string_agg(CASE WHEN length(r.m[1]) = 1 THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex') ELSE substring(r.m[1] from 2 for 2) END, '') AS bytea), 'UTF8')
FROM regexp_matches($1, '%[0-9a-f][0-9a-f]|.', 'gi') AS r(m);
$$ LANGUAGE SQL IMMUTABLE STRICT;

with FaGo as(
	select ad_date as d_te,
			url_parameters as url,
			fabd.campaign_id as camp_id,			
			coalesce (sum(spend),0) as s_spend,
			coalesce (sum(impressions),0) as s_impres,
			coalesce (sum(clicks),0) as s_clix,
			coalesce (sum(value),0) as s_value,
			coalesce (sum(reach),0) as s_reach,
			coalesce (sum(leads),0) as s_leads
			
	from facebook_ads_basic_daily fabd 
		left join facebook_campaign fc on fc.campaign_id = fabd.campaign_id
		left join facebook_adset fa on fabd.adset_id = fa.adset_id
	group by d_te, camp_id, url
	
	union all
	
	select ad_date as d_te,
			url_parameters as url,
			campaign_name as camp_nm,
			coalesce (sum(spend),0) as s_spend,
			coalesce (sum(impressions),0) as s_impres,
			coalesce (sum(clicks),0) as s_clix,
			coalesce (sum(value),0) as s_value,
			coalesce (sum(reach),0) as s_reach,
			coalesce (sum(leads),0) as s_leads
	from google_ads_basic_daily gabd 
	group by d_te, camp_nm, url
	),

	for_month as (
	select 	date(date_trunc('month',d_te)) as ad_month,
			decode_url_part(nullif(lower(substring(url, 'utm_campaign=([^&#$]+)')),'nan')) as utm_camp,
			sum(s_spend) as s_spend,
			sum(s_impres) as s_impres,
			sum(s_clix) as s_clix,
			sum(s_value) as s_value,
			
			case when sum (s_impres)>0 then 
									round(sum(s_clix)::numeric*1000/sum(s_impres)*100,2) else 0 end as ctr,
			case when sum (s_clix)>0 then 
									round(sum(s_spend)::numeric/sum(s_clix),2) else 0 end as cpc,
			case when sum (s_impres)>0 then 
									round(sum(s_spend)::numeric*1000/sum(s_impres)*100,2) else 0 end as cpm,
			case when sum (s_spend)>0 then 
									round((sum(s_value)::numeric-sum(s_spend))/sum(s_spend)*100,2) else 0 end as romi
	from FaGo
	group by 1, 2
	order by 1
)
			
select  for_month.ad_month,
		for_month.utm_camp,
		for_month.s_spend,
		for_month.s_impres,
		for_month.s_clix,
		for_month.s_value,
		for_month.ctr,
		for_month.cpc,
		for_month.cpm,
		for_month.romi,
		case when for_1month.cpm >0 then round((for_month.cpm-for_1month.cpm)/for_1month.cpm,2)*100 end as cpm_1month,
		case when for_1month.ctr >0 then round((for_month.ctr-for_1month.ctr)/for_1month.ctr,2)*100 end as ctr_1month,
		case when for_1month.romi >0 then round((for_month.romi-for_1month.romi)/for_1month.romi,2)*100 end as romi_1month
		
from for_month
left join for_month as for_1month
on for_month.ad_month=for_1month.ad_month+interval '1 month'
order by 1
;
