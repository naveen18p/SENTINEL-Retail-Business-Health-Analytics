   CREATE TABLE StoreHealthScores
(
    HealthScoreID INT IDENTITY(1,1) PRIMARY KEY,

    StoreID INT NOT NULL,
    ScoreMonth DATE NOT NULL,

    RevenueScore DECIMAL(5,2),
    ProfitabilityScore DECIMAL(5,2),
    ReturnScore DECIMAL(5,2),
    InventoryScore DECIMAL(5,2),
    RetentionScore DECIMAL(5,2),
    SatisfactionScore DECIMAL(5,2),
    ComplaintScore DECIMAL(5,2),

    BusinessHealthScore DECIMAL(5,2),

    HealthStatus VARCHAR(30),
    MainRisk VARCHAR(100),

    FOREIGN KEY (StoreID)
        REFERENCES Stores(StoreID)
);
WITH MonthlyRevenue AS
(
    SELECT
        o.StoreID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS ScoreMonth,

        SUM(
            oi.Quantity
            * oi.UnitPrice
            * (1 - oi.DiscountPercentage / 100.0)
        ) AS NetRevenue

    FROM Orders o

    JOIN OrderItems oi
        ON oi.OrderID = o.OrderID

    WHERE o.OrderStatus = 'Completed'

    GROUP BY
        o.StoreID,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),

RevenueGrowth AS
(
    SELECT
        StoreID,
        ScoreMonth,
        NetRevenue,

        LAG(NetRevenue) OVER
        (
            PARTITION BY StoreID
            ORDER BY ScoreMonth
        ) AS PreviousRevenue

    FROM MonthlyRevenue
),

RevenueScore AS
(
    SELECT
        StoreID,
        ScoreMonth,
        NetRevenue,

        (
            (NetRevenue - PreviousRevenue)
            / NULLIF(PreviousRevenue, 0)
        ) * 100 AS RevenueGrowthPercent

    FROM RevenueGrowth
)

SELECT
    s.StoreName,
    r.ScoreMonth,

    ROUND(r.NetRevenue, 2)
        AS NetRevenue,

    ROUND(r.RevenueGrowthPercent, 2)
        AS RevenueGrowthPercent,

    CASE
        WHEN RevenueGrowthPercent >= 10 THEN 100
        WHEN RevenueGrowthPercent >= 5 THEN 90
        WHEN RevenueGrowthPercent >= 0 THEN 80
        WHEN RevenueGrowthPercent >= -5 THEN 65
        WHEN RevenueGrowthPercent >= -10 THEN 45
        WHEN RevenueGrowthPercent < -10 THEN 20
        ELSE NULL
    END AS RevenueScore

FROM RevenueScore r

JOIN Stores s
    ON s.StoreID = r.StoreID

ORDER BY
    r.ScoreMonth DESC,
    RevenueScore ASC;
    WITH MonthlyPerformance AS
(
    SELECT
        o.StoreID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS ScoreMonth,

        SUM(
            oi.Quantity
            * oi.UnitPrice
            * (1 - oi.DiscountPercentage / 100.0)
        ) AS NetRevenue,

        SUM(
            oi.Quantity * oi.UnitCost
        ) AS TotalCost,

        SUM(
            CASE
                WHEN oi.DiscountPercentage > 0
                THEN
                    oi.Quantity
                    * oi.UnitPrice
                    * (1 - oi.DiscountPercentage / 100.0)
                ELSE 0
            END
        ) AS DiscountedRevenue

    FROM Orders o

    JOIN OrderItems oi
        ON oi.OrderID = o.OrderID

    WHERE o.OrderStatus = 'Completed'

    GROUP BY
        o.StoreID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),

Metrics AS
(
    SELECT
        StoreID,
        ScoreMonth,
        NetRevenue,

        (
            (NetRevenue - TotalCost)
            / NULLIF(NetRevenue, 0)
        ) * 100 AS ProfitMarginPercent,

        (
            DiscountedRevenue
            / NULLIF(NetRevenue, 0)
        ) * 100 AS DiscountedRevenuePercent

    FROM MonthlyPerformance
),

