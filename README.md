# data-mart
- analyzing supermarket's business performance after new packaging program launched
- using MS. SQL SERVER STUDIO

SQL project/case study from : https://8weeksqlchallenge.com/case-study-5/

steps:
1. import data_mart_weekly_sales.csv into SQL SERVER
2. data cleaning -> create new table: clean_weekly_sales
        </br>
        <details>
        <summary>clean_weekly_sales</summary>
        <pre>
        select region, platform, segment, customer_type, transactions, sales,
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
        </pre>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/1.%20clean_weekly_sales.jpg">
        </details>

3. data exploration:
    
    1. What day of the week is used for each week_date value?      
        <details>
        <summary>day_used</summary>            
        <pre>
        select distinct date_full, DAY(date_full) as day_used
        from clean_weekly_sales
        order by date_full;</pre>          
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/2.1%20day_used.jpg">
        </details>
        
        
    2. What range of week numbers are missing from the dataset?
    
        <details>    
        <summary>week numbers</summary>        
        <pre>
        select distinct week_number
        from clean_weekly_sales
        order by week_number;</pre>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/2.2%20week_numbers.jpg">
        </details>
    
    
    3. How many total transactions were there for each year in the dataset?
        
        <details>    
        <summary>total transactions for each year</summary>        
        <pre>
        select calendar_year, SUM(transactions) as total_trx
        from clean_weekly_sales
        group by calendar_year;
        </pre>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/2_3%20total_trx.jpg">
        </details>
    
    4. What is the total sales for each region for each month?
        
        <details>    
        <summary>total sales for each region, each month</summary>        
        <pre>
        with satu as (select *
        from (select region, month_number, CAST(sales as bigint) as sales
            from clean_weekly_sales) s
        pivot(
            sum(sales)
            for region in (['AFRICA'], ['ASIA'], ['CANADA'], ['EUROPE'], ['OCEANIA'], ['SOUTH AMERICA'], ['USA'])
        ) pivot_table)

        select *
        from satu
        order by month_number;
        </pre>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/2.4%20total_sales_for_each_region_for_each_month.jpg">
        </details>
    
    5. What is the total count of transactions for each platform?
        <details>    
        <summary>total count of transactions for each platform</summary>        
        <pre>
        select platform, COUNT(transactions) as total_cnt_trx
        from clean_weekly_sales
        group by platform;
        </pre>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/2.5%20total_count_of_transactions_for_each_platform.jpg">
        </details>
    
    6. What is the percentage of sales for Retail vs Shopify for each month?
        <details>    
        <summary>percentage of sales for Retail vs Shopify for each month</summary>        
        <pre>
        with satu as (select calendar_year, month_number, platform, sum(CAST(sales as bigint)) as total_sales
        from clean_weekly_sales
        group by calendar_year, month_number, platform
        ), 
        </br>
        dua as (select *, 
        SUM(total_sales) over(partition by calendar_year) as total_sales_all, 
        round(total_sales * 100.0 / SUM(total_sales) over(partition by calendar_year, month_number), 2) as pct_sales_per_month
        from satu)
        </br>
        select *
        from (select calendar_year, platform, month_number, pct_sales_per_month from dua) s
        pivot (
            max(pct_sales_per_month)
            for calendar_year in ([2018], [2019], [2020])
        ) pvt        
        </pre>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/2.6%20percentage%20of%20sales%20for%20Retail%20vs%20Shopify%20for%20each%20month.jpg">
        </details>
        
    7. What is the percentage of sales by demographic for each year in the dataset?
        <details>    
        <summary>percentage of sales by demographic for each year</summary>        
        <pre>
        with satu as (select calendar_year, demographic, sum(CAST(sales as bigint)) as total_sales
        from clean_weekly_sales
        group by calendar_year, demographic),
        </br>
        dua as (select *, SUM(total_sales) over(partition by calendar_year) as total_sales_all,
        round(total_sales * 100.0 / SUM(total_sales) over(partition by calendar_year), 2) as pct_demographic_per_year
        from satu)
        </br>        
        select *
        from (select demographic, calendar_year, pct_demographic_per_year from dua) s
        pivot(
            max(pct_demographic_per_year)
            for calendar_year in ([2018], [2019], [2020])
        ) pvt
        </pre>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/2.7%20percentage%20of%20sales%20by%20demographic%20for%20each%20year.jpg">
        </details>
    
    8. Which age_band and demographic values contribute the most to Retail sales?
        <details>    
        <summary>age_band and demographic values contribute the most to Retail sales</summary> 
        <p>retirees-families and retirees-couples</p>
        <pre>
        select platform, age_band, demographic, sum(CAST(sales as bigint)) as total_sales, RANK() over(order by sum(CAST(sales as bigint)) desc) as ranking
        from clean_weekly_sales
        where platform = '''Retail''' and age_band <> 'unknown'
        group by platform, age_band, demographic;
        </pre>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/2.8%20age_band%20and%20demographic%20values%20contribute%20the%20most%20to%20Retail%20sales.jpg">
        </details>
    
      
    9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
        <details>    
        <summary>average transaction size for each year for Retail vs Shopify</summary> 
        <pre>
        select calendar_year, platform, avg(CAST(sales as bigint)) as avg_trx
        from clean_weekly_sales
        group by calendar_year, platform
        order by calendar_year, platform;        
        </pre>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/2.9%20average%20transaction%20size%20for%20each%20year%20for%20Retail%20vs%20Shopify.jpg">
        </details>


