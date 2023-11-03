-- validasi CT1
select AVG(Lead_time) as [Rata-rata cycle time] 
from Sales_ETANA
where Transaction_date LIKE '2022-04-%';

SELECT AVG(Lead_time) as [Rata-rata cycle time]
FROM Sales_ETANA
WHERE Transaction_date = (SELECT MAX(Transaction_date) FROM Sales_ETANA);

-- validasi net profit
ALTER TABLE Sales_ETANA
ALTER COLUMN Net_Profit BIGINT;

select SUM(Net_Profit) as [Jumlah Net Profit Q1 2022]
from Sales_ETANA
where Transaction_date >= '2022-01-01' AND Transaction_date <= '2022-03-31';

select SUM(Net_Profit) as [Jumlah Net Profit Q1 2022]
from Sales_ETANA
WHERE Transaction_date = (SELECT MAX(Transaction_date) FROM Sales_ETANA);

-- validasi gross profit
select SUM(Gross_Profit) as [Jumlah Gross Profit Januari 2022]
from Sales_ETANA
where Transaction_date >= '2022-01-01' AND Transaction_date <= '2022-01-31';

select SUM(Gross_Profit) as [Jumlah Gross Profit saat ini]
from Sales_ETANA
where Transaction_date = (SELECT MAX(Transaction_date) FROM Sales_ETANA);

-- validasi Net sales contribution based on geographic NS-C1
WITH TotalSales AS (
    SELECT SUM(Net_Sales) AS TotalNetSales
    FROM Sales_ETANA)
SELECT Branch, SUM(Net_Sales) AS BranchSales,
       (SUM(Net_Sales) * 100.0 / TotalSales.TotalNetSales) AS Percentage
FROM Sales_ETANA
CROSS JOIN TotalSales
GROUP BY Branch, TotalSales.TotalNetSales
ORDER BY BranchSales DESC;

-- validasi Net sales contribution based on product NS-C2
ALTER TABLE Sales_ETANA
ALTER COLUMN Net_Sales BIGINT;

WITH TotalSales AS (
    SELECT SUM(Net_Sales) AS TotalNetSales
    FROM Sales_ETANA)
SELECT Sub_Product, SUM(Net_Sales) AS SubProductSales,
       (SUM(Net_Sales) * 100.0 / TotalSales.TotalNetSales) AS Percentage
FROM Sales_ETANA
CROSS JOIN TotalSales
GROUP BY Sub_Product, TotalSales.TotalNetSales
ORDER BY SubProductSales DESC;

-- validasi available stock unit
select Branch, SUM(Available_stock_qty) as [Jumlah Unit Stok]
from Stock_Etana
group by Branch
order by [Jumlah Unit Stok] desc;

-- validasi available stock value
ALTER TABLE Stock_Etana
ALTER COLUMN Available_stock_value BIGINT;

select Branch, SUM(Available_stock_value) as [Jumlah Value Stok]
from Stock_Etana
group by Branch
order by [Jumlah Value Stok] desc;

-- validasi available % repeat customer
WITH CustomerTransactionCounts AS (
    SELECT Customer_Name, COUNT(Customer_Name) AS TransactionCount
    FROM Sales_ETANA
    WHERE Transaction_date >= '2022-01-01' AND Transaction_date <= '2022-12-31'
    GROUP BY Customer_Name
)
SELECT 
    COUNT(CASE WHEN TransactionCount > 1 THEN 1 END) AS CustomersWithMoreThanOneTransaction,
    COUNT(*) AS TotalCustomersInQuarter1,
    (COUNT(CASE WHEN TransactionCount > 1 THEN 1 END) * 100.0 / COUNT(*)) AS Percentage
FROM CustomerTransactionCounts;

-- validasi available % net sales repeat customer
WITH CustomerTransactionCounts AS (
    SELECT Customer_Name, SUM(Net_Sales) AS TotalNetSales, COUNT(Customer_Name) AS TransactionCount
    FROM Sales_ETANA
    WHERE Transaction_date >= '2022-01-01' AND Transaction_date <= '2022-12-31'
    GROUP BY Customer_Name
    HAVING COUNT(Customer_Name) > 1
),
GrandTotalNetSales AS (
    SELECT SUM(Net_Sales) AS TotalNetSales 
    FROM Sales_ETANA
    WHERE Transaction_date >= '2022-01-01' AND Transaction_date <= '2022-12-31'
)
SELECT
    (SELECT SUM(TotalNetSales) FROM CustomerTransactionCounts) AS TotalNetSalesRepeatCustomer,
    (SELECT TotalNetSales FROM GrandTotalNetSales) AS TotalNetSales
	((SELECT SUM(TotalNetSales) FROM CustomerTransactionCounts)/(SELECT TotalNetSales FROM GrandTotalNetSales))*100 AS [% Net Sales Contribution];