Scores AS
(
    SELECT
        StoreID,
        ScoreMonth,
        NetRevenue,
        ProfitMarginPercent,
        DiscountedRevenuePercent,

        CASE
            WHEN ProfitMarginPercent >= 25 THEN 100
            WHEN ProfitMarginPercent >= 20 THEN 85
            WHEN ProfitMarginPercent >= 15 THEN 70
            WHEN ProfitMarginPercent >= 10 THEN 50
            WHEN ProfitMarginPercent >= 5 THEN 30
            ELSE 10
        END AS MarginScore,

        CASE
            WHEN DiscountedRevenuePercent < 20 THEN 100
            WHEN DiscountedRevenuePercent < 40 THEN 85
            WHEN DiscountedRevenuePercent < 60 THEN 65
            WHEN DiscountedRevenuePercent < 80 THEN 40
            ELSE 20
        END AS DiscountScore

    FROM Metrics
)

SELECT
    s.StoreName,
    sc.ScoreMonth,

    ROUND(sc.NetRevenue, 2)
        AS NetRevenue,

    ROUND(sc.ProfitMarginPercent, 2)
        AS ProfitMarginPercent,

    ROUND(sc.DiscountedRevenuePercent, 2)
        AS DiscountedRevenuePercent,

    sc.MarginScore,
    sc.DiscountScore,

    ROUND(
        sc.MarginScore * 0.70
        +
        sc.DiscountScore * 0.30,
        2
    ) AS ProfitabilityScore

FROM Scores sc

JOIN Stores s
    ON s.StoreID = sc.StoreID

ORDER BY
    sc.ScoreMonth DESC,
    ProfitabilityScore ASC;
    WITH ReturnsByItem AS
(
    SELECT
        OrderItemID,
        SUM(ReturnQuantity) AS ReturnedQuantity
    FROM Returns
    GROUP BY OrderItemID
),

MonthlyReturns AS
(
    SELECT
        o.StoreID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS ScoreMonth,

        SUM(oi.Quantity) AS SoldQuantity,

        SUM(
            ISNULL(r.ReturnedQuantity, 0)
        ) AS ReturnedQuantity

    FROM Orders o

    JOIN OrderItems oi
        ON oi.OrderID = o.OrderID

    LEFT JOIN ReturnsByItem r
        ON r.OrderItemID = oi.OrderItemID

    WHERE o.OrderStatus = 'Completed'

    GROUP BY
        o.StoreID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),

Metrics AS
(
    SELECT
        StoreID,
        ScoreMonth,
        SoldQuantity,
        ReturnedQuantity,

        ReturnedQuantity * 100.0
        / NULLIF(SoldQuantity, 0)
        AS ReturnRatePercent

    FROM MonthlyReturns
)

SELECT
    s.StoreName,
    m.ScoreMonth,
    m.SoldQuantity,
    m.ReturnedQuantity,

    ROUND(
        m.ReturnRatePercent,
        2
    ) AS ReturnRatePercent,

    CASE
        WHEN m.ReturnRatePercent < 2 THEN 100
        WHEN m.ReturnRatePercent < 5 THEN 85
        WHEN m.ReturnRatePercent < 8 THEN 65
        WHEN m.ReturnRatePercent < 12 THEN 40
        ELSE 20
    END AS ReturnScore

FROM Metrics m

JOIN Stores s
    ON s.StoreID = m.StoreID

ORDER BY
    m.ScoreMonth DESC,
    ReturnScore ASC;
    WITH MonthlyInventory AS
