select * from lead_data_dump;

--checking which bmi column to use
select * from lead_data_dump where bmi2 is null;
select * from lead_data_dump where bmi is null;

--leads with same name different phone numbers (considered as different leads)
select full_name, count(distinct extracted_phone)
from lead_data_dump
group by full_name
order by full_name;

--total unique leads
SELECT COUNT(DISTINCT (full_name, extracted_phone)) AS distinct_count
FROM lead_data_dump; --distinct customers = 124

--distinct values in various columns
select distinct utm_campaign from lead_data_dump; --Allurion
select distinct lead_source from lead_data_dump; --App, Social, Referral
select distinct utm_source from lead_data_dump; 
select distinct utm_adset from lead_data_dump; --Allurion
select distinct utm_content from lead_data_dump; --Allurion

--checking columns containing allurion
select * from lead_data_dump where utm_campaign not like '%Allurion%' and utm_content like '%Allurion%';

select * from lead_data_dump where pre_existing_conditions like '%Allurion%';

select COUNT(DISTINCT (full_name, extracted_phone)) AS distinct_count
FROM lead_data_dump where utm_campaign like '%Allurion%';

select lead_source, COUNT(DISTINCT (full_name, extracted_phone)) AS distinct_count
from lead_data_dump
group by lead_source;

--Allurion (lead_type)
select COUNT(DISTINCT (full_name, extracted_phone)) AS distinct_count
from lead_data_dump
where utm_campaign like '%Allurion%' and bmi2 > 34;

--Subscription Leads (lead_type)
select COUNT(DISTINCT (full_name, extracted_phone)) AS distinct_count
from lead_data_dump
where (utm_campaign like '%Allurion%' and bmi2 < 34)
		or (utm_campaign not like '%Allurion%')

--Analysis on Subscription Leads ES
select * from owner_role_mapping;

with Subscription_Leads as (
	select ldd.*, orm.owner_role
	from lead_data_dump ldd left join owner_role_mapping orm
	on ldd.owner_name = orm.owner_name
	where (utm_campaign like '%Allurion%' and bmi2 < 34)
		or (utm_campaign not like '%Allurion%')
),

rank_activity as (
	select sl.*, dense_rank() over(partition by full_name, extracted_phone order by modified_time) as r
	from Subscription_Leads sl	
)



required_lead_owners as (
	select *
	from rank_activity ra1
	where (r = (select max(r) from rank_activity ra2 where (ra2.full_name = ra1.full_name) and (ra2.extracted_phone = ra1.extracted_phone)))
		or (r = (select min(r) from rank_activity ra2 where (ra2.full_name = ra1.full_name) and (ra2.extracted_phone = ra1.extracted_phone) and (ra2.lead_status = 'P3 - Pitched')))
	order by full_name, extracted_phone, id
)

select DISTINCT (full_name, extracted_phone)
from required_lead_owners
where owner_role = 'ES'; --41,75,79,114 (Nisha Kapoor, Reena Singh, Amit Rao, Sonal Bhatt)

--Analysis on Subscription Leads
with Subscription_Leads as (
	select *
	from lead_data_dump
	where (utm_campaign like '%Allurion%' and bmi2 < 34)
		or (utm_campaign not like '%Allurion%')
)

select DISTINCT (full_name, extracted_phone)
from Subscription_Leads; --junk or not elligible (41, 79, 114)


	
with Eligible_Subscription_Leads as (
	select *
	from lead_data_dump
	where ((utm_campaign like '%Allurion%' and bmi2 < 34)
		or (utm_campaign not like '%Allurion%')) and full_name not in ('Test 41', 'Test 79', 'Test 114', 'Test 75')
),

-- pitch_scheduled_but_not_completed as (
-- 	select full_name, lead_status from Eligible_Subscription_Leads
-- 	where lead_status in (
-- 		'P4- Pitch scheduled',
-- 		'P5 - Qualified ,pitched scheduled',
-- 		'P5 - Pitched, Visit Not Scheduled'
-- 	)
-- )


-- select DISTINCT (full_name, extracted_phone) from Eligible_Subscription_Leads

-- select Distinct (full_name, extracted_phone)
-- from Eligible_Subscription_Leads;

-- count elligible customers whose pitch was scheduled
-- select full_name, modified_time, lead_status from Eligible_Subscription_Leads
-- where lead_status in ('P3 - Pitched',
-- 'P2 - Payment Link Sent',
-- 'P4- Pitch scheduled',
-- 'P1 - Payment received',
-- 'C - Customer',
-- 'Future Prospect',
-- 'P5 - Qualified ,pitched scheduled',
-- 'P5 - Pitched, Visit Not Scheduled',
-- 'P2 - Enrollment',
-- 'P4 - Visited and Pitched (offline)',
-- 'P5 - Pitched, Visit Scheduled',
-- 'P3 - Free Doctor Consultation',
-- 'P2 - Payment Link Sent (Offline)',
-- 'P2 - Payment Received');

