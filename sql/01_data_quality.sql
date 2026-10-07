/* ============================================================
   01_data_quality.sql — Data quality checks (Analytics 27–28)
   Database: AdventureWorksDW2025 — set it in the
             SSMS database dropdown before running.
   Run this file FIRST, before any analysis.
   ============================================================ */

-- 0. Row counts: how big are the fact tables?
SELECT 'FactInternetSales'  AS TableName, COUNT(*) AS RowsCnt FROM dbo.FactInternetSales
UNION ALL
SELECT 'FactResellerSales', COUNT(*) FROM dbo.FactResellerSales
UNION ALL
SELECT 'FactSalesQuota',    COUNT(*) FROM dbo.FactSalesQuota
UNION ALL
SELECT 'FactProductInventory', COUNT(*) FROM dbo.FactProductInventory;
GO

/* ------------------------------------------------------------
   27. NULL audit on key columns.
   A NULL in a join key silently drops rows from INNER JOINs —
   so audit the keys before trusting any downstream number.
   ------------------------------------------------------------ */
SELECT 'FactInternetSales' AS TableName,
       COUNT(*) AS TotalRows,
       SUM(CASE WHEN CustomerKey  IS NULL THEN 1 ELSE 0 END) AS NullCustomerKey,
       SUM(CASE WHEN ProductKey   IS NULL THEN 1 ELSE 0 END) AS NullProductKey,
       SUM(CASE WHEN OrderDateKey IS NULL THEN 1 ELSE 0 END) AS NullOrderDateKey,
       CAST(100.0 * SUM(CASE WHEN CustomerKey IS NULL
                             OR ProductKey   IS NULL
                             OR OrderDateKey IS NULL THEN 1 ELSE 0 END)
            / COUNT(*) AS DECIMAL(5,2)) AS PctRowsWithNullKey
FROM dbo.FactInternetSales;
GO

SELECT 'FactResellerSales' AS TableName,
       COUNT(*) AS TotalRows,
       SUM(CASE WHEN CustomerKey  IS NULL THEN 1 ELSE 0 END) AS NullCustomerKey,
       SUM(CASE WHEN ProductKey   IS NULL THEN 1 ELSE 0 END) AS NullProductKey,
       SUM(CASE WHEN OrderDateKey IS NULL THEN 1 ELSE 0 END) AS NullOrderDateKey,
       SUM(CASE WHEN EmployeeKey  IS NULL THEN 1 ELSE 0 END) AS NullEmployeeKey
FROM dbo.FactResellerSales;
GO

/* ------------------------------------------------------------
   28. Duplicate / grain check on orders.
   NOTE: SalesOrderNumber is NOT unique — one order has many
   line items. The true grain is (SalesOrderNumber, SalesOrderLineNumber).
   This check proves we understood the grain instead of
   "finding duplicates" that aren't real.
   ------------------------------------------------------------ */
-- Distinct orders vs fact rows: the gap = multi-line orders (expected)
SELECT COUNT(*)                            AS FactRows,
       COUNT(DISTINCT SalesOrderNumber)    AS DistinctOrders,
       COUNT(*) - COUNT(DISTINCT SalesOrderNumber) AS ExtraLineItems
FROM dbo.FactInternetSales;
GO

-- True duplicates: same order + same line number appearing twice
SELECT SalesOrderNumber, SalesOrderLineNumber, COUNT(*) AS DupCount
FROM dbo.FactInternetSales
GROUP BY SalesOrderNumber, SalesOrderLineNumber
HAVING COUNT(*) > 1;
GO

/* ------------------------------------------------------------
   Bonus: orphan foreign keys — fact rows whose dimension
   lookup is missing. Any count > 0 means joins will lose rows.
   ------------------------------------------------------------ */
SELECT 'ProductKey' AS BrokenKey, COUNT(*) AS OrphanRows
FROM dbo.FactInternetSales f
LEFT JOIN dbo.DimProduct p ON p.ProductKey = f.ProductKey
WHERE p.ProductKey IS NULL
UNION ALL
SELECT 'CustomerKey', COUNT(*)
FROM dbo.FactInternetSales f
LEFT JOIN dbo.DimCustomer c ON c.CustomerKey = f.CustomerKey
WHERE c.CustomerKey IS NULL
UNION ALL
SELECT 'OrderDateKey', COUNT(*)
FROM dbo.FactInternetSales f
LEFT JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
WHERE d.DateKey IS NULL;
GO
