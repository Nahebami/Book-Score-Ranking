-- <t>reporting_layer.book_score_rank_data</t>

INSERT INTO reporting_layer.book_score_rank_data (
book_id,
Book_Title,
Subject_name,
topic_name,
language_name,
publisher_name,
publisher_imprint,
Author,
norm_DTC_Revenue,
norm_enrollment,
norm_bay_read_mins,
norm_clicks,
publication_date,
Newness,
Overall_rank,
athena_timestamp
)

WITH  active_books as 
(
select
id as Book_ID,
isbn13_idvalue as ISBN,
coalesce(case when hardback_isbn = '' then null else hardback_isbn end, case when softback_isbn = '' then null else softback_isbn end) OTHER_ISBN,
title_text as Book_Title,
publisher_name,
publisher_imprint,
publication_date,
date_activated,
date_added,
case when perlego_subject_name = '' then null else perlego_subject_name end as Subject_name,
coalesce(case when perlego_topic_name1 = '' then null else perlego_topic_name1 end,
case when perlego_topic_name2 = '' then null else perlego_topic_name2 end,
case when perlego_topic_name3 = '' then null else perlego_topic_name3 end,
case when perlego_topic_name4 = '' then null else perlego_topic_name4 end) as topic_name,
coalesce(case when contributor1_person_name = '' then null else contributor1_person_name end,
case when contributor2_person_name = '' then null else contributor2_person_name end,
case when contributor3_person_name = '' then null else contributor3_person_name end) as Author,
language_name
from prod_gold_bucket_database.book_meta
where is_available = 1
),

--------- D2C Revenue 
dtc_revenue as 
(

with revenue as 
(
select
a.referrer_book, count(a.user_id) users,sum(b.total_paid_gbp) DTC_Revenue
from
(
select user_id, referrer_book
from analytics_reporting .user_registrations
where date_format(registration_time ,'%Y%m%d') >= date_format(date_add('month',-12,date_add('day',0,date_trunc('month',current_date))),'%Y%m%d')
and payment_channel_crude = 'direct'
and converted_subscribed = 'Y'
and referrer_book is not null
) a
left join 
(
select 
user_id, sum(coalesce(total_paid_gbp,0)) total_paid_gbp
from analytics_reporting.subscriptions
group by 1
)  b on (a.user_id = b.user_id)
where b.total_paid_gbp >0
group by 1 )


select 
b.*,
--ROUND((1.0*DTC_Revenue - min_DTC_Revenue) / (max_DTC_Revenue - min_DTC_Revenue) * 1000, 0) AS norm_DTC_Revenue,
CASE WHEN ROUND((1.0*DTC_Revenue - min_DTC_Revenue) / (max_DTC_Revenue - min_DTC_Revenue) * 1000, -1) = 0 THEN 1.0 ELSE 
ROUND((1.0*DTC_Revenue - min_DTC_Revenue) / (max_DTC_Revenue - min_DTC_Revenue) * 1000, -1) END norm_DTC_Revenue
from (
select a.*, 
MIN(DTC_Revenue) OVER (PARTITION BY 1) min_DTC_Revenue,
MAX(DTC_Revenue) OVER (PARTITION BY 1) max_DTC_Revenue
from revenue a
) b
),



--------- Academic Mandate
academic_mandate as 
(

with alma_libre as 
(
 ------ Enrolment numbers for alma libre requires the below logic as the enrolment number is captured for a degree & uni which is then duplucated for any book within the degree
select 
perlego_bookid as book_id, sum(degree_new_enrollments) enrollment
from ( select 
perlego_bookid, isbn, degree_name, uni_code, coalesce(cast(degree_new_enrollments as double)) degree_new_enrollments , count(1) cnt
from analytics_reporting.alma_libre_matched_data
where available_status = 'Yes'
group by 1,2,3,4,5
) group by 1
),

bmg  as (
select
perlego_bookid as book_id, sum(enrollments_adjusted) enrollment 
from analytics_reporting.bmg_matched_data
where available_status = 'Yes'
group by 1
),

external_titles as 
(
select book_id, enrollment
from (
select book_id , sum(enrollment) enrollment
from (
select * from bmg
union all 
select * from alma_libre
) group by 1 ) where enrollment > 0
)

select 
b.*,
--ROUND((1.0*enrollment - min_enrollment) / (max_enrollment - min_enrollment) * 1000, 0) AS norm_enrollment,
CASE WHEN ROUND((1.0*enrollment - min_enrollment) / (max_enrollment - min_enrollment) * 1000, -1) = 0 THEN 1.0 ELSE 
ROUND((1.0*enrollment - min_enrollment) / (max_enrollment - min_enrollment) * 1000, -1) END norm_enrollment
from (
select a.*, 
MIN(enrollment) OVER (PARTITION BY 1) min_enrollment,
MAX(enrollment) OVER (PARTITION BY 1) max_enrollment
from external_titles a
) b

),

