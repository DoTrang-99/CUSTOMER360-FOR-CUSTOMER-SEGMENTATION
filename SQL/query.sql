--Calculate Frequency, Recency, Monetary
SELECT
CustomerID ,
DATEDIFF(Day, MAX(cast(Purchase_date as DATE)), '2022-09-01') as 'Recency',
ROUND(COUNT(DISTINCT(Cast(Purchase_Date as DATE)))/
CAST(datediff(YEAR, MIN(Cast(created_date as DATE)), '2022-09-01') as Float), 2) as
'Frequency',
SUM(GMV) as 'Monetary',
ROW_NUMBER () OVER (
ORDER BY
DATEDIFF(DAY, MAX(Purchase_Date), '2022-09-01')) AS rn_R,
ROW_NUMBER () OVER (
ORDER BY
ROUND(COUNT(DISTINCT(Cast(Purchase_Date as DATE)))/
CAST(datediff(YEAR, MIN(Cast(created_date as DATE)), '2022-09-01') as Float), 2)) AS
rn_F,
ROW_NUMBER () OVER (
ORDER BY
SUM(GMV)) AS rn_M
INTO #Calc
FROM
Customer_Transaction ct
JOIN Customer_Registered cr ON
ct.CustomerID = cr.ID
WHERE
ct.CustomerID <> 0
GROUP BY
ct.CustomerID, cr.created_date
--Calculate RFM Point
SELECT
*,
Case
When Recency < (SELECT Recency FROM #Calc WHERE (rn_R = (SELECT
CAST(COUNT(DISTINCT(rn_R))*0.25 AS INT) FROM #Calc)))
AND Recency >= (SELECT Recency FROM #Calc WHERE rn_R = 1)
THEN '4'
When Recency >= (SELECT Recency From #Calc WHERE (rn_R = (SELECT
CAST(COUNT(DISTINCT(rn_R))*0.25 AS INT) FROM #Calc)))
AND Recency < (SELECT Recency From #Calc WHERE (rn_R = (SELECT
CAST(COUNT(DISTINCT(rn_R))*0.5 AS INT) FROM #Calc)))
THEN '3'
When Recency >= (SELECT Recency From #Calc WHERE (rn_R = (SELECT
CAST(COUNT(DISTINCT(rn_R))*0.5 AS INT) FROM #Calc)))
AND Recency < (SELECT Recency From #Calc WHERE (rn_R = (SELECT
CAST(COUNT(DISTINCT(rn_R))*0.75 AS INT) FROM #Calc)))
THEN '2'
ELSE '1' END AS R,
Case
When Frequency < (SELECT Frequency FROM #Calc WHERE (rn_F = (SELECT
CAST(COUNT(DISTINCT(rn_F))*0.25 AS INT) FROM #Calc)))
AND Frequency >= (SELECT Frequency FROM #Calc WHERE rn_F = 1)
THEN '1'
When Frequency >= (SELECT Frequency From #Calc WHERE (rn_F = (SELECT
CAST(COUNT(DISTINCT(rn_F))*0.25 AS INT) FROM #Calc)))
AND Frequency < (SELECT Frequency From #Calc WHERE (rn_F = (SELECT
CAST(COUNT(DISTINCT(rn_F))*0.5 AS INT) FROM #Calc)))
THEN '2'
When Frequency >= (SELECT Frequency From #Calc WHERE (rn_F = (SELECT
CAST(COUNT(DISTINCT(rn_F))*0.5 AS INT) FROM #Calc)))
AND Frequency < (SELECT Frequency From #Calc WHERE (rn_F = (SELECT
CAST(COUNT(DISTINCT(rn_F))*0.75 AS INT) FROM #Calc)))
THEN '3'
ELSE '4' END AS F,
Case
When Monetary < (SELECT Monetary FROM #Calc WHERE (rn_M = (SELECT
CAST(COUNT(DISTINCT(rn_M))*0.25 AS INT) FROM #Calc)))
AND Monetary >= (SELECT Monetary FROM #Calc WHERE rn_M = 1)
THEN '1'
When Monetary >= (SELECT Monetary From #Calc WHERE (rn_M = (SELECT
CAST(COUNT(DISTINCT(rn_M))*0.25 AS INT) FROM #Calc)))
AND Monetary < (SELECT Monetary From #Calc WHERE (rn_M = (SELECT
CAST(COUNT(DISTINCT(rn_M))*0.5 AS INT) FROM #Calc)))
THEN '2'
When Monetary >= (SELECT Monetary From #Calc WHERE (rn_M = (SELECT
CAST(COUNT(DISTINCT(rn_M))*0.5 AS INT) FROM #Calc)))
AND Monetary < (SELECT Monetary From #Calc WHERE (rn_M = (SELECT
CAST(COUNT(DISTINCT(rn_M))*0.75 AS INT) FROM #Calc)))
THEN '3'
ELSE '4' END AS M
INTO #RFM_Calc
FROM #Calc
SELECT CustomerID, Recency, Frequency, Monetary, R, F, M FROM #RFM_Calc
--Mapping Customer Groups
SELECT CONCAT(R,F,M) as "RFM",
CASE
WHEN (R >= 3 AND F >= 3 AND M >= 3) THEN 'Superriors Loyalists'
WHEN (R >= 3 AND F >= 3 AND M < 3) THEN 'Potential Loyalists'
WHEN (R >= 3 AND F < 3 AND M >= 3) THEN 'Responsive'
WHEN (R >= 3 AND F < 3 AND M < 3) THEN 'Promising'
WHEN (R < 3 AND F >= 3 AND M >= 3) THEN 'Hibernating Loyalists'
WHEN (R < 3 AND F < 3 AND M >= 3) THEN 'Need Attention'
WHEN (R < 3 AND F >= 3 AND M < 3) THEN 'About to Sleep'
ELSE 'At Risk'
END AS RFM_Segment, COUNT(*) as "Total_clients"
FROM #RFM_Calc
GROUP BY CONCAT(R,F,M), R, F, M
SELECT R, COUNT(*) as "Total_Clients"
FROM #RFM_calc
Group by R
SELECT F, COUNT(*) as "Total_Clients"
FROM #RFM_calc
Group by F
SELECT M, COUNT(*) as "Total_Clients"
FROM #RFM_calc
Group by M