WITH CustomerTransactionCounts AS (
    SELECT Customer_Name, SUM(Net_Sales) AS TotalNetSales, COUNT(Customer_Name) AS TransactionCount
    FROM Sales_ETANA
    WHERE Transaction_date >= '2022-01-01' AND Transaction_date <= '2022-12-31'
    GROUP BY Customer_Name
    HAVING COUNT(Customer_Name) > 1
),
GrandTotalNetSales AS (
    SELECT SUM(CAST(Net_Sales as float)) AS TotalNetSales 
    FROM Sales_ETANA
    WHERE Transaction_date >= '2022-01-01' AND Transaction_date <= '2022-12-31'
)
SELECT
    (SELECT SUM(TotalNetSales) FROM CustomerTransactionCounts) AS TotalNetSalesRepeatCustomer,
    (SELECT TotalNetSales FROM GrandTotalNetSales) AS TotalNetSales,
    ((SELECT SUM(CAST(TotalNetSales as float)) FROM CustomerTransactionCounts)/(SELECT TotalNetSales FROM GrandTotalNetSales))*100 AS [% Net Sales Contribution];

-- Sales value by employee
SELECT SE.Sales_person, RDP.EMPLOYEE_NAME, SUM(Net_Sales) AS SalesValueEmployee
FROM Sales_ETANA SE
LEFT JOIN [Raw Data Pekerja] RDP ON SE.Sales_person = RDP.EMPLOYEE_CODE
GROUP BY Sales_person, EMPLOYEE_NAME
ORDER BY SUM(Net_Sales) DESC;

-- net profit by employee
SELECT SE.Sales_person, RDP.EMPLOYEE_NAME, SUM(Net_Profit) AS ProfitEmployee
FROM Sales_ETANA SE
LEFT JOIN [Raw Data Pekerja] RDP ON SE.Sales_person = RDP.EMPLOYEE_CODE
GROUP BY Sales_person, EMPLOYEE_NAME
ORDER BY SUM(Net_Profit) DESC;

-- sales volume by employee
SELECT SE.Sales_person, RDP.EMPLOYEE_NAME, SUM(Sales_unit) AS SalesVolumeEmployee
FROM Sales_ETANA SE
LEFT JOIN [Raw Data Pekerja] RDP ON SE.Sales_person = RDP.EMPLOYEE_CODE
GROUP BY Sales_person, EMPLOYEE_NAME
ORDER BY SUM(Sales_unit) DESC;

-- Inventory turnover ITO
WITH SalesCTE AS (
    SELECT 
		Branch,
        AVG(CAST(Net_Sales as float)) AS AverageNetSales
    FROM Sales_ETANA
    GROUP BY Branch 
),
StockCTE AS (
    SELECT 
		Branch,
        AVG(CAST(Available_Stock_value as float)) AS AverageInventory
    FROM Stock_Etana
    GROUP BY Branch 
)
SELECT 
    S.Branch,
    S.AverageNetSales,
    I.AverageInventory,
    CAST(S.AverageNetSales as float) / CAST(I.AverageInventory as float) AS [Inventory Turnover]
FROM SalesCTE S
LEFT JOIN StockCTE I ON S.Branch = I.Branch
GROUP BY  S.Branch,  S.AverageNetSales, I.AverageInventory
ORDER BY   CAST(S.AverageNetSales as float) / CAST(I.AverageInventory as float) desc;

-- Total Days of Inventory TDI
WITH SalesUnit AS (
    SELECT
        Branch, 
        AVG(CAST(Sales_Unit as float)) as [Rata-rata unit terjual]
    FROM Sales_ETANA
    GROUP BY Branch
),
StockUnit AS (
    SELECT 
        Branch,
        AVG(CAST(Available_stock_qty as float)) as [Rata-rata unit tersedia]
    FROM Stock_Etana
    GROUP BY Branch
)
SELECT 
    SaU.Branch,
    SaU.[Rata-rata unit terjual],
    StU.[Rata-rata unit tersedia],
    (SaU.[Rata-rata unit terjual] / StU.[Rata-rata unit tersedia])*30 as [Total Days of Inventory]
FROM SalesUnit SaU
LEFT JOIN StockUnit StU ON SaU.Branch = StU.Branch
ORDER BY [Total Days of Inventory] desc;

-- Rate of obsoleted inventory ROI
ALTER TABLE Stock_Etana
ALTER COLUMN Value_obsoleted BIGINT;

WITH StockSummary AS (
    SELECT 
        DATEADD(MONTH, DATEDIFF(MONTH, 0, Date_Updated), 0) AS MonthUpdated,
        SUM(Value_obsoleted) AS [Jumlah Nilai Stock Obsolete],
        AVG(Available_stock_value) AS [Rata-rata stok tersedia]
    FROM Stock_Etana 
    GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, Date_Updated), 0)
)
SELECT 
    MonthUpdated,
    [Jumlah Nilai Stock Obsolete],
    [Rata-rata stok tersedia],
    (CAST([Jumlah Nilai Stock Obsolete] as float) / CAST([Rata-rata stok tersedia]as float)) AS rate
FROM StockSummary
ORDER BY MonthUpdated;

-- Forecast accuracy FA
SELECT 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, Transaction_date), 0) AS TransactionMonth,
    SUM(CAST(Sales_Unit as float)) AS Sales_Unit,
    SUM(CAST(Forecasted_Sales_unit as float)) AS Forecasted_Sales_unit,
    ABS(SUM(CAST(Sales_Unit as float)) - SUM(CAST(Forecasted_Sales_unit as float))) /(SUM(CAST(Sales_Unit as float))) * 100 AS MAPE
FROM Sales_ETANA
GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, Transaction_date), 0)
ORDER BY DATEADD(MONTH, DATEDIFF(MONTH, 0, Transaction_date), 0);