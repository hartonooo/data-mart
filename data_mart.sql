--1. DATA CLEANING
select *,
SUBSTRING(week_date,2, CHARINDEX('/', week_date, 1)-2)  as day, 
SUBSTRING(week_date, CHARINDEX('/', week_date, 1)+1, 1) as month_number,
concat('20', SUBSTRING(week_date, CHARINDEX('/', week_date, CHARINDEX('/', week_date)+1)+1, 2)) as calendar_year,
DATEFROMPARTS(concat('20', SUBSTRING(week_date, CHARINDEX('/', week_date, CHARINDEX('/', week_date)+1)+1, 2)),
				SUBSTRING(week_date, CHARINDEX('/', week_date, 1)+1, 1),
				SUBSTRING(week_date,2, CHARINDEX('/', week_date, 1)-2)) as date_full,
case
	when SUBSTRING(week_date,2, CHARINDEX('/', week_date, 1)-2) between 1 and 7 then 1
	when SUBSTRING(week_date,2, CHARINDEX('/', week_date, 1)-2) between 8 and 14 then 2
	when SUBSTRING(week_date,2, CHARINDEX('/', week_date, 1)-2) between 15 and 21 then 3
	else 4
end as week_number,
case 
	when SUBSTRING(segment, 2, 1) = 'C' then 'Couples'
	when SUBSTRING(segment, 2, 1) = 'F' then 'Families'
	else 'unknown'
end as demographic,
case
	when SUBSTRING(segment, 3, 1) = '1' then 'Young Adults'
	when SUBSTRING(segment, 3, 1) = '2' then 'Middle Aged'
	when SUBSTRING(segment, 3, 1) = '3' or SUBSTRING(segment, 3, 1) = '4' then 'Retirees'
	else 'unknown'
end as age_band, 
round(sales*100.0/transactions, 2) as avg_transaction
into clean_weekly_sales
from data_mart_weekly_sales;


--2. DATA EXPLORATION

--1. What day of the week is used for each week_date value?
select distinct date_full, DAY(date_full)
from clean_weekly_sales
order by date_full;



--2. What range of week numbers are missing from the dataset?
select distinct week_number
from clean_weekly_sales
order by week_number;

--none is missing


--3. How many total transactions were there for each year in the dataset?
select calendar_year, SUM(transactions) as total_trx
from clean_weekly_sales
group by calendar_year;



--4. What is the total sales for each region for each month?
select region, sum(CAST(sales as bigint)) as total_sales
from clean_weekly_sales
group by region;



--5. What is the total count of transactions for each platform
select platform, COUNT(transactions) as total_cnt_trx
from clean_weekly_sales
group by platform;


--6. What is the percentage of sales for Retail vs Shopify for each month?
with satu as (select calendar_year, month_number, platform, sum(CAST(sales as bigint)) as total_sales
from clean_weekly_sales
group by calendar_year, month_number
)

select *, 
SUM(total_sales) over(partition by calendar_year) as total_sales_all, 
round(total_sales * 100.0 / SUM(total_sales) over(partition by calendar_year, month_number), 2) as pct_sales_per_month
from satu
order by calendar_year, month_number, platform;


--7. What is the percentage of sales by demographic for each year in the dataset?
with satu as (select calendar_year, demographic, sum(CAST(sales as bigint)) as total_sales
from clean_weekly_sales
group by calendar_year, demographic)

select *, SUM(total_sales) over(partition by calendar_year) as total_sales_all,
round(total_sales * 100.0 / SUM(total_sales) over(partition by calendar_year), 2) as pct_demographic_per_year
from satu
order by calendar_year, demographic;


--8. Which age_band and demographic values contribute the most to Retail sales? 
select age_band, demographic, sum(CAST(sales as bigint)) as total_sales
from clean_weekly_sales
where platform = '''Retail'''
group by age_band, demographic
order by sum(CAST(sales as bigint)) desc;

--> unknown, retirees families or retirees couples

--9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
--If not - how would you calculate it instead?

select calendar_year, platform, avg(CAST(sales as bigint)) as avg_trx
from clean_weekly_sales
group by calendar_year, platform
order by calendar_year, platform;



--3. BEFORE & AFTER ANALYSIS

--start new program (condition) at date_full: 2020-06-15 

--1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
with satu as (select *,
case
	when date_full >= '2020-06-15' then 'after' else 'before'
end as new_packaging_date
from clean_weekly_sales),

total_sales_4_weeks_before as(
select sum(CAST(sales as bigint)) as total_sales_before
from satu
where date_full between DATEADD(week, -4, '2020-06-15') and '2020-06-15'),


total_sales_4_weeks_after as(
select sum(CAST(sales as bigint)) as total_sales_after
from satu
where date_full between '2020-06-15' and DATEADD(week, 4, '2020-06-15'))

select *,
case
	when total_sales_4_weeks_before.total_sales_before > total_sales_4_weeks_after.total_sales_after then 'before is more trx' else 'after is more trx'
end as status,
total_sales_4_weeks_before.total_sales_before - total_sales_4_weeks_after.total_sales_after as diff
from total_sales_4_weeks_before, total_sales_4_weeks_after
--> more trx before new program launched, in timeline 4 weeks before and 4 weeks after
--> the difference: 10.973.134



