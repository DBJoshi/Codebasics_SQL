SELECT * FROM gdb023.dim_customer;
---1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT market, region
FROM dim_customer
WHERE customer = 'Atliq exclusive'
AND region = 'APAC'

----2.What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,unique_products_2020, unique_products_2021, percentage_chg

WITH unique_product_2020 as (SELECT COUNT(DISTINCT product_code) AS unique_product_2020
FROM fact_sales_monthly
WHERE fiscal_year = 2020 ),
unique_product_2021 AS (SELECT COUNT(DISTINCT product_code) AS unique_product_2021 
FROM fact_sales_monthly
WHERE fiscal_year = 2021)
SELECT *, ( (unique_product_2021-unique_product_2020)/unique_product_2020)*100 As percentage_chg
FROM unique_product_2020, unique_product_2021;

----3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields: 
segment, product_count

SELECT  segment,COUNT(DISTINCT product_code) AS product_count
FROM dim_product
Group by segment
ORDER BY product_count DESC;

---4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields:
segment, product_count_2020, product_count_2021, difference

WITH pc_2020 AS (SELECT dm.segment as segment,  COUNT(DISTINCT dm.product_code) As product_count_2020
FROM dim_product as dm 
INNER JOIN fact_sales_monthly as fsm
ON dm.product_code = fsm.product_code
WHERE fsm.fiscal_year = 2020
GROUP BY dm.segment),
pc_2021 AS( SELECT dm.segment As segment, COUNT(DISTINCT dm.product_code) As product_count_2021
FROM dim_product as dm 
INNER JOIN fact_sales_monthly as fsm
ON dm.product_code = fsm.product_code
WHERE fsm.fiscal_year = 2021
GROUP BY dm.segment)
SELECT segment, product_count_2020, product_count_2021, (product_count_2021-product_count_2020) As difference
FROM pc_2020
JOIN pc_2021
USING (segment)
ORDER BY difference DESC


----5. Get the products that have the highest and lowest manufacturing costs.The final output should contain these fields,
product_code, product, manufacturing_cost


SELECT dm.product_code, dm.product, fcm.manufacturing_cost
FROM dim_product as dm
INNER JOIN fact_manufacturing_cost As fcm
USING (product_code)
WHERE fcm.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
OR fcm.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;



---6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields,
customer_code, customer, average_discount_percentag use fact_pre_invoice_deductions, dim_customer 2. concepts like joins, where, Group by, Aggregate function(Avg), Round,order by, Limit, et

SELECT dc.customer_code, dc.customer, ROUND((AVG(fpid.pre_invoice_discount_pct))*100,2) AS average_discount_percentage
FROM dim_customer as dc
INNER JOIN fact_pre_invoice_deductions AS fpid
ON dc.customer_code = fpid.customer_code
WHERE dc.market = 'India'
AND fpid.fiscal_year = 2021
GROUP BY dc.customer, dc.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;


---7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.
The final report contains these columns: Month, Year, Gross sales Amount



SELECT MONTHNAME(fsm.date) as month, YEAR(fsm.date) as year, SUM(ROUND( fsm.sold_quantity*fgp.gross_price ,2))/1000000 As gross_sales_amount
FROM fact_gross_price AS fgp
INNER JOIN fact_sales_monthly as fsm
USING(product_code,fiscal_year)
INNER JOIN dim_customer as dc 
USING (customer_code)
WHERE dc.customer = 'Atliq Exclusive'
GROUP BY month, year;



-----8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,Quarter,total_sold_quantity
use the fact_sales_monthly table 2. derive the Month from the date and assign a Quarter. Note that fiscal_year for Atliq Hardware starts from September(09)
3. concepts like CTEs, case-when, where, Group by, Order by, and Aggregate function(sum).

SELECT 
CASE WHEN date between '2019-09-01' and '2019-11-30' then 'Quater1'
         WHEN date between '2019-12-01' and '2020-02-28' then 'Quater2'
         WHEN date between '2020-03-01' and '2020-05-31' then 'Quater3'
		 WHEN date between '2020-06-01' and '2020-08-31' then 'Quater4'
         END as 'Quater',
SUM(sold_quantity) as total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY quater
ORDER BY total_sold_quantity DESC;


----9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
channel, gross_sales_mln, percentage
1. gross_sales_mln = gross_price * sold_quantity 2. use fact_sales_monthly, fact_gross_price, dim_customer tables 3. concepts like joins, CTEs, where, Group by, Aggregate function(sum),
Round, order by, Limit, and window functions

WITH grm AS
(SELECT  dc.channel, ROUND((SUM(fgp.gross_price * fsm.sold_quantity))/1000000,2)As gross_sales_mln
FROM dim_customer as dc
Inner JOIN fact_sales_monthly as fsm
USING (customer_code)
INNER JOIN fact_gross_price as fgp
USING( product_code, fiscal_year)
WHERE fiscal_year = 2021
GROUP BY dc.channel
ORDER BY gross_sales_mln DESC)
SELECT channel, gross_sales_mln, (gross_sales_mln/SUM(gross_sales_mln) OVER ()*100)As percentages
FROM grm;


---10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division, product_code, product, total_sold_quantity, rank_order
use fact_sales_monthly, dim_product tables 2. concepts like CTEs, filtering, Group by, Aggregate function(sum), window functions like Rank, Partition By

WITH total as
(SELECT dp.division, dp.product_code, dp.product, SUM(fsm.sold_quantity) As total_sold_quantity
FROM dim_product as dp
JOIN fact_sales_monthly AS fsm
ON dp.product_code = fsm.product_code
WHERE fsm.fiscal_year = 2021
GROUP BY dp.division,dp.product_code, dp.product
ORDER BY total_sold_quantity DESC),
rk as
(SELECT *, DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
FROM total)
SELECT * from rk
WHERE rank_order <= 3;
 
 
