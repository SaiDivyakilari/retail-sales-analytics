/* ============================================================
   02_sales_performance.sql — Sales performance (Analytics 1–7)
   Database: AdventureWorksDW2025.
   Business lens: how revenue trends over time, by channel.
   ============================================================ */

/* ------------------------------------------------------------
   1. Annual revenue summary — revenue, orders, units per year
   ------------------------------------------------------------ */
SELECT d.CalendarYear,
       SUM(f.SalesAmount)                    AS TotalRevenue,
       COUNT(DISTINCT f.SalesOrderNumber)    AS Orders,
       COUNT(*)                              AS OrderLines,
       SUM(f.OrderQuantity)                  AS UnitsSold,
       CAST(SUM(f.SalesAmount)
            / NULLIF(COUNT(DISTINCT f.SalesOrderNumber), 0)
            AS DECIMAL(12,2))                AS AvgOrderValue
FROM dbo.FactInternetSales f
JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
GROUP BY d.CalendarYear
ORDER BY d.CalendarYear;
GO

/* ------------------------------------------------------------
   2. Monthly revenue trend
   ------------------------------------------------------------ */
SELECT d.CalendarYear,
       d.MonthNumberOfYear                   AS MonthNum,
       d.EnglishMonthName                    AS MonthName,
       SUM(f.SalesAmount)                    AS Revenue,
       COUNT(DISTINCT f.SalesOrderNumber)    AS Orders
FROM dbo.FactInternetSales f
JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
GROUP BY d.CalendarYear, d.MonthNumberOfYear, d.EnglishMonthName
ORDER BY d.CalendarYear, d.MonthNumberOfYear;
GO

/* ------------------------------------------------------------
   3. Month-over-month growth % — which months accelerated?
   ------------------------------------------------------------ */
WITH Monthly AS (
    SELECT d.CalendarYear,
           d.MonthNumberOfYear AS MonthNum,
           SUM(f.SalesAmount)  AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
    GROUP BY d.CalendarYear, d.MonthNumberOfYear
)
SELECT CalendarYear, MonthNum, Revenue,
       LAG(Revenue) OVER (ORDER BY CalendarYear, MonthNum) AS PrevMonthRevenue,
       CAST(100.0 * (Revenue - LAG(Revenue) OVER (ORDER BY CalendarYear, MonthNum))
            / NULLIF(LAG(Revenue) OVER (ORDER BY CalendarYear, MonthNum), 0)
            AS DECIMAL(6,2)) AS MoMGrowthPct
FROM Monthly
ORDER BY CalendarYear, MonthNum;
GO

/* ------------------------------------------------------------
   4. Year-over-year growth by month — same month, prior year
   ------------------------------------------------------------ */
WITH Monthly AS (
    SELECT d.CalendarYear,
           d.MonthNumberOfYear AS MonthNum,
           SUM(f.SalesAmount)  AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
    GROUP BY d.CalendarYear, d.MonthNumberOfYear
)
SELECT CalendarYear, MonthNum, Revenue,
       LAG(Revenue, 12) OVER (ORDER BY CalendarYear, MonthNum) AS SameMonthLastYear,
       CAST(100.0 * (Revenue - LAG(Revenue, 12) OVER (ORDER BY CalendarYear, MonthNum))
            / NULLIF(LAG(Revenue, 12) OVER (ORDER BY CalendarYear, MonthNum), 0)
            AS DECIMAL(6,2)) AS YoYGrowthPct
FROM Monthly
ORDER BY CalendarYear, MonthNum;
GO

/* ------------------------------------------------------------
   5. Running total of revenue — the cumulative curve
   ------------------------------------------------------------ */
WITH Monthly AS (
    SELECT d.CalendarYear,
           d.MonthNumberOfYear AS MonthNum,
           SUM(f.SalesAmount)  AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
    GROUP BY d.CalendarYear, d.MonthNumberOfYear
)
SELECT CalendarYear, MonthNum, Revenue,
       SUM(Revenue) OVER (ORDER BY CalendarYear, MonthNum
                          ROWS UNBOUNDED PRECEDING) AS RunningTotal
FROM Monthly
ORDER BY CalendarYear, MonthNum;
GO

/* ------------------------------------------------------------
   6. Three-month moving average — trend without monthly noise
   ------------------------------------------------------------ */
WITH Monthly AS (
    SELECT d.CalendarYear,
           d.MonthNumberOfYear AS MonthNum,
           SUM(f.SalesAmount)  AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
    GROUP BY d.CalendarYear, d.MonthNumberOfYear
)
SELECT CalendarYear, MonthNum, Revenue,
       CAST(AVG(CAST(Revenue AS DECIMAL(14,2))) OVER (
              ORDER BY CalendarYear, MonthNum
              ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
            AS DECIMAL(14,2)) AS MovingAvg3M
FROM Monthly
ORDER BY CalendarYear, MonthNum;
GO

/* ------------------------------------------------------------
   7. Internet vs reseller channel comparison —
   which channel drives revenue, and how has the mix shifted?
   ------------------------------------------------------------ */
WITH ChannelSales AS (
    SELECT d.CalendarYear, 'Internet' AS Channel, f.SalesAmount
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
    UNION ALL
    SELECT d.CalendarYear, 'Reseller', f.SalesAmount
    FROM dbo.FactResellerSales f
    JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
)
SELECT CalendarYear, Channel,
       SUM(SalesAmount) AS Revenue,
       CAST(100.0 * SUM(SalesAmount)
            / SUM(SUM(SalesAmount)) OVER (PARTITION BY CalendarYear)
            AS DECIMAL(5,2)) AS ChannelSharePct
FROM ChannelSales
GROUP BY CalendarYear, Channel
ORDER BY CalendarYear, Channel;
GO
