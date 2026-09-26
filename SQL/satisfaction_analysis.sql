WITH MonthlyRatings AS
(
    SELECT
        s.StoreName,

        DATEFROMPARTS(
            YEAR(r.ReviewDate),
            MONTH(r.ReviewDate),
            1
        ) AS ReviewMonth,

        COUNT(*) AS ReviewCount,

        AVG(CAST(r.Rating AS DECIMAL(10,2)))
            AS AverageRating

    FROM Reviews r

    JOIN Orders o
        ON o.OrderID = r.OrderID

    JOIN Stores s
        ON s.StoreID = o.StoreID

    GROUP BY
        s.StoreName,
        DATEFROMPARTS(
            YEAR(r.ReviewDate),
            MONTH(r.ReviewDate),
            1
        )
),

RatingTrend AS
(
    SELECT
        StoreName,
        ReviewMonth,
        ReviewCount,
        AverageRating,

        LAG(AverageRating) OVER
        (
            PARTITION BY StoreName
            ORDER BY ReviewMonth
        ) AS PreviousMonthRating

    FROM MonthlyRatings
)

SELECT
    StoreName,
    ReviewMonth,
    ReviewCount,

    ROUND(AverageRating, 2)
        AS AverageRating,

    ROUND(PreviousMonthRating, 2)
        AS PreviousMonthRating,

    ROUND(
        AverageRating - PreviousMonthRating,
        2
    ) AS RatingChange

FROM RatingTrend

ORDER BY
    AverageRating ASC,
    ReviewMonth DESC;
    WITH MonthlyRatings AS
(
    SELECT
        s.StoreName,

        DATEFROMPARTS(
            YEAR(r.ReviewDate),
            MONTH(r.ReviewDate),
            1
        ) AS ReviewMonth,

        COUNT(*) AS ReviewCount,

        AVG(CAST(r.Rating AS DECIMAL(10,2)))
            AS AverageRating

    FROM Reviews r

    JOIN Orders o
        ON o.OrderID = r.OrderID

    JOIN Stores s
        ON s.StoreID = o.StoreID

    WHERE s.StoreName = 'NovaRetail Mumbai'

    GROUP BY
        s.StoreName,
        DATEFROMPARTS(
            YEAR(r.ReviewDate),
            MONTH(r.ReviewDate),
            1
        )
)

SELECT
    StoreName,
    ReviewMonth,
    ReviewCount,

    ROUND(AverageRating, 2)
        AS AverageRating,

    CASE
        WHEN AverageRating < 3
             AND ReviewCount >= 20
        THEN 'HIGH SATISFACTION RISK'

        WHEN AverageRating < 3.5
             AND ReviewCount >= 20
        THEN 'WATCH'

        ELSE 'NORMAL'
    END AS SentinelWarning

FROM MonthlyRatings

ORDER BY ReviewMonth;