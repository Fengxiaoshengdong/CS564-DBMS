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

/*
result:
 dept |    contribution
------+--------------------
    2 | 0.0410644333395693
   38 | 0.0727544868985812
   40 | 0.0441973276022408
   72 | 0.0420093366708089
   90 |  0.044952085107151
   91 | 0.0313700059687512
   92 | 0.0730967512147294
   93 | 0.0254024091054592
   94 | 0.0304081375555446
   95 | 0.0695251010358334
(10 rows)
*/