(
    SELECT
        i.StoreID,
        i.SnapshotDate AS ScoreMonth,

        COUNT(*) AS ProductCount,

        SUM(
            CASE
                WHEN i.StockOnHand = 0
                THEN 1
                ELSE 0
            END
        ) AS OutOfStockProducts,

        SUM(
            CASE
                WHEN i.StockOnHand <= i.ReorderPoint
                THEN 1
                ELSE 0
            END
        ) AS BelowReorderProducts

    FROM Inventory i

    GROUP BY
        i.StoreID,
        i.SnapshotDate
),

Metrics AS
(
    SELECT
        StoreID,
        ScoreMonth,
        ProductCount,
        OutOfStockProducts,
        BelowReorderProducts,

        OutOfStockProducts * 100.0
        / NULLIF(ProductCount, 0)
        AS OutOfStockPercent,

        BelowReorderProducts * 100.0
        / NULLIF(ProductCount, 0)
        AS BelowReorderPercent

    FROM MonthlyInventory
),

Scores AS
(
    SELECT
        StoreID,
        ScoreMonth,
        ProductCount,
        OutOfStockProducts,
        BelowReorderProducts,
        OutOfStockPercent,
        BelowReorderPercent,

        CASE
            WHEN OutOfStockPercent < 1 THEN 100
            WHEN OutOfStockPercent < 3 THEN 85
            WHEN OutOfStockPercent < 5 THEN 65
            WHEN OutOfStockPercent < 8 THEN 40
            ELSE 20
        END AS OOSScore,

        CASE
            WHEN BelowReorderPercent < 10 THEN 100
            WHEN BelowReorderPercent < 15 THEN 85
            WHEN BelowReorderPercent < 20 THEN 65
            WHEN BelowReorderPercent < 30 THEN 40
            ELSE 20
        END AS ReorderScore

    FROM Metrics
)

SELECT
    s.StoreName,
    sc.ScoreMonth,

    sc.ProductCount,
    sc.OutOfStockProducts,
    sc.BelowReorderProducts,

    ROUND(sc.OutOfStockPercent, 2)
        AS OutOfStockPercent,

    ROUND(sc.BelowReorderPercent, 2)
        AS BelowReorderPercent,

    sc.OOSScore,
    sc.ReorderScore,

    ROUND(
        sc.OOSScore * 0.60
        +
        sc.ReorderScore * 0.40,
        2
    ) AS InventoryScore

FROM Scores sc

JOIN Stores s
    ON s.StoreID = sc.StoreID

ORDER BY
    sc.ScoreMonth DESC,
    InventoryScore ASC;
    WITH CustomerMonths AS
(
    SELECT DISTINCT
        StoreID,
        CustomerID,

        DATEFROMPARTS(
            YEAR(OrderDate),
            MONTH(OrderDate),
            1
        ) AS SalesMonth

    FROM Orders

    WHERE OrderStatus = 'Completed'
),

MonthlyRetention AS
(
    SELECT
        pm.StoreID,

        DATEADD(
            MONTH,
            1,
            pm.SalesMonth
        ) AS ScoreMonth,

        COUNT(DISTINCT pm.CustomerID)
            AS PreviousMonthCustomers,

        COUNT(DISTINCT cm.CustomerID)
            AS RetainedCustomers

    FROM CustomerMonths pm

    LEFT JOIN CustomerMonths cm
        ON cm.StoreID = pm.StoreID
        AND cm.CustomerID = pm.CustomerID
        AND cm.SalesMonth =
            DATEADD(
                MONTH,
                1,
                pm.SalesMonth
            )

    GROUP BY
        pm.StoreID,
        DATEADD(
            MONTH,
            1,
            pm.SalesMonth
        )
),

Metrics AS
(
    SELECT
        StoreID,
        ScoreMonth,
        PreviousMonthCustomers,
        RetainedCustomers,

        RetainedCustomers * 100.0
        / NULLIF(PreviousMonthCustomers, 0)
        AS RetentionRatePercent

    FROM MonthlyRetention
)

