SELECT Sa.dept, SUM(Sa.WeeklySales/St.size) AS totalNormSale 
FROM Sales Sa, Stores St
WHERE Sa.store = St.store
GROUP BY dept
ORDER BY SUM(Sa.WeeklySales/St.size) DESC
LIMIT 10;

/*
result:
 dept |  totalnormsale
------+------------------
   92 | 4128.35283184452
   38 | 4080.21098287073
   95 |  3879.8351126117
   90 | 2567.52589305854
   40 | 2400.34807233329
    2 | 2232.72935979053
   72 | 2191.77409403543
   91 | 1791.72819385294
   94 | 1747.77832661447
   13 | 1620.50955989047
(10 rows)
*/