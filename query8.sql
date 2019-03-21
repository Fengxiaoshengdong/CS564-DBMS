8. Get the top 10 departments overall ranked by total sales normalized by the size of the store where the sales were recorded.
SELECT Sa.dept, SUM(Sa.WeeklySales/St.size) AS totalNormSale 
FROM Sales Sa, Stores St
WHERE Sa.store = St.store
GROUP BY dept
ORDER BY SUM(Sa.WeeklySales/St.size) DESC
LIMIT 10;
