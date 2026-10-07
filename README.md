# Retail Sales Analytics — SQL Server Project

**Dataset:** AdventureWorksDW (Microsoft's official sample data warehouse)
**Tools:** SQL Server + SSMS · **Language:** T-SQL (joins, CTEs, window functions, views, stored procedures)

## Setup

1. Download `AdventureWorksDW2025.bak`:
   https://github.com/microsoft/sql-server-samples/releases/tag/adventureworks
   (under "AdventureWorksDW (Data Warehouse) full database backups").
   Note: a 2025 backup only restores on SQL Server 2025 or newer — install
   SQL Server 2025 Developer (free) from
   https://www.microsoft.com/en-us/sql-server/sql-server-downloads, plus SSMS.
2. In SSMS: right-click **Databases → Restore Database → Device** → select the `.bak` → OK.
3. Set the database dropdown in SSMS to your restored database
   (each script header tells you where it expects to run).

## Run order

| File | What it does | Guide section |
|---|---|---|
| `sql/01_data_quality.sql` | NULL audit, grain check, orphan-FK check | Analytics 27–28 |
| `sql/02_sales_performance.sql` | Annual/monthly revenue, MoM/YoY growth, running total, 3-month MA, channel comparison | Analytics 1–7 |
| `sql/views/vw_MonthlyRevenue.sql` | Reusable view: monthly revenue + MoM% + YoY% + running total + 3-month moving average | Views |

More analysis files (`03_product_analysis.sql` … `07_sales_team.sql`) follow the same
pattern — each answers the business questions in the project guide, one file per section.

## Schema (star)

`FactInternetSales` / `FactResellerSales` (facts) join to
`DimDate`, `DimProduct`, `DimCustomer`, `DimGeography`, `DimSalesTerritory`,
`DimPromotion`, `DimEmployee`, `DimCurrency`. Targets live in `FactSalesQuota`,
stock in `FactProductInventory`.

## Key findings

*(Fill in after running — 5–8 bullets a stakeholder would care about.)*
