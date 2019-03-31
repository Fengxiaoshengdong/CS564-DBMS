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

/*
result:
    attribute     | corr_sign |      correlation
------------------+-----------+-----------------------
 UnemploymentRate | -         |   -0.0258637151104456
 Temperature      | -         |  -0.00231244659998809
 FuelPrice        | -         | -0.000120295860528548
 CPI              | -         |   -0.0209213356051743
 */