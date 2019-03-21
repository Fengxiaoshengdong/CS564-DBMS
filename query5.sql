5. Which stores have had sales in every department in that store for every month of at least one calendar year among 2010, 2011, and 2012?
 
WITH MONTH_SALE(Store, dept, WeeklySales, month, year) 
AS (SELECT sa.Store,sa.dept, sa.WeeklySales, SUBSTRING(CAST(WeekDate AS varchar(10)),6,2) AS month, SUBSTRING(CAST(WeekDate AS varchar(10)),0,5) AS year
	FROM Sales sa, Stores st
	WHERE sa.Store = st.Store
	),
MONTH_SALE_SUM 
AS 
	(SELECT store, dept, month, SUM(WeeklySales) AS MONTH_SUM, year
	FROM MONTH_SALE
	GROUP BY month, store, dept, year
	ORDER BY store, year, month
)
SELECT DISTINCT Store
FROM MONTH_SALE_SUM 
WHERE MONTH = ALL(SELECT DISTINCT MONTH FROM MONTH_SALE_SUM)
	AND dept = ALL(SELECT DISTINCT dept FROM MONTH_SALE_SUM)
	AND year = ANY(SELECT DISTINCT year FROM MONTH_SALE_SUM)
	AND MONTH_SUM > 0;