SELECT
    s.StoreName,
    m.ScoreMonth,

    m.PreviousMonthCustomers,
    m.RetainedCustomers,

    m.PreviousMonthCustomers
        - m.RetainedCustomers
        AS LostCustomers,

    ROUND(
        m.RetentionRatePercent,
        2
    ) AS RetentionRatePercent,

    CASE
        WHEN m.RetentionRatePercent >= 40 THEN 100
        WHEN m.RetentionRatePercent >= 30 THEN 85
        WHEN m.RetentionRatePercent >= 20 THEN 65
        WHEN m.RetentionRatePercent >= 10 THEN 40
        ELSE 20
    END AS RetentionScore

FROM Metrics m

JOIN Stores s
    ON s.StoreID = m.StoreID

ORDER BY
    m.ScoreMonth DESC,
    RetentionScore ASC;
    WITH MonthlyRatings AS
(
    SELECT
        o.StoreID,

        DATEFROMPARTS(
            YEAR(r.ReviewDate),
            MONTH(r.ReviewDate),
            1
        ) AS ScoreMonth,

        COUNT(*) AS ReviewCount,

        AVG(
            CAST(r.Rating AS DECIMAL(10,2))
        ) AS AverageRating

    FROM Reviews r

    JOIN Orders o
        ON o.OrderID = r.OrderID

    WHERE r.ReviewDate < '2026-09-01'

    GROUP BY
        o.StoreID,

        DATEFROMPARTS(
            YEAR(r.ReviewDate),
            MONTH(r.ReviewDate),
            1
        )
)

SELECT
    s.StoreName,
    m.ScoreMonth,
    m.ReviewCount,

    ROUND(
        m.AverageRating,
        2
    ) AS AverageRating,

    CASE
        WHEN m.ReviewCount < 20
        THEN NULL

        WHEN m.AverageRating >= 4.2 THEN 100
        WHEN m.AverageRating >= 3.8 THEN 85
        WHEN m.AverageRating >= 3.4 THEN 65
        WHEN m.AverageRating >= 3.0 THEN 40
        ELSE 20
    END AS SatisfactionScore

FROM MonthlyRatings m

JOIN Stores s
    ON s.StoreID = m.StoreID

ORDER BY
    m.ScoreMonth DESC,
    SatisfactionScore ASC;
    WITH MonthlyOrders AS
(
    SELECT
        StoreID,

        DATEFROMPARTS(
            YEAR(OrderDate),
            MONTH(OrderDate),
            1
        ) AS ScoreMonth,

        COUNT(*) AS CompletedOrders

    FROM Orders

    WHERE OrderStatus = 'Completed'

    GROUP BY
        StoreID,
        DATEFROMPARTS(
            YEAR(OrderDate),
            MONTH(OrderDate),
            1
        )
),

MonthlyComplaints AS
(
    SELECT
        StoreID,

        DATEFROMPARTS(
            YEAR(ComplaintDate),
            MONTH(ComplaintDate),
            1
        ) AS ScoreMonth,

        COUNT(*) AS ComplaintCount,

        AVG(
            CAST(ResolutionDays AS DECIMAL(10,2))
        ) AS AvgResolutionDays

    FROM Complaints

    GROUP BY
        StoreID,
        DATEFROMPARTS(
            YEAR(ComplaintDate),
            MONTH(ComplaintDate),
            1
        )
),

Metrics AS
(
    SELECT
        o.StoreID,
        o.ScoreMonth,
        o.CompletedOrders,

        ISNULL(c.ComplaintCount, 0)
            AS ComplaintCount,

        ISNULL(c.AvgResolutionDays, 0)
            AS AvgResolutionDays,

        ISNULL(c.ComplaintCount, 0) * 100.0
        / NULLIF(o.CompletedOrders, 0)
            AS ComplaintsPer100Orders

    FROM MonthlyOrders o

    LEFT JOIN MonthlyComplaints c
        ON c.StoreID = o.StoreID
        AND c.ScoreMonth = o.ScoreMonth
),

