
Combined AS
(
    SELECT
        s.StoreID,
        s.StoreName,
        r.ScoreMonth,

        r.RevenueScore,

        p.ProfitabilityScore,

        rt.ReturnScore,

        i.InventoryScore,

        cr.RetentionScore,

        sa.SatisfactionScore,

        co.ComplaintScore

    FROM RevenueScores r

    JOIN Stores s
        ON s.StoreID = r.StoreID

    JOIN ProfitabilityScores p
        ON p.StoreID = r.StoreID
        AND p.ScoreMonth = r.ScoreMonth

    JOIN ReturnScores rt
        ON rt.StoreID = r.StoreID
        AND rt.ScoreMonth = r.ScoreMonth

    JOIN InventoryScores i
        ON i.StoreID = r.StoreID
        AND i.ScoreMonth = r.ScoreMonth

    JOIN RetentionScores cr
        ON cr.StoreID = r.StoreID
        AND cr.ScoreMonth = r.ScoreMonth

    JOIN SatisfactionScores sa
        ON sa.StoreID = r.StoreID
        AND sa.ScoreMonth = r.ScoreMonth

    JOIN ComplaintScores co
        ON co.StoreID = r.StoreID
        AND co.ScoreMonth = r.ScoreMonth
),


-- ============================================================
-- CALCULATE FINAL BUSINESS HEALTH SCORE
-- ============================================================

FinalScores AS
(
    SELECT
        *,

        RevenueScore * 0.20

        + ProfitabilityScore * 0.15

        + ReturnScore * 0.15

        + InventoryScore * 0.15

        + RetentionScore * 0.15

        + SatisfactionScore * 0.10

        + ComplaintScore * 0.10

        AS BusinessHealthScore

    FROM Combined

   WHERE
    ScoreMonth >= '2025-02-01'
    AND ScoreMonth <= '2026-08-01'
    AND SatisfactionScore IS NOT NULL
)


-- ============================================================
-- INSERT FINAL RESULTS
-- ============================================================

INSERT INTO StoreHealthScores
(
    StoreID,
    ScoreMonth,
    RevenueScore,
    ProfitabilityScore,
    ReturnScore,
    InventoryScore,
    RetentionScore,
    SatisfactionScore,
    ComplaintScore,
    BusinessHealthScore,
    HealthStatus,
    MainRisk
)

SELECT
    StoreID,

    ScoreMonth,

    RevenueScore,

    ROUND(
        ProfitabilityScore,
        2
    ),

    ReturnScore,

    ROUND(
        InventoryScore,
        2
    ),

    RetentionScore,

    SatisfactionScore,

    ROUND(
        ComplaintScore,
        2
    ),

    ROUND(
        BusinessHealthScore,
        2
    ),


    -- ========================================================
    -- HEALTH STATUS
    -- ========================================================

    CASE

        WHEN BusinessHealthScore < 40
        THEN 'CRITICAL'


        WHEN RevenueScore <= 20

          OR ProfitabilityScore <= 20

          OR ReturnScore <= 20

          OR InventoryScore <= 20

          OR RetentionScore <= 20

          OR SatisfactionScore <= 20

          OR ComplaintScore <= 20

        THEN 'HIGH RISK'


        WHEN BusinessHealthScore < 70

          OR RevenueScore <= 30

          OR ProfitabilityScore <= 30

          OR ReturnScore <= 30

          OR InventoryScore <= 30

          OR RetentionScore <= 30

          OR SatisfactionScore <= 30

          OR ComplaintScore <= 30

        THEN 'WARNING'


        WHEN BusinessHealthScore < 85
        THEN 'STABLE'


        ELSE 'HEALTHY'

    END AS HealthStatus,


    -- ========================================================
    -- MAIN RISK
    -- ========================================================

    CASE

        WHEN RevenueScore <= ProfitabilityScore

         AND RevenueScore <= ReturnScore

         AND RevenueScore <= InventoryScore

         AND RevenueScore <= RetentionScore

         AND RevenueScore <= SatisfactionScore

         AND RevenueScore <= ComplaintScore

        THEN 'REVENUE'


        WHEN ProfitabilityScore <= ReturnScore

         AND ProfitabilityScore <= InventoryScore

         AND ProfitabilityScore <= RetentionScore

         AND ProfitabilityScore <= SatisfactionScore

         AND ProfitabilityScore <= ComplaintScore

        THEN 'PROFITABILITY / DISCOUNT'


        WHEN ReturnScore <= InventoryScore

         AND ReturnScore <= RetentionScore

         AND ReturnScore <= SatisfactionScore

         AND ReturnScore <= ComplaintScore

        THEN 'RETURNS'


        WHEN InventoryScore <= RetentionScore

         AND InventoryScore <= SatisfactionScore

         AND InventoryScore <= ComplaintScore

        THEN 'INVENTORY'


        WHEN RetentionScore <= SatisfactionScore

         AND RetentionScore <= ComplaintScore

        THEN 'CUSTOMER RETENTION'


        WHEN SatisfactionScore <= ComplaintScore

        THEN 'CUSTOMER SATISFACTION'


        ELSE 'COMPLAINTS'

    END AS MainRisk

FROM FinalScores;


-- ============================================================
-- CHECK STORED RESULTS
-- ============================================================

SELECT
    s.StoreName,

    h.ScoreMonth,

    h.RevenueScore,

    h.ProfitabilityScore,

    h.ReturnScore,

    h.InventoryScore,

    h.RetentionScore,

    h.SatisfactionScore,

    h.ComplaintScore,

    h.BusinessHealthScore,

    h.HealthStatus,

    h.MainRisk

FROM StoreHealthScores h

JOIN Stores s
    ON s.StoreID = h.StoreID

WHERE h.ScoreMonth = '2026-08-01'

ORDER BY
    h.BusinessHealthScore ASC;
    SELECT
    ScoreMonth,
    COUNT(*) AS StoreCount
FROM StoreHealthScores
GROUP BY ScoreMonth
ORDER BY ScoreMonth;
SELECT
    ScoreMonth,
    HealthStatus,
    COUNT(*) AS StoreCount
FROM StoreHealthScores
GROUP BY
    ScoreMonth,
    HealthStatus
ORDER BY
    ScoreMonth,
    HealthStatus;