--2. What about the entire 12 weeks before and after?
with satu as (select *,
case
	when date_full >= '2020-06-15' then 'after' else 'before'
end as new_packaging_date
from clean_weekly_sales),

total_sales_12_weeks_before as(
select sum(CAST(sales as bigint)) as total_sales_before
from satu
where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'),


total_sales_12_weeks_after as(
select sum(CAST(sales as bigint)) as total_sales_after
from satu
where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15'))

select *,	
case
	when total_sales_12_weeks_before.total_sales_before > total_sales_12_weeks_after.total_sales_after then 'before is more trx' else 'after is more trx'
end as status,
total_sales_12_weeks_before.total_sales_before - total_sales_12_weeks_after.total_sales_after as diff
from total_sales_12_weeks_before, total_sales_12_weeks_after

--> more trx before new program launched, in timeline 12 weeks before and 12 weeks after
--> the difference got more bigger for 'before' status: 722.350.742



--3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
select calendar_year, sum(CAST(sales as bigint)) as total_sales
from clean_weekly_sales
group by calendar_year

--> with total_sales before new program:
	--2018 around 13 million, 
	--2019 around 14 million,
	--4 weeks before and
	--12 weeks after
--all show bigger total_sales compared to total_sales after new program launched




--4. BONUS QUESTION
--Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

--1. REGION:

with satu as (select *,
case
	when date_full >= '2020-06-15' then 'after' else 'before'
end as new_packaging_date
from clean_weekly_sales),

total_sales_12_weeks_before as(
select region, sum(CAST(sales as bigint)) as total_sales_before
from satu
where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by region),


total_sales_12_weeks_after as(
select region, sum(CAST(sales as bigint)) as total_sales_after
from satu
where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
group by region)

select b.region, 
		b. total_sales_before, 
		a.total_sales_after,
		(b.total_sales_before - a.total_sales_after) as diff,
		round((b.total_sales_before - a.total_sales_after) *100.0 / b. total_sales_before, 2) as pct
from total_sales_12_weeks_before b
join total_sales_12_weeks_after a
on b.region = a.region
order by (b.total_sales_before - a.total_sales_after) *100.0 / b. total_sales_before desc;

--> the region got more impact is asia


--2. PLATFORM:

with satu as (select *,
case
	when date_full >= '2020-06-15' then 'after' else 'before'
end as new_packaging_date
from clean_weekly_sales),

total_sales_12_weeks_before as(
select platform, sum(CAST(sales as bigint)) as total_sales_before
from satu
where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by platform),


total_sales_12_weeks_after as(
select platform, sum(CAST(sales as bigint)) as total_sales_after
from satu
where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
group by platform)

select b.platform, 
		b. total_sales_before, 
		a.total_sales_after,
		(b.total_sales_before - a.total_sales_after) as diff,
		round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) as pct
from total_sales_12_weeks_before b
join total_sales_12_weeks_after a
on b.platform = a.platform
order by round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) desc;

--> the platform got more impact is retail



--3. age_band:

with satu as (select *,
case
	when date_full >= '2020-06-15' then 'after' else 'before'
end as new_packaging_date
from clean_weekly_sales),

total_sales_12_weeks_before as(
select age_band, sum(CAST(sales as bigint)) as total_sales_before
from satu
where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by age_band),


total_sales_12_weeks_after as(
select age_band, sum(CAST(sales as bigint)) as total_sales_after
from satu
where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
group by age_band)

select b.age_band, 
		b. total_sales_before, 
		a.total_sales_after,
		(b.total_sales_before - a.total_sales_after) as diff,
		round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) as pct
from total_sales_12_weeks_before b
join total_sales_12_weeks_after a
on b.age_band = a.age_band
order by round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) desc;

--> the age_band got more impact is middle aged


--4. demographic:

with satu as (select *,
case
	when date_full >= '2020-06-15' then 'after' else 'before'
end as new_packaging_date
from clean_weekly_sales),

total_sales_12_weeks_before as(
select demographic, sum(CAST(sales as bigint)) as total_sales_before
from satu
where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by demographic),


total_sales_12_weeks_after as(
select demographic, sum(CAST(sales as bigint)) as total_sales_after
from satu
where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
group by demographic)

select b.demographic, 
		b. total_sales_before, 
		a.total_sales_after,
		(b.total_sales_before - a.total_sales_after) as diff,
		round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) as pct
from total_sales_12_weeks_before b
join total_sales_12_weeks_after a
on b.demographic = a.demographic
order by round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) desc;

--> the demographic got more impact is families

--5 customer type:

with satu as (select *,
case
	when date_full >= '2020-06-15' then 'after' else 'before'
end as new_packaging_date
from clean_weekly_sales),

total_sales_12_weeks_before as(
select customer_type, sum(CAST(sales as bigint)) as total_sales_before
from satu
where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by customer_type),


total_sales_12_weeks_after as(
select customer_type, sum(CAST(sales as bigint)) as total_sales_after
from satu
where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
group by customer_type)

select b.customer_type, 
		b. total_sales_before, 
		a.total_sales_after,
		(b.total_sales_before - a.total_sales_after) as diff,
		round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) as pct
from total_sales_12_weeks_before b
join total_sales_12_weeks_after a
on b.customer_type = a.customer_type
order by round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) desc;

--> the customer type got more impact is guest


