select count(*) from lead_data_dump;

--removing rows in between and keeping only extreme rows where lead_status is same for 
--a countinuous series of more than two rows 
--as the min and max for each lead_status is required in lead_owner calculations and 
--other analysis, the results will be same if we use this optimized dataset
WITH ranked_leads AS (
	SELECT *,
	LAG(lead_status) OVER (PARTITION BY extracted_phone ORDER BY modified_time) AS prev_lead_status,
	LEAD(lead_status) OVER (PARTITION BY extracted_phone ORDER BY modified_time) AS next_lead_status,
	ROW_NUMBER() OVER (PARTITION BY extracted_phone, lead_status ORDER BY modified_time ASC) AS rn_min,
	ROW_NUMBER() OVER (PARTITION BY extracted_phone, lead_status ORDER BY modified_time DESC) AS rn_max
	FROM lead_data_dump
    WHERE created_time >= NOW() - INTERVAL '3 months'

)

DELETE FROM lead_data_dump
WHERE id NOT IN (
		SELECT id
		FROM ranked_leads
		WHERE (lead_status != prev_lead_status OR prev_lead_status IS NULL)
		OR (lead_status != next_lead_status OR next_lead_status IS NULL)
		OR rn_min = 1
		OR rn_max = 1
);


-- with Eligible_Subscription_Leads as (
-- 	select ldd.*, orm.owner_role
-- 	from lead_data_dump ldd left join owner_role_mapping orm
-- 	on ldd.owner_name = orm.owner_name
-- 	where ((utm_campaign like '%Allurion%' and bmi2 < 34)
-- 		or (utm_campaign not like '%Allurion%')) and full_name not in ('Test 41', 'Test 79', 'Test 114', 'Test 75')
-- ),

-- rank_activity as (
-- 	select sl.*, dense_rank() over(partition by full_name, extracted_phone order by modified_time) as r
-- 	from Eligible_Subscription_Leads sl	
-- ),

-- required_lead_owners as (
-- 	select *
-- 	from rank_activity ra1
-- 	where (r = (select max(r) from rank_activity ra2 where (ra2.full_name = ra1.full_name) and (ra2.extracted_phone = ra1.extracted_phone)))
-- 		or (r = (select min(r) from rank_activity ra2 where (ra2.full_name = ra1.full_name) and (ra2.extracted_phone = ra1.extracted_phone) and (ra2.lead_status = 'P3 - Pitched')))
-- 	order by full_name, extracted_phone, id
-- ),

-- Eligible_Subscription_Leads_ES as(
-- 	select full_name, extracted_phone,lead_status,owner_name, created_time, modified_time
-- 	from required_lead_owners
-- 	where owner_role = 'ES'
-- ),

-- completed_time_stats as (
-- 	select e.*, row_number() over(partition by full_name order by modified_time) as r 
-- 	from Eligible_Subscription_Leads_ES e
-- 		where lead_status in ('P3 - Pitched',
-- 		'P2 - Payment Link Sent',
-- 		'P1 - Payment received',
-- 		'C - Customer',
-- 		'Future Prospect',
-- 		'P2 - Enrollment',
-- 		'P4 - Visited and Pitched (offline)',
-- 		'P5 - Pitched, Visit Scheduled',
-- 		'P3 - Free Doctor Consultation',
-- 		'P2 - Payment Link Sent (Offline)',
-- 		'P2 - Payment Received')
-- ),

-- first_pitch_done as (
-- 	select * from completed_time_stats where r = 1
-- ),

-- first_pitch_less_than_24 as (
-- 	select fpd.*, (EXTRACT(EPOCH FROM (modified_time - created_time)) / 3600) as time_diff
-- 	from first_pitch_done fpd
-- 	where (EXTRACT(EPOCH FROM (modified_time - created_time)) / 3600) < 24
-- 	order by fpd.full_name
-- )

-- select owner_name, count(distinct full_name) as distinct_count
-- from first_pitch_less_than_24
-- group by owner_name;
	
-- -- select owner_name,Count(Distinct full_name)from Eligible_Subscription_Leads_ES
-- -- 	where lead_status in ('P3 - Pitched',
-- -- 	'P2 - Payment Link Sent',
-- -- 	'P1 - Payment received',
-- -- 	'C - Customer',
-- -- 	'Future Prospect',
-- -- 	'P2 - Enrollment',
-- -- 	'P4 - Visited and Pitched (offline)',
-- -- 	'P5 - Pitched, Visit Scheduled',
-- -- 	'P3 - Free Doctor Consultation',
-- -- 	'P2 - Payment Link Sent (Offline)',
-- -- 	'P2 - Payment Received')
-- -- group by owner_name;

-- select full_name, created_time, modified_time, lead_status,
-- 	row_number() over(partition by full_name order by modified_time) as r
-- 	from Eligible_Subscription_Leads
-- 	where lead_status in ('P3 - Pitched',
-- 	'P2 - Payment Link Sent',
-- 	'P1 - Payment received',
-- 	'C - Customer',
-- 	'Future Prospect',
-- 	'P2 - Enrollment',
-- 	'P4 - Visited and Pitched (offline)',
-- 	'P5 - Pitched, Visit Scheduled',
-- 	'P3 - Free Doctor Consultation',
-- 	'P2 - Payment Link Sent (Offline)',
-- 	'P2 - Payment Received')

select distinct utm_source from lead_data_dump;

select count(distinct(full_name, extracted_phone)) from lead_data_dump;

select gender, count(distinct(full_name, extracted_phone)) from lead_data_dump
where full_name not in ('Test 41','Test 75','Test 79','Test 114')
group by gender;

SELECT 
    CASE
        WHEN age < 18 THEN 'Under 18'
        WHEN age >= 18 AND age <= 30 THEN '18-30'
        WHEN age > 30 AND age <= 50 THEN '31-50'
        ELSE 'Above 50'
    END AS age_group,
    COUNT(distinct (full_name,extracted_phone)) AS total_count
FROM lead_data_dump
GROUP BY age_group
ORDER BY age_group;

select full_name, extracted_phone, count(distinct age)
from lead_data_dump
group by full_name, extracted_phone;


WITH ranked_ages AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY full_name, extracted_phone ORDER BY modified_time DESC) AS rn
    FROM lead_data_dump
),

updated_age as (
	SELECT *
	FROM ranked_ages
	WHERE rn = 1
)

SELECT 
    CASE
		WHEN age is null THEN 'Unknown'
        WHEN age < 18 THEN 'Under 18'
        WHEN age >= 18 AND age <= 30 THEN '18-30'
        WHEN age > 30 AND age <= 50 THEN '31-50'
        ELSE 'Above 50'
    END AS age_group,
    COUNT(distinct (full_name,extracted_phone)) AS total_count
FROM updated_age
where full_name not in ('Test 41','Test 75','Test 79','Test 114')
GROUP BY age_group
ORDER BY age_group;