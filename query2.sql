2.Get the stores at locations where the unemployment rate exceeded 10% at least once but the fuel price never exceeded 4.
SELECT DISTINCT Store 
FROM Stores S
WHERE S.Store IN (
		SELECT Store FROM TemporalData WHERE UnemploymentRate > 10) 
	AND S.Store NOT IN (
		SELECT Store FROM TemporalData WHERE FuelPrice > 4);