Scores AS
(
    SELECT
        StoreID,
        ScoreMonth,
        CompletedOrders,
        ComplaintCount,
        AvgResolutionDays,
        ComplaintsPer100Orders,

        CASE
            WHEN ComplaintsPer100Orders < 1 THEN 100
            WHEN ComplaintsPer100Orders < 2 THEN 85
            WHEN ComplaintsPer100Orders < 4 THEN 65
            WHEN ComplaintsPer100Orders < 6 THEN 40
            ELSE 20
        END AS ComplaintRateScore,

        CASE
            WHEN AvgResolutionDays < 2 THEN 100
            WHEN AvgResolutionDays < 4 THEN 85
            WHEN AvgResolutionDays < 6 THEN 65
            WHEN AvgResolutionDays < 8 THEN 40
            ELSE 20
        END AS ResolutionScore

    FROM Metrics
)

SELECT
    s.StoreName,
    sc.ScoreMonth,

    sc.CompletedOrders,
    sc.ComplaintCount,

    ROUND(
        sc.ComplaintsPer100Orders,
        2
    ) AS ComplaintsPer100Orders,

    ROUND(
        sc.AvgResolutionDays,
        2
    ) AS AvgResolutionDays,

    sc.ComplaintRateScore,
    sc.ResolutionScore,

    ROUND(
        sc.ComplaintRateScore * 0.60
        +
        sc.ResolutionScore * 0.40,
        2
    ) AS ComplaintScore

FROM Scores sc

JOIN Stores s
    ON s.StoreID = sc.StoreID

ORDER BY
    sc.ScoreMonth DESC,
    ComplaintScore ASC;
  USE SentinelDB;
GO

-- ============================================================
-- DELETE PREVIOUS AUGUST 2026 SCORES
-- ============================================================

DELETE FROM StoreHealthScores;



-- ============================================================
-- SENTINEL BUSINESS HEALTH SCORE
-- ============================================================

;WITH

-- ============================================================
-- 1. REVENUE SCORE
-- ============================================================

MonthlyRevenue AS
(
    SELECT
        o.StoreID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS ScoreMonth,

        SUM(
            oi.Quantity
            * oi.UnitPrice
            * (1 - oi.DiscountPercentage / 100.0)
        ) AS NetRevenue

    FROM Orders o

    JOIN OrderItems oi
        ON oi.OrderID = o.OrderID

    WHERE o.OrderStatus = 'Completed'

    GROUP BY
        o.StoreID,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),

RevenueGrowth AS
(
    SELECT
        StoreID,
        ScoreMonth,
        NetRevenue,

        LAG(NetRevenue) OVER
        (
            PARTITION BY StoreID
            ORDER BY ScoreMonth
        ) AS PreviousRevenue

    FROM MonthlyRevenue
),

RevenueScores AS
(
    SELECT
        StoreID,
        ScoreMonth,

        CASE
            WHEN
                (
                    (NetRevenue - PreviousRevenue)
                    / NULLIF(PreviousRevenue, 0)
                ) * 100 >= 10
            THEN 100

            WHEN
                (
                    (NetRevenue - PreviousRevenue)
                    / NULLIF(PreviousRevenue, 0)
                ) * 100 >= 5
            THEN 90

            WHEN
                (
                    (NetRevenue - PreviousRevenue)
                    / NULLIF(PreviousRevenue, 0)
                ) * 100 >= 0
            THEN 80

            WHEN
                (
                    (NetRevenue - PreviousRevenue)
                    / NULLIF(PreviousRevenue, 0)
                ) * 100 >= -5
            THEN 65

            WHEN
                (
                    (NetRevenue - PreviousRevenue)
                    / NULLIF(PreviousRevenue, 0)
                ) * 100 >= -10
            THEN 45

            ELSE 20
        END AS RevenueScore

    FROM RevenueGrowth
),


-- ============================================================
-- 2. PROFITABILITY / DISCOUNT SCORE
-- ============================================================

