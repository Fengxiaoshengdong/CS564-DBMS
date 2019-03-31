SELECT DISTINCT Store 
FROM Stores S
WHERE S.Store IN (
		SELECT Store FROM TemporalData WHERE UnemploymentRate > 10) 
	AND S.Store NOT IN (
		SELECT Store FROM TemporalData WHERE FuelPrice > 4);

/*
result:
 store
-------
    34
    43
(2 rows)
*/