pitched_scheduled_customers as (
	select full_name, lead_status from Eligible_Subscription_Leads
	where lead_status in ('P3 - Pitched',
	'P2 - Payment Link Sent',
	'P4- Pitch scheduled',
	'P1 - Payment received',
	'C - Customer',
	'Future Prospect',
	'P5 - Qualified ,pitched scheduled',
	'P5 - Pitched, Visit Not Scheduled',
	'P2 - Enrollment',
	'P4 - Visited and Pitched (offline)',
	'P5 - Pitched, Visit Scheduled',
	'P3 - Free Doctor Consultation',
	'P2 - Payment Link Sent (Offline)',
	'P2 - Payment Received')
),

not_pitched_customers as (
	select full_name, lead_status from Eligible_Subscription_Leads
	where full_name not in (select distinct full_name from pitched_scheduled ,_customers)
)

select * from not_pitched_customers;

pitch completed
with Eligible_Subscription_Leads as (
	select *
	from lead_data_dump
	where ((utm_campaign like '%Allurion%' and bmi2 < 34)
		or (utm_campaign not like '%Allurion%')) and full_name not in ('Test 41', 'Test 79', 'Test 114', 'Test 75')
)

converted leads
select count(distinct full_name) from Eligible_Subscription_Leads
where lead_status in (
	'P1 - Payment received',
	'C - Customer',
	'P2 - Payment Received'
);

pitch_completed as (
	select full_name, created_time, modified_time, lead_status,
	row_number() over(partition by full_name order by modified_time) as r
	from Eligible_Subscription_Leads
	where lead_status in ('P3 - Pitched',
	'P2 - Payment Link Sent',
	'P1 - Payment received',
	'C - Customer',
	'Future Prospect',
	'P2 - Enrollment',
	'P4 - Visited and Pitched (offline)',
	'P5 - Pitched, Visit Scheduled',
	'P3 - Free Doctor Consultation',
	'P2 - Payment Link Sent (Offline)',
	'P2 - Payment Received')
	order by full_name, modified_time
),

-- select count(distinct full_name) from Eligible_Subscription_Leads
-- where lead_status = 'Prospect Dead - PD' and full_name in (select distinct full_name from pitch_completed);
pitch_scheduled_but_not_completed as (
	select full_name from pitched_scheduled_customers
	where full_name not in (select distinct full_name from pitch_completed)
)

select distinct full_name from pitch_scheduled_but_not_completed;

select distinct full_name from Eligible_Subscription_Leads where lead_status = 'Prospect Dead - PD'
and full_name in (select distinct full_name from pitch_scheduled_but_not_completed);

first_pitch_completed as (
	select full_name, created_time, modified_time, lead_status from pitch_completed
	where r = 1
	order by full_name
)

--pitch completed within 24 hours
select count(distinct full_name)
from first_pitch_completed 
where (EXTRACT(EPOCH FROM (modified_time - created_time)) / 3600) < 24;


--subscription ES funnel
with Subscription_Leads as (
	select ldd.*, orm.owner_role
	from lead_data_dump ldd left join owner_role_mapping orm
	on ldd.owner_name = orm.owner_name
	where (utm_campaign like '%Allurion%' and bmi2 < 34)
		or (utm_campaign not like '%Allurion%')
),



with Eligible_Subscription_Leads as (
	select ldd.*, orm.owner_role
	from lead_data_dump ldd left join owner_role_mapping orm
	on ldd.owner_name = orm.owner_name
	where ((utm_campaign like '%Allurion%' and bmi2 < 34)
		or (utm_campaign not like '%Allurion%')) and full_name not in ('Test 41', 'Test 79', 'Test 114', 'Test 75')
),

rank_activity as (
	select sl.*, dense_rank() over(partition by full_name, extracted_phone order by modified_time) as r
	from Eligible_Subscription_Leads sl	
),

required_lead_owners as (
	select *
	from rank_activity ra1
	where (r = (select max(r) from rank_activity ra2 where (ra2.full_name = ra1.full_name) and (ra2.extracted_phone = ra1.extracted_phone)))
		or (r = (select min(r) from rank_activity ra2 where (ra2.full_name = ra1.full_name) and (ra2.extracted_phone = ra1.extracted_phone) and (ra2.lead_status = 'P3 - Pitched')))
	order by full_name, extracted_phone, id
),


-- select owner_name, count(distinct (full_name, extracted_phone))
-- from required_lead_owners
-- where owner_role = 'ES'
-- group by owner_name;

