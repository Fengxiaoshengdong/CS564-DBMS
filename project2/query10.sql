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

/*
result:
 year | quarters | store_a_sales | store_b_sales | store_c_sales
------+----------+---------------+---------------+---------------
 2010 | 1        |   2.38155e+08 |   1.11852e+08 |   2.22458e+07
 2010 | 2        |   3.90789e+08 |    1.8321e+08 |   3.63699e+07
 2010 | 3        |   3.82694e+08 |   1.78504e+08 |   3.62904e+07
 2010 | 4        |   4.53792e+08 |   2.16412e+08 |    3.8572e+07
 2010 |          |   1.46543e+09 |   6.89978e+08 |   1.33478e+08
 2011 | 1        |   3.41852e+08 |   1.53904e+08 |   3.36366e+07
 2011 | 2        |   3.85807e+08 |   1.75556e+08 |   3.65837e+07
 2011 | 3        |   4.13364e+08 |   1.87497e+08 |   3.84975e+07
 2011 | 4        |   4.37185e+08 |   2.07162e+08 |   3.71553e+07
 2011 |          |   1.57821e+09 |   7.24119e+08 |   1.45873e+08
 2012 | 1        |   3.81451e+08 |   1.72499e+08 |   3.85173e+07
 2012 | 2        |   3.98117e+08 |   1.81932e+08 |   3.82483e+07
 2012 | 3        |   3.89167e+08 |   1.78201e+08 |   3.76368e+07
 2012 | 4        |    1.1864e+08 |   5.39715e+07 |   1.17501e+07
 2012 |          |   1.28738e+09 |   5.86604e+08 |   1.26153e+08
(15 rows)
*/