4. analyzing data:
    
    1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
        <details>    
        <summary>total sales for the 4 weeks before and after 2020-06-15</summary> 
        <pre>
        with satu as (select *,
        case
        when date_full >= '2020-06-15' then 'after' else 'before'
        end as new_packaging_date
        from clean_weekly_sales),</br>
        
        total_sales_4_weeks_before as(
        select sum(CAST(sales as bigint)) as total_sales_before
        from satu
        where date_full between DATEADD(week, -4, '2020-06-15') and '2020-06-15'),</br>
        
        total_sales_4_weeks_after as(
        select sum(CAST(sales as bigint)) as total_sales_after
        from satu
        where date_full between '2020-06-15' and DATEADD(week, 4, '2020-06-15'))</br>
        
        select *,
        case
        when total_sales_4_weeks_before.total_sales_before > total_sales_4_weeks_after.total_sales_after then 'before is more trx' else 'after is more trx'
        end as status,
        total_sales_4_weeks_before.total_sales_before - total_sales_4_weeks_after.total_sales_after as diff
        from total_sales_4_weeks_before, total_sales_4_weeks_after;   
        </pre></br>
        <p>more trx before new program launched, in timeline 4 weeks before and 4 weeks after</p>
        <p>the difference: 10.973.134</p>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/3.1%20total%20sales%20for%20the%204%20weeks%20before%20and%20after%202020-06-15.jpg">
        </details>

    
    2. What about the entire 12 weeks before and after?
        <details>    
        <summary>total sales for the 12 weeks before and after 2020-06-15</summary> 
        <pre>
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
        </pre></br>
        <p>more trx before new program launched, in timeline 12 weeks before and 12 weeks after</p>
        <p>the difference got more bigger for 'before' status: 722.350.742</p>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/3.2%20total%20sales%20for%20the%2012%20weeks%20before%20and%20after%202020-06-15.jpg">
        </details>
    
    
    3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
        <details>    
        <summary>compare with the previous years in 2018 and 2019</summary> 
        <pre>
        select calendar_year, sum(CAST(sales as bigint)) as total_sales
        from clean_weekly_sales
        where calendar_year in (2018, 2019)
        group by calendar_year;     
        </pre></br>
        <p>with total_sales before new program:</p>
        
                - 2018 around 13 million
                - 2019 around 14 million
                - 4 weeks before and
                - 12 weeks before
                
        <p>all show bigger total_sales compared to total_sales after new program launched</p>
        
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/3.3%20compare%20with%20the%20previous%20years%20in%202018%20and%202019.jpg">
        </details>