Eligible_Subscription_Leads_ES as(
	select full_name, extracted_phone,lead_status,owner_name, created_time, modified_time
	from required_lead_owners
	where owner_role = 'ES'
),

-- select distinct full_name from Eligible_Subscription_Leads_ES;

-- select Dfull_name from Eligible_Subscription_Leads_ES;

pitch_completed as (
	select full_name, created_time, modified_time, lead_status
	-- row_number() over(partition by full_name order by modified_time) as r
	from Eligible_Subscription_Leads
	where lead_status in ('P3 - Pitched',
	'P2 - Payment Link Sent',
	'P1 - Payment received',
	'C - Customer',
	'Future Prospect',
	'P2 - Enrollment',
	'P4 - Visited and Pitched (offline)',
	'P5 - Pitched, Visit Scheduled',
	'P3 - Free Doctor Consultation',
	'P2 - Payment Link Sent (Offline)',
	'P2 - Payment Received')
	-- order by full_name, modified_time
),

pitched_scheduled_customers as (
	select full_name, extracted_phone,lead_status,owner_name, owner_role from Eligible_Subscription_Leads
	where lead_status in ('P3 - Pitched',
	'P2 - Payment Link Sent',
	'P4- Pitch scheduled',
	'P1 - Payment received',
	'C - Customer',
	'Future Prospect',
	'P5 - Qualified ,pitched scheduled',
	'P5 - Pitched, Visit Not Scheduled',
	'P2 - Enrollment',
	'P4 - Visited and Pitched (offline)',
	'P5 - Pitched, Visit Scheduled',
	'P3 - Free Doctor Consultation',
	'P2 - Payment Link Sent (Offline)',
	'P2 - Payment Received')
),

eligible_subscription_leads_ES_pitch_completed as (
	select * from pitch_completed
	where full_name in (select distinct full_name from Eligible_Subscription_Leads_ES)
)

-- select distinct (full_name) from eligible_subscription_leads_ES_pitch_completed;

-- select owner_name, count(distinct full_name) 
-- from eligible_subscription_leads_ES_pitch_scheduled where owner_role = 'ES'
-- group by owner_name;
-- select Distinct full_name from Eligible_Subscription_Leads_ES
-- 	where lead_status in ('P3 - Pitched',
-- 	'P2 - Payment Link Sent',
-- 	'P4- Pitch scheduled',
-- 	'P1 - Payment received',
-- 	'C - Customer',
-- 	'Future Prospect',
-- 	'P5 - Qualified ,pitched scheduled',
-- 	'P5 - Pitched, Visit Not Scheduled',
-- 	'P2 - Enrollment',
-- 	'P4 - Visited and Pitched (offline)',
-- 	'P5 - Pitched, Visit Scheduled',
-- 	'P3 - Free Doctor Consultation',
-- 	'P2 - Payment Link Sent (Offline)',
-- 	'P2 - Payment Received');
completed_time_stats as (
	select e.*, row_number() over(partition by full_name order by modified_time) as r 
	from Eligible_Subscription_Leads_ES e
		where lead_status in ('P3 - Pitched',
		'P2 - Payment Link Sent',
		'P1 - Payment received',
		'C - Customer',
		'Future Prospect',
		'P2 - Enrollment',
		'P4 - Visited and Pitched (offline)',
		'P5 - Pitched, Visit Scheduled',
		'P3 - Free Doctor Consultation',
		'P2 - Payment Link Sent (Offline)',
		'P2 - Payment Received')
),

first_pitch_done as (
	select * from completed_time_stats where r = 1
),

first_pitch_less_than_24 as (
	select fpd.*, (EXTRACT(EPOCH FROM (modified_time - created_time)) / 3600) as time_diff
	from first_pitch_done fpd
	where (EXTRACT(EPOCH FROM (modified_time - created_time)) / 3600) < 24
	order by fpd.full_name
)

select owner_name, count(distinct full_name) as distinct_count
from first_pitch_less_than_24
group by owner_name;
	
-- select owner_name,Count(Distinct full_name)from Eligible_Subscription_Leads_ES
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
-- group by owner_name;

select full_name, created_time, modified_time, lead_status,
	row_number() over(partition by full_name order by modified_time) as r
	from Eligible_Subscription_Leads
	where lead_status in ('P3 - Pitched',
	'P2 - Payment Link Sent',
	'P1 - Payment received',
	'C - Customer',
	'Future Prospect',
	'P2 - Enrollment',
	'P4 - Visited and Pitched (offline)',
	'P5 - Pitched, Visit Scheduled',
	'P3 - Free Doctor Consultation',
	'P2 - Payment Link Sent (Offline)',
	'P2 - Payment Received')