ProfitMetrics AS
(
    SELECT
        o.StoreID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS ScoreMonth,

        SUM(
            oi.Quantity
            * oi.UnitPrice
            * (1 - oi.DiscountPercentage / 100.0)
        ) AS NetRevenue,

        SUM(
            oi.Quantity * oi.UnitCost
        ) AS TotalCost,

        SUM(
            CASE
                WHEN oi.DiscountPercentage > 0
                THEN
                    oi.Quantity
                    * oi.UnitPrice
                    * (1 - oi.DiscountPercentage / 100.0)

                ELSE 0
            END
        ) AS DiscountedRevenue

    FROM Orders o

    JOIN OrderItems oi
        ON oi.OrderID = o.OrderID

    WHERE o.OrderStatus = 'Completed'

    GROUP BY
        o.StoreID,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),

ProfitabilityScores AS
(
    SELECT
        StoreID,
        ScoreMonth,

        (
            CASE
                WHEN
                    (
                        (NetRevenue - TotalCost)
                        / NULLIF(NetRevenue, 0)
                    ) * 100 >= 25
                THEN 100

                WHEN
                    (
                        (NetRevenue - TotalCost)
                        / NULLIF(NetRevenue, 0)
                    ) * 100 >= 20
                THEN 85

                WHEN
                    (
                        (NetRevenue - TotalCost)
                        / NULLIF(NetRevenue, 0)
                    ) * 100 >= 15
                THEN 70

                WHEN
                    (
                        (NetRevenue - TotalCost)
                        / NULLIF(NetRevenue, 0)
                    ) * 100 >= 10
                THEN 50

                WHEN
                    (
                        (NetRevenue - TotalCost)
                        / NULLIF(NetRevenue, 0)
                    ) * 100 >= 5
                THEN 30

                ELSE 10
            END * 0.70
        )

        +

        (
            CASE
                WHEN
                    (
                        DiscountedRevenue
                        / NULLIF(NetRevenue, 0)
                    ) * 100 < 20
                THEN 100

                WHEN
                    (
                        DiscountedRevenue
                        / NULLIF(NetRevenue, 0)
                    ) * 100 < 40
                THEN 85

                WHEN
                    (
                        DiscountedRevenue
                        / NULLIF(NetRevenue, 0)
                    ) * 100 < 60
                THEN 65

                WHEN
                    (
                        DiscountedRevenue
                        / NULLIF(NetRevenue, 0)
                    ) * 100 < 80
                THEN 40

                ELSE 20
            END * 0.30
        )

        AS ProfitabilityScore

    FROM ProfitMetrics
),


-- ============================================================
-- 3. RETURN SCORE
-- ============================================================

ReturnsByItem AS
(
    SELECT
        OrderItemID,
        SUM(ReturnQuantity) AS ReturnedQuantity

    FROM Returns

    GROUP BY
        OrderItemID
),

ReturnMetrics AS
(
    SELECT
        o.StoreID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS ScoreMonth,

        SUM(oi.Quantity) AS SoldQuantity,

        SUM(
            ISNULL(r.ReturnedQuantity, 0)
        ) AS ReturnedQuantity

    FROM Orders o

    JOIN OrderItems oi
        ON oi.OrderID = o.OrderID

    LEFT JOIN ReturnsByItem r
        ON r.OrderItemID = oi.OrderItemID

    WHERE o.OrderStatus = 'Completed'

    GROUP BY
        o.StoreID,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),

ReturnScores AS
(
    SELECT
        StoreID,
        ScoreMonth,

        CASE
            WHEN
                ReturnedQuantity * 100.0
                / NULLIF(SoldQuantity, 0) < 2
            THEN 100

            WHEN
                ReturnedQuantity * 100.0
                / NULLIF(SoldQuantity, 0) < 5
            THEN 85

            WHEN
                ReturnedQuantity * 100.0
                / NULLIF(SoldQuantity, 0) < 8
            THEN 65

            WHEN
                ReturnedQuantity * 100.0
                / NULLIF(SoldQuantity, 0) < 12
            THEN 40

            ELSE 20
        END AS ReturnScore

    FROM ReturnMetrics
),


