WITH 
MONTH_SALE(WeeklySales, type, month) 
AS 
	(SELECT sa.WeeklySales, st.type, SUBSTRING(CAST(WeekDate AS varchar(10)),6,2) AS month
	FROM Sales sa, Stores st
	WHERE sa.Store = st.Store
	),
MONTH_SALE_SUM 
AS 
	(SELECT month, type, SUM(WeeklySales) AS MONTH_SUM
	FROM MONTH_SALE
	GROUP BY month, type
	ORDER BY type, month
	)
SELECT CASE month
		WHEN '01' THEN 'Jan'
		WHEN '02' THEN 'Feb'
		WHEN '03' THEN 'Mar'
		WHEN '04' THEN 'Apr'
		WHEN '05' THEN 'May'
		WHEN '06' THEN 'Jun'
		WHEN '07' THEN 'Jul'
		WHEN '08' THEN 'Aug'
		WHEN '09' THEN 'Sep'
		WHEN '10' THEN 'Oct'
		WHEN '11' THEN 'Nov'
		WHEN '12' THEN 'Dec'
	END months, 
	type, MONTH_SUM, MONTH_SUM * 100/SUM(MONTH_SUM) OVER(PARTITION BY type) "% contribution"
FROM MONTH_SALE_SUM;

/*
result:
 months | type |  month_sum  |  % contribution
--------+------+-------------+------------------
 Jan    | A    | 2.14176e+08 | 4.94517291870296
 Feb    | A    | 3.66506e+08 | 8.46237778111938
 Mar    | A    | 3.80773e+08 |  8.7917834357331
 Apr    | A    | 4.16181e+08 | 9.60933018828221
 May    | A    | 3.59085e+08 | 8.29102708191177
 Jun    | A    | 3.99448e+08 | 9.22297486205232
 Jul    | A    | 4.17243e+08 | 9.63384622468555
 Aug    | A    | 3.94862e+08 | 9.11709212455745
 Sep    | A    | 3.73119e+08 |  8.6150486806721
 Oct    | A    | 3.77133e+08 | 8.70773098700509
 Nov    | A    | 2.64721e+08 | 6.11222225453493
 Dec    | A    | 3.67763e+08 | 8.49139641617382
 Jan    | B    | 9.54465e+07 | 4.77065330033624
 Feb    | B    | 1.67672e+08 | 8.38064557631928
 Mar    | B    | 1.75136e+08 | 8.75374780844694
 Apr    | B    |  1.9088e+08 |  9.5406732223245
 May    | B    | 1.63456e+08 | 8.16993291563631
 Jun    | B    | 1.86362e+08 | 9.31483945330364
 Jul    | B    | 1.93743e+08 | 9.68378314072234
 Aug    | B    | 1.81505e+08 | 9.07205641571321
 Sep    | B    | 1.68954e+08 |  8.4447511424482
 Oct    | B    | 1.70604e+08 | 8.52721508402692
 Nov    | B    | 1.25546e+08 | 6.27508562123668
 Dec    | B    | 1.81396e+08 | 9.06661032158474
 Jan    | C    | 2.29758e+07 |  5.6660036682519
 Feb    | C    | 3.45485e+07 | 8.51990249981534
 Mar    | C    | 3.68753e+07 | 9.09371888804082
 Apr    | C    | 3.97991e+07 | 9.81473213017449
 May    | C    | 3.45833e+07 | 8.52850119823459
 Jun    | C    | 3.68194e+07 | 9.07992466999622
 Jul    | C    | 3.90144e+07 | 9.62123922109701
 Aug    | C    | 3.67215e+07 | 9.05578380198952
 Sep    | C    | 3.66885e+07 | 9.04765661645824
 Oct    | C    | 3.70491e+07 | 9.13656145655579
 Nov    | C    | 2.27486e+07 | 5.60997550816068
 Dec    | C    | 2.76796e+07 | 6.82599886158244
(36 rows)
*/