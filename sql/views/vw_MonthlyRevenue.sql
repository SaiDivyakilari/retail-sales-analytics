/* ============================================================
   vw_MonthlyRevenue.sql — monthly revenue + growth metrics
   Database: AdventureWorksDW2025.
   Re-runnable: CREATE OR ALTER keeps it idempotent.
   ============================================================ */
CREATE OR ALTER VIEW dbo.vw_MonthlyRevenue AS
WITH Monthly AS (
    SELECT d.CalendarYear,
           d.MonthNumberOfYear AS MonthNum,
           MAX(d.EnglishMonthName) AS MonthName,  -- one name per (year, month)
           SUM(f.SalesAmount)  AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
    GROUP BY d.CalendarYear, d.MonthNumberOfYear
)
SELECT CalendarYear,
       MonthNum,
       MonthName,
       Revenue,
       LAG(Revenue) OVER (ORDER BY CalendarYear, MonthNum)
           AS PrevMonthRevenue,
       CAST(100.0 * (Revenue - LAG(Revenue) OVER (ORDER BY CalendarYear, MonthNum))
            / NULLIF(LAG(Revenue) OVER (ORDER BY CalendarYear, MonthNum), 0)
            AS DECIMAL(6,2)) AS MoMGrowthPct,
       LAG(Revenue, 12) OVER (ORDER BY CalendarYear, MonthNum)
           AS SameMonthLastYear,
       CAST(100.0 * (Revenue - LAG(Revenue, 12) OVER (ORDER BY CalendarYear, MonthNum))
            / NULLIF(LAG(Revenue, 12) OVER (ORDER BY CalendarYear, MonthNum), 0)
            AS DECIMAL(6,2)) AS YoYGrowthPct,
       SUM(Revenue) OVER (ORDER BY CalendarYear, MonthNum
                          ROWS UNBOUNDED PRECEDING) AS RunningTotal,
       CAST(AVG(CAST(Revenue AS DECIMAL(14,2))) OVER (
              ORDER BY CalendarYear, MonthNum
              ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
            AS DECIMAL(14,2)) AS MovingAvg3M
FROM Monthly;
GO

-- Smoke test:
-- SELECT TOP 12 * FROM dbo.vw_MonthlyRevenue ORDER BY CalendarYear, MonthNum;
