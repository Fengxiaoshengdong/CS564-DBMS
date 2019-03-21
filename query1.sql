1. Which stores had the largest and smallest overall sales during holiday weeks?
WITH holidaySale (Store, overallSales) 
AS (
	SELECT Store, SUM(WeeklySales) AS overallSales 
	FROM Sales S, holiday H 
	WHERE S.weekDate = H.weekDate 
		AND H.isHoliday = 'T'
	GROUP BY S.Store)
SELECT O.Store, O.overallSales
FROM holidaySale O
WHERE O.overallSales = (SELECT MIN(overallSales) FROM holidaySale) 
	OR O.overallSales = (SELECT MAX(overallSales) FROM holidaySale);