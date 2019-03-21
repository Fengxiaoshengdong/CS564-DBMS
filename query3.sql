3. How many non-holiday weeks had larger sales than the overall average sales during holiday weeks?
WITH nonholidaySales(WeekDate, sumSale) 
AS 
	(SELECT S.WeekDate, SUM(WeeklySales) AS "sum"
	FROM Sales S, Holidays H
	WHERE S.WeekDate = H.WeekDate  
		AND H.IsHoliday = 'f'
	GROUP BY S.WeekDate
	),
holidaySales(WeekDate, sumSale) 
AS 
	(SELECT S.WeekDate, SUM(WeeklySales) AS "sum"
	FROM Sales S, Holidays H
	WHERE S.WeekDate = H.WeekDate  
		AND H.IsHoliday = 't'
	GROUP BY S.WeekDate
	)
SELECT COUNT(DISTINCT N.WeekDate)
FROM nonholidaySales N
WHERE N.sumSale >  (SELECT AVG(sumSale) 
					FROM holidaySales S2);