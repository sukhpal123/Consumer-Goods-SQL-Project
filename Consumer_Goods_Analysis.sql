USE Customer_Goods;

--1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct market from dim_customer where customer = 'Atliq Exclusive' and region = 'APAC';
--What is the percentage of unique product increase in 2021 vs. 2020?
select 
count(distinct case when fiscal_year = 2020 then product_code end) as unique_product_2020,
count(distinct case when fiscal_year = 2021 then product_code end) as unique_product_2021,
ROUND((CAST(count(distinct case when fiscal_year = 2021 then product_code end)
-count(distinct case when fiscal_year = 2020 then product_code end) AS float)
/count(distinct case when fiscal_year = 2020 then product_code end))*100,1) AS percentage_change
from fact_sales_monthly
where fiscal_year IN (2020,2021);

--3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
select segment,count(distinct product_code) as product_count from dim_product group by segment order by product_count desc;

--4: Which segment had the most increase in unique products in 2021 vs 2020?
select Top 3 segment,
COUNT(distinct case when fiscal_year = 2020 then dp.product_code end) as unique_product_2020,
COUNT(distinct case when fiscal_year = 2021 then dp.product_code end) as unique_product_2021,
(COUNT(distinct case when fiscal_year = 2021 then dp.product_code end) - COUNT(distinct case when fiscal_year = 2020 then dp.product_code end)) as difference
from dim_product dp join fact_sales_monthly fsm on dp.product_code = fsm.product_code group by segment order by difference desc;

--5.	Get the products that have the highest and lowest manufacturing costs. 
select distinct dp.product_code,product, manufacturing_cost from dim_product dp join fact_manufacturing_cost fmc on dp.product_code = fmc.product_code
where manufacturing_cost = (select MAX(manufacturing_cost) from fact_manufacturing_cost) OR 
manufacturing_cost = (select MIN(manufacturing_cost) from fact_manufacturing_cost) order by manufacturing_cost desc;

--6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
select Top 5 dc.customer_code,customer,Round(AVG(pre_invoice_discount_pct),3) as average_discount_percentage from dim_customer dc 
join fact_pre_invoice_deductions fpd on dc.customer_code = fpd.customer_code
where fiscal_year = 2021 and market = 'India' group by dc.customer_code,customer order by average_discount_percentage desc;

--7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
--This analysis helps to get an idea of low and high-performing months and take strategic decisions.
select DATENAME(MONTH,date) as Month ,sale.fiscal_year,Round(Sum(gross_price * sold_quantity),1) as Gross_sale_amount from fact_sales_monthly sale join dim_customer dc on sale.customer_code = dc.customer_code 
join fact_gross_price gross  on  sale.product_code = gross.product_code where customer = 'Atliq Exclusive' group by DATENAME(MONTH,date),sale.fiscal_year
order by Gross_sale_amount desc;

--8.	In which quarter of 2020, got the maximum total_sold_quantity? 

select DATEPART(QQ,date) AS quarter, SUM(sold_quantity) as total_sold_quantity from fact_sales_monthly where fiscal_year = 2020 
group by DATEPART(QQ,date) ;

with cte_quarter as 
(select 
case 
when DATEPART(QQ,date) = '3' then 'Q1' 
when DATEPART(QQ,date) = '4' then 'Q2' 
when DATEPART(QQ,date) = '1' then 'Q3' 
when DATEPART(QQ,date) = '2' then 'Q4'
end
as quarter,SUM(sold_quantity) as total_sold_quantity
from fact_sales_monthly where fiscal_year = 2020 group by DATEPART(QQ,date)
)
select * from cte_quarter;

-- 9.	Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
 With CTE as
 (select distinct channel, Round(SUM(gross_price * sold_quantity),1) as gross_sales_mln from fact_sales_monthly sale 
 join fact_gross_price gross on sale.product_code = gross.product_code 
 join dim_customer dc on sale.customer_code = dc.customer_code where sale.fiscal_year = 2021 
 group by channel)
 select channel,gross_sales_mln, (gross_sales_mln/(select sum(gross_sales_mln) from CTE))*100 as percentage 
 from CTE order by percentage desc;

 -- 10.	Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
 With sale as
 (select dp.division,dp.product_code,dp.product,sum(sold_quantity) total_sold_quantity, 
 RANK() over(PARTITION BY division Order by sum(sold_quantity) desc) AS Rank from dim_product  dp 
 join fact_sales_monthly sale on dp.product_code = sale.product_code where fiscal_year = 2021
 group by dp.division,dp.product_code,dp.product)

 select * from sale where rank <= 3;