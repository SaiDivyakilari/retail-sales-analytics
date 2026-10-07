# AdventureWorksDW2025 — ER Diagram

Four star schemas for the Retail Sales Analytics project.
Read each as: **one** dimension row → **many** fact rows, joined on the labeled key.

---

## 1. Internet Sales (online orders)

Grain: one row per order line · Measures: `OrderQuantity`, `UnitPrice`, `SalesAmount`, `TaxAmt`, `Freight`

```mermaid
erDiagram
    DimDate ||--o{ FactInternetSales : "OrderDateKey, DueDateKey, ShipDateKey"
    DimCustomer ||--o{ FactInternetSales : "CustomerKey"
    DimProduct ||--o{ FactInternetSales : "ProductKey"
    DimPromotion ||--o{ FactInternetSales : "PromotionKey"
    DimCurrency ||--o{ FactInternetSales : "CurrencyKey"
    DimSalesTerritory ||--o{ FactInternetSales : "SalesTerritoryKey"
    DimGeography ||--o{ DimCustomer : "GeographyKey"
    DimProductSubcategory ||--o{ DimProduct : "ProductSubcategoryKey"
    DimProductCategory ||--o{ DimProductSubcategory : "ProductCategoryKey"

    FactInternetSales {
        string SalesOrderNumber PK
        int SalesOrderLineNumber PK
        int ProductKey FK
        int OrderDateKey FK
        int DueDateKey FK
        int ShipDateKey FK
        int CustomerKey FK
        int PromotionKey FK
        int CurrencyKey FK
        int SalesTerritoryKey FK
        int OrderQuantity
        decimal UnitPrice
        decimal SalesAmount
    }
    DimDate {
        int DateKey PK
        date FullDateAlternateKey
        int CalendarYear
        int CalendarQuarter
        int MonthNumberOfYear
        string EnglishMonthName
        string EnglishDayNameOfWeek
    }
    DimCustomer {
        int CustomerKey PK
        int GeographyKey FK
        string FirstName
        string LastName
        decimal YearlyIncome
        date DateFirstPurchase
    }
    DimGeography {
        int GeographyKey PK
        string City
        string StateProvinceName
        string EnglishCountryRegionName
    }
    DimProduct {
        int ProductKey PK
        string EnglishProductName
        string Color
        decimal ListPrice
        int ProductSubcategoryKey FK
        string Status
    }
    DimProductSubcategory {
        int ProductSubcategoryKey PK
        string EnglishProductSubcategoryName
        int ProductCategoryKey FK
    }
    DimProductCategory {
        int ProductCategoryKey PK
        string EnglishProductCategoryName
    }
    DimPromotion {
        int PromotionKey PK
        string EnglishPromotionName
        decimal DiscountPct
    }
    DimCurrency {
        int CurrencyKey PK
        string CurrencyAlternateKey
    }
    DimSalesTerritory {
        int SalesTerritoryKey PK
        string SalesTerritoryRegion
        string SalesTerritoryCountry
        string SalesTerritoryGroup
    }
```

---

## 2. Reseller Sales (B2B orders)

Grain: one row per order line · Measures: `OrderQuantity`, `UnitPrice`, `SalesAmount` ·
Extra vs internet: `DimReseller` + `DimEmployee` (salesperson)

```mermaid
erDiagram
    DimDate ||--o{ FactResellerSales : "OrderDateKey, DueDateKey, ShipDateKey"
    DimReseller ||--o{ FactResellerSales : "ResellerKey"
    DimEmployee ||--o{ FactResellerSales : "EmployeeKey"
    DimProduct ||--o{ FactResellerSales : "ProductKey"
    DimPromotion ||--o{ FactResellerSales : "PromotionKey"
    DimCurrency ||--o{ FactResellerSales : "CurrencyKey"
    DimSalesTerritory ||--o{ FactResellerSales : "SalesTerritoryKey"
    DimSalesTerritory ||--o{ DimEmployee : "SalesTerritoryKey"
    DimGeography ||--o{ DimReseller : "GeographyKey"

    FactResellerSales {
        string SalesOrderNumber PK
        int SalesOrderLineNumber PK
        int ProductKey FK
        int OrderDateKey FK
        int ResellerKey FK
        int EmployeeKey FK
        int PromotionKey FK
        int CurrencyKey FK
        int SalesTerritoryKey FK
        int OrderQuantity
        decimal SalesAmount
    }
    DimReseller {
        int ResellerKey PK
        string ResellerName
        int GeographyKey FK
    }
    DimEmployee {
        int EmployeeKey PK
        string FirstName
        string LastName
        string Title
        int SalesTerritoryKey FK
    }
    DimDate {
        int DateKey PK
        date FullDateAlternateKey
        int CalendarYear
        int CalendarQuarter
    }
    DimProduct {
        int ProductKey PK
        string EnglishProductName
    }
    DimPromotion {
        int PromotionKey PK
        decimal DiscountPct
    }
    DimCurrency {
        int CurrencyKey PK
        string CurrencyAlternateKey
    }
    DimSalesTerritory {
        int SalesTerritoryKey PK
        string SalesTerritoryRegion
        string SalesTerritoryCountry
    }
    DimGeography {
        int GeographyKey PK
        string City
        string EnglishCountryRegionName
    }
```

---

## 3. Sales Quota (targets)

Grain: one row per salesperson per quarter · Measure: `SalesAmountQuota` ·
Powers the quota-attainment analytics

```mermaid
erDiagram
    DimEmployee ||--o{ FactSalesQuota : "EmployeeKey"
    DimDate ||--o{ FactSalesQuota : "DateKey (quarter grain)"

    FactSalesQuota {
        int SalesQuotaKey PK
        int EmployeeKey FK
        int DateKey FK
        decimal SalesAmountQuota
    }
    DimEmployee {
        int EmployeeKey PK
        string FirstName
        string LastName
        string Title
    }
    DimDate {
        int DateKey PK
        int CalendarYear
        int CalendarQuarter
    }
```

---

## 4. Product Inventory (stock)

Grain: one row per product per day · Measures: `UnitCost`, `UnitsIn`, `UnitsOut`, `UnitsBalance` ·
Powers the slow-moving-inventory analysis

```mermaid
erDiagram
    DimProduct ||--o{ FactProductInventory : "ProductKey"
    DimDate ||--o{ FactProductInventory : "DateKey"

    FactProductInventory {
        int ProductKey PK
        int DateKey PK
        decimal UnitCost
        int UnitsIn
        int UnitsOut
        int UnitsBalance
    }
    DimProduct {
        int ProductKey PK
        string EnglishProductName
        decimal ListPrice
    }
    DimDate {
        int DateKey PK
        date FullDateAlternateKey
    }
```

---

**Note:** the same dimension tables are reused across stars (conformed dimensions) — e.g. join
`FactInternetSales` to `DimDate` three times with different aliases when you need order date,
due date, and ship date in one query.
