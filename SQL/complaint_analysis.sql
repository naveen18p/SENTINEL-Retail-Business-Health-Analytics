WITH MonthlyOrders AS
(
    SELECT
        StoreID,

        DATEFROMPARTS(
            YEAR(OrderDate),
            MONTH(OrderDate),
            1
        ) AS SalesMonth,

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
        ) AS ComplaintMonth,

        COUNT(*) AS ComplaintCount,

        AVG(CAST(ResolutionDays AS DECIMAL(10,2)))
            AS AvgResolutionDays,

        SUM(
            CASE
                WHEN ComplaintStatus = 'Open'
                THEN 1
                ELSE 0
            END
        ) AS OpenComplaints,

        SUM(
            CASE
                WHEN ComplaintStatus = 'Escalated'
                THEN 1
                ELSE 0
            END
        ) AS EscalatedComplaints

    FROM Complaints

    GROUP BY
        StoreID,
        DATEFROMPARTS(
            YEAR(ComplaintDate),
            MONTH(ComplaintDate),
            1
        )
)

SELECT
    s.StoreName,
    o.SalesMonth,
    o.CompletedOrders,

    ISNULL(c.ComplaintCount, 0)
        AS ComplaintCount,

    ROUND(
        ISNULL(c.ComplaintCount, 0) * 100.0
        / NULLIF(o.CompletedOrders, 0),
        2
    ) AS ComplaintsPer100Orders,

    ROUND(
        ISNULL(c.AvgResolutionDays, 0),
        2
    ) AS AvgResolutionDays,

    ISNULL(c.OpenComplaints, 0)
        AS OpenComplaints,

    ISNULL(c.EscalatedComplaints, 0)
        AS EscalatedComplaints

FROM MonthlyOrders o

JOIN Stores s
    ON s.StoreID = o.StoreID

LEFT JOIN MonthlyComplaints c
    ON c.StoreID = o.StoreID
    AND c.ComplaintMonth = o.SalesMonth

ORDER BY
    AvgResolutionDays DESC,
    ComplaintsPer100Orders DESC;
    WITH MonthlyOrders AS
(
    SELECT
        StoreID,
        DATEFROMPARTS(
            YEAR(OrderDate),
            MONTH(OrderDate),
            1
        ) AS SalesMonth,
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
        ) AS ComplaintMonth,

        COUNT(*) AS ComplaintCount,

        AVG(CAST(ResolutionDays AS DECIMAL(10,2)))
            AS AvgResolutionDays,

        SUM(
            CASE
                WHEN ComplaintStatus = 'Open'
                THEN 1 ELSE 0
            END
        ) AS OpenComplaints,

        SUM(
            CASE
                WHEN ComplaintStatus = 'Escalated'
                THEN 1 ELSE 0
            END
        ) AS EscalatedComplaints

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
        s.StoreName,
        o.SalesMonth,
        o.CompletedOrders,

        ISNULL(c.ComplaintCount, 0)
            AS ComplaintCount,

        ISNULL(c.ComplaintCount, 0) * 100.0
        / NULLIF(o.CompletedOrders, 0)
            AS ComplaintsPer100Orders,

        ISNULL(c.AvgResolutionDays, 0)
            AS AvgResolutionDays,

        ISNULL(c.OpenComplaints, 0)
            AS OpenComplaints,

        ISNULL(c.EscalatedComplaints, 0)
            AS EscalatedComplaints

    FROM MonthlyOrders o

    JOIN Stores s
        ON s.StoreID = o.StoreID

    LEFT JOIN MonthlyComplaints c
        ON c.StoreID = o.StoreID
        AND c.ComplaintMonth = o.SalesMonth
)

SELECT
    StoreName,
    SalesMonth,

    ROUND(ComplaintsPer100Orders, 2)
        AS ComplaintsPer100Orders,

    ROUND(AvgResolutionDays, 2)
        AS AvgResolutionDays,

    OpenComplaints,
    EscalatedComplaints,

    CASE
        WHEN AvgResolutionDays >= 7
             AND ComplaintsPer100Orders >= 5
        THEN 'HIGH COMPLAINT RISK'

        WHEN AvgResolutionDays >= 5
             OR ComplaintsPer100Orders >= 4
        THEN 'WATCH'

        ELSE 'NORMAL'
    END AS SentinelWarning

FROM Metrics

WHERE
    AvgResolutionDays >= 5
    OR ComplaintsPer100Orders >= 4

ORDER BY
    SalesMonth DESC,
    AvgResolutionDays DESC;