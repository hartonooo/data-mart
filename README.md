# data-mart
- analyzing supermarket's business performance after new packaging program launched
- using MS. SQL SERVER STUDIO

SQL project/case study from : https://8weeksqlchallenge.com/case-study-5/

steps:
1. import data_mart_weekly_sales.csv into SQL SERVER
2. data cleaning
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
        
        </pre>
        <img src="">
        </details>
    
    
    7. What is the percentage of sales by demographic for each year in the dataset?
    8. Which age_band and demographic values contribute the most to Retail sales?
    9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

4. analyzing data:
    
    1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
    2. What about the entire 12 weeks before and after?
    3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

5. more question:
    Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
      1. region
      2. platform
      3. age_band
      4. demographic
      5. customer_type

