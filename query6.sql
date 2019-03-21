6. For each of the 4 numeric attributes in TemporalData, are they positively or negatively correlated with sales and how strong is the correlation? Your SQL query should output an
instance with the following schema with 4 rows: Output6 (AttributeName VARCHAR(20), CorrSign char(1), CorrValue (float))


WITH summary(temp, fuelprice, cpi, unemp, WeekSale) 
AS
	(SELECT T.temperature, T.fuelprice, T.cpi, T.unemploymentrate, S.WeeklySales
	FROM TemporalData T, Sales S
	WHERE T.WeekDate = S.WeekDate AND T.Store = S.Store
	)

(SELECT 'Temperature' as attribute,
		CASE 
		WHEN (CORR(s.temp, s.WeekSale)) > 0 THEN '+'
		WHEN (CORR(s.temp, s.WeekSale)) < 0 THEN '-'
		ELSE '0' END
		AS corr_sign,
		CORR(s.temp, s.WeekSale) AS correlation
		FROM summary s)
UNION 

(SELECT 'FuelPrice' as attribute,
		CASE 
		WHEN (CORR(s.fuelprice, s.WeekSale)) > 0 THEN '+'
		WHEN (CORR(s.fuelprice, s.WeekSale)) < 0 THEN '-'
		ELSE '0' END
		AS corr_sign,
		CORR(s.fuelprice, s.WeekSale) AS correlation
		FROM summary s)
UNION 

(SELECT 'CPI' as attribute,
		CASE 
		WHEN (CORR(s.cpi, s.WeekSale)) > 0 THEN '+'
		WHEN (CORR(s.cpi, s.WeekSale)) < 0 THEN '-'
		ELSE '0' END
		AS corr_sign,
		CORR(s.cpi, s.WeekSale) AS correlation
		FROM summary s)

UNION 

(SELECT 'UnemploymentRate' as attribute,
		CASE 
		WHEN (CORR(s.unemp, s.WeekSale)) > 0 THEN '+'
		WHEN (CORR(s.unemp, s.WeekSale)) < 0 THEN '-'
		ELSE '0' END
		AS corr_sign,
		CORR(s.unemp, s.WeekSale) AS correlation
		FROM summary s);