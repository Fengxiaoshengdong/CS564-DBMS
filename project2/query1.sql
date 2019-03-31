WITH Overall (Store, overallSales) AS (
	SELECT Store, SUM(WeeklySales) AS overallSales 
	FROM Sales S 
	GROUP BY S.Store)
SELECT O.Store, O.overallSales
FROM Overall O
WHERE O.overallSales = (SELECT MIN(overallSales) FROM Overall) OR O.overallSales = (SELECT MAX(overallSales) FROM Overall);

/*
result:
 store | overallsales
-------+--------------
    33 |  3.71603e+07
    20 |  3.01397e+08
(2 rows)
*/