-- ============================================================
-- 4. INVENTORY SCORE
-- ============================================================

InventoryMetrics AS
(
    SELECT
        StoreID,

        DATEFROMPARTS(
            YEAR(SnapshotDate),
            MONTH(SnapshotDate),
            1
        ) AS ScoreMonth,

        COUNT(*) AS ProductCount,

        SUM(
            CASE
                WHEN StockOnHand = 0
                THEN 1
                ELSE 0
            END
        ) AS OutOfStockProducts,

        SUM(
            CASE
                WHEN StockOnHand <= ReorderPoint
                THEN 1
                ELSE 0
            END
        ) AS BelowReorderProducts

    FROM Inventory

    GROUP BY
        StoreID,
        DATEFROMPARTS(
            YEAR(SnapshotDate),
            MONTH(SnapshotDate),
            1
        )
),

InventoryScores AS
(
    SELECT
        StoreID,
        ScoreMonth,

        (
            CASE
                WHEN
                    OutOfStockProducts * 100.0
                    / NULLIF(ProductCount, 0) < 1
                THEN 100

                WHEN
                    OutOfStockProducts * 100.0
                    / NULLIF(ProductCount, 0) < 3
                THEN 85

                WHEN
                    OutOfStockProducts * 100.0
                    / NULLIF(ProductCount, 0) < 5
                THEN 65

                WHEN
                    OutOfStockProducts * 100.0
                    / NULLIF(ProductCount, 0) < 8
                THEN 40

                ELSE 20
            END * 0.60
        )

        +

        (
            CASE
                WHEN
                    BelowReorderProducts * 100.0
                    / NULLIF(ProductCount, 0) < 10
                THEN 100

                WHEN
                    BelowReorderProducts * 100.0
                    / NULLIF(ProductCount, 0) < 15
                THEN 85

                WHEN
                    BelowReorderProducts * 100.0
                    / NULLIF(ProductCount, 0) < 20
                THEN 65

                WHEN
                    BelowReorderProducts * 100.0
                    / NULLIF(ProductCount, 0) < 30
                THEN 40

                ELSE 20
            END * 0.40
        )

        AS InventoryScore

    FROM InventoryMetrics
),


-- ============================================================
-- 5. CUSTOMER RETENTION SCORE
-- ============================================================

CustomerMonths AS
(
    SELECT DISTINCT
        StoreID,
        CustomerID,

        DATEFROMPARTS(
            YEAR(OrderDate),
            MONTH(OrderDate),
            1
        ) AS SalesMonth

    FROM Orders

    WHERE OrderStatus = 'Completed'
),

RetentionMetrics AS
(
    SELECT
        pm.StoreID,

        DATEADD(
            MONTH,
            1,
            pm.SalesMonth
        ) AS ScoreMonth,

        COUNT(DISTINCT pm.CustomerID)
            AS PreviousCustomers,

        COUNT(DISTINCT cm.CustomerID)
            AS RetainedCustomers

    FROM CustomerMonths pm

    LEFT JOIN CustomerMonths cm
        ON cm.StoreID = pm.StoreID

        AND cm.CustomerID = pm.CustomerID

        AND cm.SalesMonth =
            DATEADD(
                MONTH,
                1,
                pm.SalesMonth
            )

    GROUP BY
        pm.StoreID,

        DATEADD(
            MONTH,
            1,
            pm.SalesMonth
        )
),

RetentionScores AS
(
    SELECT
        StoreID,
        ScoreMonth,

        CASE
            WHEN
                RetainedCustomers * 100.0
                / NULLIF(PreviousCustomers, 0) >= 40
            THEN 100

            WHEN
                RetainedCustomers * 100.0
                / NULLIF(PreviousCustomers, 0) >= 30
            THEN 85

            WHEN
                RetainedCustomers * 100.0
                / NULLIF(PreviousCustomers, 0) >= 20
            THEN 65

            WHEN
                RetainedCustomers * 100.0
                / NULLIF(PreviousCustomers, 0) >= 10
            THEN 40

            ELSE 20
        END AS RetentionScore

    FROM RetentionMetrics
),


