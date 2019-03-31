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

/*
result:
 count
-------
     8
(1 row)
*/