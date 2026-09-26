WITH MonthlyRevenue AS
(
    SELECT
        s.StoreName,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        SUM(
            oi.Quantity
            * oi.UnitPrice
            * (1 - oi.DiscountPercentage / 100.0)
        ) AS NetRevenue

    FROM Orders o

    JOIN Stores s
        ON s.StoreID = o.StoreID

    JOIN OrderItems oi
        ON oi.OrderID = o.OrderID

    WHERE o.OrderStatus = 'Completed'

    GROUP BY
        s.StoreName,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),

RevenueWithPreviousMonth AS
(
    SELECT
        StoreName,
        SalesMonth,
        NetRevenue,

        LAG(NetRevenue) OVER
        (
            PARTITION BY StoreName
            ORDER BY SalesMonth
        ) AS PreviousMonthRevenue

    FROM MonthlyRevenue
)

SELECT
    StoreName,
    SalesMonth,
    ROUND(NetRevenue, 2) AS NetRevenue,
    ROUND(PreviousMonthRevenue, 2) AS PreviousMonthRevenue,

    ROUND(
        (
            (NetRevenue - PreviousMonthRevenue)
            / NULLIF(PreviousMonthRevenue, 0)
        ) * 100,
        2
    ) AS MoMGrowthPercent

FROM RevenueWithPreviousMonth

ORDER BY
    StoreName,
    SalesMonth;
    WITH MonthlyRevenue AS
(
    SELECT
        s.StoreName,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        SUM(
            oi.Quantity
            * oi.UnitPrice
            * (1 - oi.DiscountPercentage / 100.0)
        ) AS NetRevenue

    FROM Orders o

    JOIN Stores s
        ON s.StoreID = o.StoreID

    JOIN OrderItems oi
        ON oi.OrderID = o.OrderID

    WHERE o.OrderStatus = 'Completed'

    GROUP BY
        s.StoreName,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),

PreviousRevenue AS
(
    SELECT
        StoreName,
        SalesMonth,
        NetRevenue,

        LAG(NetRevenue) OVER
        (
            PARTITION BY StoreName
            ORDER BY SalesMonth
        ) AS PreviousMonthRevenue

    FROM MonthlyRevenue
),

Growth AS
(
    SELECT
        StoreName,
        SalesMonth,
        NetRevenue,

        (
            (NetRevenue - PreviousMonthRevenue)
            / NULLIF(PreviousMonthRevenue, 0)
        ) * 100 AS MoMGrowthPercent

    FROM PreviousRevenue
),

GrowthHistory AS
(
    SELECT
        StoreName,
        SalesMonth,
        MoMGrowthPercent,

        LAG(MoMGrowthPercent, 1) OVER
        (
            PARTITION BY StoreName
            ORDER BY SalesMonth
        ) AS PreviousGrowth1,

        LAG(MoMGrowthPercent, 2) OVER
        (
            PARTITION BY StoreName
            ORDER BY SalesMonth
        ) AS PreviousGrowth2

    FROM Growth
)

SELECT
    StoreName,
    SalesMonth,

    ROUND(PreviousGrowth2, 2) AS Growth3MonthsAgo,
    ROUND(PreviousGrowth1, 2) AS Growth2MonthsAgo,
    ROUND(MoMGrowthPercent, 2) AS CurrentGrowth,

    'Revenue Warning' AS Warning

FROM GrowthHistory

WHERE
    MoMGrowthPercent < 0
    AND PreviousGrowth1 < 0
    AND PreviousGrowth2 < 0

ORDER BY
    StoreName,
    SalesMonth;