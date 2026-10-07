# T-SQL Primer — Retail Sales Analytics Project

You already know window functions, stored procedures, and functions conceptually.
This is just the SQL Server dialect. Every example below runs against `AdventureWorksDW2025`.

## 1. SELECT basics

```sql
-- TOP n instead of LIMIT
SELECT TOP 10 EnglishProductName, ListPrice
FROM dbo.DimProduct
ORDER BY ListPrice DESC;

-- dbo. schema prefix is convention; brackets only needed for spaces/reserved words
SELECT [EnglishProductName] FROM dbo.DimProduct;
```

## 2. Dates

```sql
SELECT GETDATE();                    -- current datetime
SELECT CAST(GETDATE() AS DATE);      -- just the date
SELECT DATEADD(year, -1, GETDATE()); -- one year ago
SELECT DATEDIFF(day, '2021-01-01', GETDATE());  -- days between
SELECT EOMONTH(GETDATE());           -- last day of current month
SELECT YEAR(FullDateAlternateKey), MONTH(FullDateAlternateKey)
FROM dbo.DimDate;
```

Note: facts join to `DimDate` on the integer `DateKey`; the actual date column is
`FullDateAlternateKey` (type `date`).

## 3. NULL handling

```sql
SELECT ISNULL(Color, 'Unknown') FROM dbo.DimProduct;   -- T-SQL specific, 2 args only
SELECT COALESCE(Color, Size, 'Unknown') FROM dbo.DimProduct;  -- standard, works too
```

## 4. Strings

```sql
SELECT FirstName + ' ' + LastName FROM dbo.DimCustomer;  -- + poisons on NULL
SELECT CONCAT(FirstName, ' ', LastName) FROM dbo.DimCustomer;  -- NULL-safe
SELECT LEN(EnglishProductName), SUBSTRING(EnglishProductName, 1, 5)
FROM dbo.DimProduct;
```

## 5. The integer-division gotcha

```sql
SELECT 5 / 2;        -- returns 2, not 2.5 (both sides are INT)
SELECT 5 / 2.0;      -- returns 2.5
-- In growth-% calcs, always: CAST(new - old AS DECIMAL(10,2)) / NULLIF(old, 0)
```

## 6. Variables and batches

```sql
DECLARE @StartDate DATE = '2021-01-01';
DECLARE @Region NVARCHAR(50) = 'North America';

SELECT SUM(SalesAmount)
FROM dbo.FactInternetSales
WHERE OrderDateKey >= CONVERT(INT, CONVERT(VARCHAR, @StartDate, 112));
GO   -- batch separator (an SSMS command, not T-SQL). Variables die at GO.
```

## 7. Stored procedures — you know the idea, here's the shell

```sql
CREATE OR ALTER PROCEDURE dbo.usp_SalesReport
    @StartDate DATE,
    @EndDate   DATE,
    @Region    NVARCHAR(50) = NULL     -- optional param with default
AS
BEGIN
    SET NOCOUNT ON;   -- suppresses "(n rows affected)" noise

    SELECT d.CalendarYear, d.MonthNumberOfYear, SUM(f.SalesAmount) AS Revenue
    FROM dbo.FactInternetSales f
    JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
    WHERE d.FullDateAlternateKey BETWEEN @StartDate AND @EndDate
      AND (@Region IS NULL OR f.SalesTerritoryKey IN (
              SELECT SalesTerritoryKey FROM dbo.DimSalesTerritory
              WHERE SalesTerritoryGroup = @Region))
    GROUP BY d.CalendarYear, d.MonthNumberOfYear;
END;
GO

EXEC dbo.usp_SalesReport @StartDate = '2021-01-01', @EndDate = '2021-12-31';
```

## 8. Functions

```sql
-- Scalar (call as dbo.fn_Name(...) — schema prefix required)
CREATE OR ALTER FUNCTION dbo.fn_NetRevenue(@Gross DECIMAL(18,2), @Discount DECIMAL(5,2))
RETURNS DECIMAL(18,2)
AS BEGIN RETURN @Gross * (1 - @Discount); END;
GO

-- Inline table-valued (preferred: the optimizer treats it like a view, fast)
CREATE OR ALTER FUNCTION dbo.fn_TopProducts(@TopN INT)
RETURNS TABLE
AS RETURN (
    SELECT TOP (@TopN) ProductKey, SUM(SalesAmount) AS Revenue
    FROM dbo.FactInternetSales
    GROUP BY ProductKey
    ORDER BY Revenue DESC
);
GO
```

## 9. Temp tables

```sql
SELECT ProductKey, SUM(SalesAmount) AS Revenue
INTO #TopProducts                        -- # = session-local temp table
FROM dbo.FactInternetSales
GROUP BY ProductKey;

SELECT * FROM #TopProducts WHERE Revenue > 100000;
DROP TABLE #TopProducts;
```

## 10. APPLY — T-SQL's lateral join

A correlated subquery in the FROM clause. `CROSS APPLY` = inner, `OUTER APPLY` = left.

```sql
-- Latest sale per product, without a window function
SELECT p.EnglishProductName, s.SalesAmount, s.OrderDateKey
FROM dbo.DimProduct p
CROSS APPLY (
    SELECT TOP 1 SalesAmount, OrderDateKey
    FROM dbo.FactInternetSales f
    WHERE f.ProductKey = p.ProductKey
    ORDER BY f.OrderDateKey DESC
) s;
```

## 11. Safe conversions

```sql
SELECT TRY_CAST('abc' AS INT);    -- NULL instead of an error
SELECT TRY_CAST('2021-13-99' AS DATE);  -- NULL
```

---

**Bottom line:** your window functions (`ROW_NUMBER`, `RANK`, `LAG`, `SUM() OVER (...)`)
work exactly as you know them. The new things to reach for in this project are
`TOP`, `DATEADD`/`DATEDIFF`, `ISNULL`, `APPLY`, and the proc shell in section 7.