--------- Readership
Readership as 
(

with reading_eng as 
(
select
book_id, users, total_reading_mins, (total_reading_mins/users) avg_read_mins
from (
 select book_id, count(distinct user_id) users , sum(reading_duration_minutes) total_reading_mins
from analytics_reporting.reading_activity_daily
where date_format(reading_date ,'%Y%m%d') >= date_format(date_add('month',-6,date_add('day',0,date_trunc('month',current_date))),'%Y%m%d')
group by 1 )
),

average as 
(
select avg(users) all_user,
 avg(avg_read_mins) all_avg_read_mins
from (
select
book_id, users, reading_mins, (reading_mins/users) avg_read_mins
from (
 select book_id, count(distinct user_id) users , sum(reading_duration_minutes) reading_mins
from analytics_reporting.reading_activity_daily
where date_format(reading_date ,'%Y%m%d') >= date_format(date_add('month',-6,date_add('day',0,date_trunc('month',current_date))),'%Y%m%d')
group by 1 ) )
),

summary as 
(
select 
a.*, 
((all_user*all_avg_read_mins) +  (total_reading_mins)) / (all_user+users) bay_read_mins
from reading_eng a
cross join average b
)

select 
b.*,
--ROUND((1.0*bay_read_mins - min_bay_read_mins) / (max_bay_read_mins - min_bay_read_mins) * 1000, 0) AS norm_bay_read_mins,
CASE WHEN ROUND((1.0*bay_read_mins - min_bay_read_mins) / (max_bay_read_mins - min_bay_read_mins) * 1000, -1) = 0 THEN 1.0 ELSE 
ROUND((1.0*bay_read_mins - min_bay_read_mins) / (max_bay_read_mins - min_bay_read_mins) * 1000, -1) END norm_bay_read_mins
from (
select a.*, 
MIN(bay_read_mins) OVER (PARTITION BY 1) min_bay_read_mins,
MAX(bay_read_mins) OVER (PARTITION BY 1) max_bay_read_mins
from summary a ) b
),


--------- Interest
Interest as 
(

with google_clicks as 
(
with max_date as 
(
select max(dates) max_dates
from perlego_reporting_layer.prod___fct__gads_landing_pages -- frequently updated table added temp (reporting_layer.dev_ma___fct__gads_landing_pages)
)

select 
--min(dates) min_dates, max(dates) max_dates
cast(book_id as integer) book_id, sum(cast(impressions as double)) impressions, sum(cast(clicks as double)) clicks 
from perlego_reporting_layer.prod___fct__gads_landing_pages cross join max_date
where date_format(dates ,'%Y%m%d') >= date_format(date_add('month',-3,date_add('day',0,date_trunc('month',max_dates))),'%Y%m%d')
and cast(clicks as double) > 0 
 and book_id is not null 
 group by 1
)

select 
b.*,
CASE WHEN ROUND((1.0*clicks - min_clicks) / (max_clicks - min_clicks) * 1000, -1) = 0 THEN 1.0 ELSE 
ROUND((1.0*clicks - min_clicks) / (max_clicks - min_clicks) * 1000, -1) END norm_clicks
from (
select a.*, 
MIN(clicks) OVER (PARTITION BY 1) min_clicks,
MAX(clicks) OVER (PARTITION BY 1) max_clicks
from google_clicks a where clicks > 0 ) b
),



--------- Newness (Book Publication Date)
Newness as 
(
select 
Book_ID, publication_date, publication_date_clean, date_activated, date_added, Book_Title,
rank() over(order by publication_date_clean desc) norm_publication_dt
from (
select
Book_ID,publication_date, 
case 
when substring(replace(publication_date,'-',''),1,8) = '' then '0' 
when lower(substring(replace(publication_date,'-',''),1,8)) in ('none','na') then '0' 
when substring(replace(publication_date,'-',''),1,8) is null then '0'
else substring(replace(publication_date,'-',''),1,8) end publication_date_clean,
date_activated, date_added, Book_Title
from active_books )
), 


--------- Consolidating all ranking paramteres
score_result as 
(
select  
active_books.Book_ID, active_books.Book_Title, Subject_name, topic_name, language_name, publisher_name, publisher_imprint, Author,
/* DTC Revenue */
cast(coalesce(dtc_revenue.norm_DTC_Revenue,0) as double) as norm_DTC_Revenue,

/* Academic mandate */
cast(coalesce(academic_mandate.norm_enrollment,0) as double)  as norm_enrollment,

/* Readership */
cast(coalesce(readership.norm_bay_read_mins,0) as double) as norm_bay_read_mins,

/* Interest */
cast(coalesce(Interest.norm_clicks,0) as double)  as norm_clicks,

/* Newness */
coalesce(Newness.publication_date_clean,'0') as publication_date,
rank() over (order by coalesce(Newness.publication_date_clean,'0') desc, Newness.date_activated desc, Newness.date_added desc, Newness.Book_Title asc)  Newness


from active_books
left join dtc_revenue on (active_books.book_id = dtc_revenue.referrer_book)
left join academic_mandate on (active_books.book_id = academic_mandate.book_id)
left join Readership on (active_books.book_id = Readership.book_id)
left join Interest on (active_books.book_id = Interest.book_id)
left join Newness on (active_books.book_id = Newness.book_id)
)

Select 
book_id, Book_Title, Subject_name, topic_name, language_name, publisher_name, publisher_imprint, Author,
norm_DTC_Revenue, --as DTC_Revenue,
norm_enrollment, --as Academic_Mandate, 
norm_bay_read_mins, --as Readership, 
norm_clicks, --as Interest,
publication_date ,--as Newness,
Newness,
Overall_rank,
CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS athena_timestamp
from (
select 
a.*,
rank() over ( order by norm_DTC_Revenue desc, norm_enrollment desc, norm_bay_read_mins desc, norm_clicks desc, Newness asc) overall_rank
from score_result a
)
;
