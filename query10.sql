10. The accounting department has asked for the following report. Write a SQL Query that
would most closely produce the needed report. Quarters are defined traditionally, with
Jan,Feb,March being Q1, etc. 

WITH MONTH_SALE(Store, dept, WeeklySales, month, year, type) AS (
	SELECT sa.Store, sa.dept, sa.WeeklySales, SUBSTRING(CAST(WeekDate AS varchar(10)),6,2) AS month, 
    SUBSTRING(CAST(WeekDate AS varchar(10)),0,5) AS year, st.type
	FROM Sales sa, Stores st
	WHERE sa.Store = st.Store
),
 MONTH_SALE_SUM (year, quarters, type, MONTH_SUM) AS (
	SELECT year, CASE
        WHEN month = '01' OR month = '02' OR month = '03' THEN '1'
        WHEN month = '04' OR month = '05' OR month = '06' THEN '2'
        WHEN month = '07' OR month = '08' OR month = '09' THEN '3'
        WHEN month = '10' OR month = '11' OR month = '12' THEN '4'
    END Quarters    
    , type, SUM(WeeklySales) AS MONTH_SUM
	FROM MONTH_SALE
	GROUP BY month, type, year
	ORDER BY type, year, month
),
quarter_sale AS(
SELECT year, quarters, type, SUM(MONTH_SUM) 
FROM MONTH_SALE_SUM
GROUP BY year, quarters, type
ORDER BY year, quarters, type
),
store_sales_in_quarters AS
(SELECT qa.year, qa.quarters, qa.store_a_sales, qb.store_b_sales, qc.store_c_sales
FROM
(SELECT year, quarters, SUM(sum) AS store_a_sales
FROM quarter_sale
WHERE type = 'A'
GROUP BY year, quarters
ORDER BY year, quarters) AS qa 
INNER JOIN 
(SELECT year, quarters, SUM(sum) AS store_b_sales
FROM quarter_sale
WHERE type = 'B'
GROUP BY year, quarters
ORDER BY year, quarters) AS qb ON qa.year = qb.year AND qa.quarters = qb.quarters
INNER JOIN 
(SELECT year, quarters, SUM(sum) AS store_c_sales
FROM quarter_sale 
WHERE type = 'C'
GROUP BY year, quarters
ORDER BY year, quarters) AS qc ON qa.year = qc.year AND qa.quarters = qc.quarters)
SELECT * FROM store_sales_in_quarters
UNION
SELECT '2010' AS year, NULL AS quarters, SUM(store_a_sales) AS store_a_sales, SUM(store_b_sales) AS store_b_sales,
SUM(store_c_sales) AS store_c_sales
FROM store_sales_in_quarters
WHERE year = '2010'
UNION
SELECT '2011' AS year, NULL AS quarters, SUM(store_a_sales) AS store_a_sales, SUM(store_b_sales) AS store_b_sales,
SUM(store_c_sales) AS store_c_sales
FROM store_sales_in_quarters
WHERE year = '2011'
UNION
SELECT '2012' AS year, NULL AS quarters, SUM(store_a_sales) AS store_a_sales, SUM(store_b_sales) AS store_b_sales,
SUM(store_c_sales) AS store_c_sales
FROM store_sales_in_quarters
WHERE year = '2012'
ORDER BY year , quarters ASC NULLS LAST;










