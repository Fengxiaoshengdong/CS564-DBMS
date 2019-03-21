9. For the top 10 departments (in above query8), find the sales, % contribution of monthly sales to total sales 
and monthly cumulative total of sales. Format the output to 2 decimal places.

WITH TOP10 
AS 
    (SELECT Sa.dept, SUM(Sa.WeeklySales/St.size) AS totalNormSale, RANK() OVER(ORDER BY SUM(Sa.WeeklySales/St.size) DESC) AS rank
    FROM Sales Sa, Stores St
    WHERE Sa.store = St.store
    GROUP BY dept
    LIMIT 10),
MONTH_SALE(Store, dept, WeeklySales, month, year) 
AS 
    (SELECT sa.Store,sa.dept, sa.WeeklySales, SUBSTRING(CAST(WeekDate AS varchar(10)),6,2) AS month, SUBSTRING(CAST(WeekDate AS varchar(10)),0,5) AS year
	FROM Sales sa, Stores st
	WHERE sa.Store = st.Store
	),
MONTH_SALE_SUM 
AS 
	(SELECT store, dept, month, SUM(WeeklySales) AS MONTH_SUM, year
	FROM MONTH_SALE
	GROUP BY month, store, dept, year
	ORDER BY store, year, month
),
monthSaleByDept(dept, yr, mo, monthlysales) 
AS
    (SELECT m.dept, year, month, SUM(MONTH_SUM) AS monthlysales
    FROM MONTH_SALE_SUM m, TOP10 t
    WHERE m.dept = t.dept
    GROUP BY m.dept, year, month
    ORDER BY m.dept, year, month
    )

SELECT *, ROUND(CAST (100 * monthlysales/SUM(monthlysales) OVER(PARTITION BY dept) AS NUMERIC), 2) AS contribution,
ROUND(CAST(SUM(monthlysales) OVER(PARTITION BY dept rows BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NUMERIC), 2) AS cumulative_sales   
FROM monthSaleByDept;
