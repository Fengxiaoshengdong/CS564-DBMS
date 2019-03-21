7. Which departments contribute to at least 5% of store sales across for at least 3 stores? List the departments and 
their average contribution to sales across the stores.

WITH deptStoreSale 
AS 
    (SELECT store, dept, SUM(WeeklySales) AS store_dept_Sales
    FROM Sales 
    GROUP BY store, dept
    ORDER BY SUM(WeeklySales), store),
storeSale
AS 
    (SELECT store, SUM(WeeklySales) AS store_Sales
    FROM Sales 
    GROUP BY store
    ORDER BY SUM(WeeklySales), store),
overFivePercent(dept, store, fivePercentStoreSales, store_dept_Sales)
AS
    (SELECT d.dept, d.store, s.store_Sales*0.05, d.store_dept_Sales
    FROM deptStoreSale d, storeSale s
    WHERE store_dept_Sales > 0.05 * store_Sales AND d.store = s.store),
candidateDept
AS 
    (SELECT  dept, COUNT(dept) 
    FROM overFivePercent
    GROUP BY dept
    HAVING COUNT(dept) >= 3
    ORDER BY dept),
avgDeptContribution 
AS
    (SELECT d.dept, AVG(d.store_dept_Sales / s.store_Sales) AS contribution
    FROM deptStoreSale d, storeSale s
    WHERE d.store = s.store
    GROUP BY d.dept)
SELECT c.dept, a.contribution
FROM candidateDept c, avgDeptContribution a
WHERE c.dept = a.dept;