4. Get the total sales per month, and its contribution to total sales (across months) overall for each type of store.
WITH 
MONTH_SALE(WeeklySales, type, month) 
AS 
	(SELECT sa.WeeklySales, st.type, SUBSTRING(CAST(WeekDate AS varchar(10)),6,2) AS month
	FROM Sales sa, Stores st
	WHERE sa.Store = st.Store
	),
MONTH_SALE_SUM 
AS 
	(SELECT month, type, SUM(WeeklySales) AS MONTH_SUM
	FROM MONTH_SALE
	GROUP BY month, type
	ORDER BY type, month
	)
SELECT CASE month
		WHEN '01' THEN 'Jan'
		WHEN '02' THEN 'Feb'
		WHEN '03' THEN 'Mar'
		WHEN '04' THEN 'Apr'
		WHEN '05' THEN 'May'
		WHEN '06' THEN 'Jun'
		WHEN '07' THEN 'Jul'
		WHEN '08' THEN 'Aug'
		WHEN '09' THEN 'Sep'
		WHEN '10' THEN 'Oct'
		WHEN '11' THEN 'Nov'
		WHEN '12' THEN 'Dec'
	END months, 
	type, MONTH_SUM, MONTH_SUM * 100/SUM(MONTH_SUM) OVER(PARTITION BY type) "% contribution"
FROM MONTH_SALE_SUM;