5. more question:
    Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
      1. region
        <details>    
        <summary>region with highest negative impact</summary> 
        <pre>
        with satu as (select *,
        case
        when date_full >= '2020-06-15' then 'after' else 'before'
        end as new_packaging_date
        from clean_weekly_sales),</br>
        total_sales_12_weeks_before as(
        select region, sum(CAST(sales as bigint)) as total_sales_before
        from satu
        where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
        group by region),</br>
        total_sales_12_weeks_after as(
        select region, sum(CAST(sales as bigint)) as total_sales_after
        from satu
        where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
        group by region)</br>
        select b.region, 
                b. total_sales_before, 
                a.total_sales_after,
                (b.total_sales_before - a.total_sales_after) as diff,
                round((b.total_sales_before - a.total_sales_after) *100.0 / b. total_sales_before, 2) as pct_impact
                from total_sales_12_weeks_before b
                join total_sales_12_weeks_after a
                on b.region = a.region
                order by (b.total_sales_before - a.total_sales_after) *100.0 / b. total_sales_before desc;         
        </pre></br>
        <p>the region with highest negative impact is asia</p>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/4.1%20region%20negative%20impact.jpg">
        </details>      
      
      2. platform
        <details>    
        <summary>platform with highest negative impact</summary> 
        <pre>
        with satu as (select *,
        case
        when date_full >= '2020-06-15' then 'after' else 'before'
        end as new_packaging_date
        from clean_weekly_sales),</br>
        total_sales_12_weeks_before as(
        select platform, sum(CAST(sales as bigint)) as total_sales_before
        from satu
        where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
        group by platform),</br>
        total_sales_12_weeks_after as(
        select platform, sum(CAST(sales as bigint)) as total_sales_after
        from satu
        where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
        group by platform)</br>
        select b.platform, 
                b. total_sales_before, 
                a.total_sales_after,
                (b.total_sales_before - a.total_sales_after) as diff,
                round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) as pct_impact
        from total_sales_12_weeks_before b
        join total_sales_12_weeks_after a
        on b.platform = a.platform
        order by round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) desc;         
        </pre></br>
        <p>the platform with highest negative impact is retail</p>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/4.2%20platform%20negative%20impact.jpg">
        </details>    
                     
      3. age_band
        <details>    
        <summary>age_band with highest negative impact</summary> 
        <pre>
        with satu as (select *,
        case
        when date_full >= '2020-06-15' then 'after' else 'before'
        end as new_packaging_date
        from clean_weekly_sales),</br>
        total_sales_12_weeks_before as(
        select age_band, sum(CAST(sales as bigint)) as total_sales_before
        from satu
        where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
        group by age_band),</br>
        total_sales_12_weeks_after as(
        select age_band, sum(CAST(sales as bigint)) as total_sales_after
        from satu
        where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
        group by age_band)</br>
        select b.age_band, 
                b. total_sales_before, 
                a.total_sales_after,
                (b.total_sales_before - a.total_sales_after) as diff,
                round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) as pct_impact
        from total_sales_12_weeks_before b
        join total_sales_12_weeks_after a
        on b.age_band = a.age_band
        where b.age_band <> 'unknown'
        order by round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) desc;         
        </pre></br>
        <p>the age_band with highest negative impact is middle aged</p>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/4.3%20age_band%20negative%20impact.jpg">
        </details>    
      
      
      4. demographic
        <details>    
        <summary>demographic with highest negative impact</summary> 
        <pre>
        with satu as (select *,
        case
        when date_full >= '2020-06-15' then 'after' else 'before'
        end as new_packaging_date
        from clean_weekly_sales),</br>
        total_sales_12_weeks_before as(
        select demographic, sum(CAST(sales as bigint)) as total_sales_before
        from satu
        where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
        group by demographic),</br>
        total_sales_12_weeks_after as(
        select demographic, sum(CAST(sales as bigint)) as total_sales_after
        from satu
        where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
        group by demographic)</br>
        select b.demographic, 
                b. total_sales_before, 
                a.total_sales_after,
                (b.total_sales_before - a.total_sales_after) as diff,
                round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) as pct_impact
        from total_sales_12_weeks_before b
        join total_sales_12_weeks_after a
        on b.demographic = a.demographic
        where b.demographic <> 'unknown'
        order by round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) desc;       
        </pre></br>
        <p>the demographic with highest negative impact is families</p>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/4.4%20demographic%20negative%20impact.jpg">
        </details>    
      
      
      
      5. customer_type
        <details>    
        <summary>customer type with highest negative impact</summary> 
        <pre>
        with satu as (select *,
        case
        when date_full >= '2020-06-15' then 'after' else 'before'
        end as new_packaging_date
        from clean_weekly_sales),</br>
        total_sales_12_weeks_before as(
        select customer_type, sum(CAST(sales as bigint)) as total_sales_before
        from satu
        where date_full between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
        group by customer_type),</br>
        total_sales_12_weeks_after as(
        select customer_type, sum(CAST(sales as bigint)) as total_sales_after
        from satu
        where date_full between '2020-06-15' and DATEADD(week, 12, '2020-06-15')
        group by customer_type)</br>
        select b.customer_type, 
                        b. total_sales_before, 
                        a.total_sales_after,
                        (b.total_sales_before - a.total_sales_after) as diff,
                        round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) as pct_impact
        from total_sales_12_weeks_before b
        join total_sales_12_weeks_after a
        on b.customer_type = a.customer_type
        order by round((b.total_sales_before - a.total_sales_after) *100.0/ b. total_sales_before, 2) desc;             
        </pre></br>
        <p>the customer type with highest negative impact is guest</p>
        <img src="https://github.com/mas-tono/data-mart/blob/main/image/4.5%20customer%20type%20negative%20impact.jpg">
        </details>    