-- ============================================================
-- 6. CUSTOMER SATISFACTION SCORE
-- ============================================================

SatisfactionMetrics AS
(
    SELECT
        o.StoreID,

        DATEFROMPARTS(
            YEAR(r.ReviewDate),
            MONTH(r.ReviewDate),
            1
        ) AS ScoreMonth,

        COUNT(*) AS ReviewCount,

        AVG(
            CAST(r.Rating AS DECIMAL(10,2))
        ) AS AverageRating

    FROM Reviews r

    JOIN Orders o
        ON o.OrderID = r.OrderID

    GROUP BY
        o.StoreID,

        DATEFROMPARTS(
            YEAR(r.ReviewDate),
            MONTH(r.ReviewDate),
            1
        )
),

SatisfactionScores AS
(
    SELECT
        StoreID,
        ScoreMonth,

        CASE
            WHEN ReviewCount < 20
            THEN NULL

            WHEN AverageRating >= 4.2
            THEN 100

            WHEN AverageRating >= 3.8
            THEN 85

            WHEN AverageRating >= 3.4
            THEN 65

            WHEN AverageRating >= 3.0
            THEN 40

            ELSE 20
        END AS SatisfactionScore

    FROM SatisfactionMetrics
),


-- ============================================================
-- 7. COMPLAINT SCORE
-- ============================================================

MonthlyOrders AS
(
    SELECT
        StoreID,

        DATEFROMPARTS(
            YEAR(OrderDate),
            MONTH(OrderDate),
            1
        ) AS ScoreMonth,

        COUNT(*) AS CompletedOrders

    FROM Orders

    WHERE OrderStatus = 'Completed'

    GROUP BY
        StoreID,

        DATEFROMPARTS(
            YEAR(OrderDate),
            MONTH(OrderDate),
            1
        )
),

MonthlyComplaints AS
(
    SELECT
        StoreID,

        DATEFROMPARTS(
            YEAR(ComplaintDate),
            MONTH(ComplaintDate),
            1
        ) AS ScoreMonth,

        COUNT(*) AS ComplaintCount,

        AVG(
            CAST(ResolutionDays AS DECIMAL(10,2))
        ) AS AvgResolutionDays

    FROM Complaints

    GROUP BY
        StoreID,

        DATEFROMPARTS(
            YEAR(ComplaintDate),
            MONTH(ComplaintDate),
            1
        )
),

ComplaintMetrics AS
(
    SELECT
        o.StoreID,
        o.ScoreMonth,

        ISNULL(c.ComplaintCount, 0)
        * 100.0
        / NULLIF(o.CompletedOrders, 0)
        AS ComplaintsPer100Orders,

        ISNULL(
            c.AvgResolutionDays,
            0
        ) AS AvgResolutionDays

    FROM MonthlyOrders o

    LEFT JOIN MonthlyComplaints c
        ON c.StoreID = o.StoreID
        AND c.ScoreMonth = o.ScoreMonth
),

ComplaintScores AS
(
    SELECT
        StoreID,
        ScoreMonth,

        (
            CASE
                WHEN ComplaintsPer100Orders < 1
                THEN 100

                WHEN ComplaintsPer100Orders < 2
                THEN 85

                WHEN ComplaintsPer100Orders < 4
                THEN 65

                WHEN ComplaintsPer100Orders < 6
                THEN 40

                ELSE 20
            END * 0.60
        )

        +

        (
            CASE
                WHEN AvgResolutionDays < 2
                THEN 100

                WHEN AvgResolutionDays < 4
                THEN 85

                WHEN AvgResolutionDays < 6
                THEN 65

                WHEN AvgResolutionDays < 8
                THEN 40

                ELSE 20
            END * 0.40
        )

        AS ComplaintScore