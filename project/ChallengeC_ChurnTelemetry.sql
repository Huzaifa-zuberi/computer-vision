-- ============================================================
-- Challenge C: Subscription Platform "Churn & Engagement"
--             Telemetry Engine
-- Author: Huzaif Zuberi & Sheikh Uzair Ali
-- Description: CTE-based risk analysis, GROUP BY / HAVING
--              aggregate filter, and analytical view
-- ============================================================

-- ---------------------- SOURCE TABLES ----------------------

CREATE TABLE Subscribers (
    SubscriberID    INT             NOT NULL IDENTITY(1,1),
    Email           VARCHAR(150)    NOT NULL,
    FullName        VARCHAR(100)    NOT NULL,
    PlanType        VARCHAR(30)     NOT NULL DEFAULT 'Basic',
    IsActive        BIT             NOT NULL DEFAULT 1,
    JoinedDate      DATE            NOT NULL,
    CONSTRAINT PK_Subscribers PRIMARY KEY (SubscriberID)
);

CREATE TABLE ContentAssets (
    AssetID         INT             NOT NULL IDENTITY(1,1),
    CreatorID       INT             NOT NULL,
    Title           VARCHAR(200)    NOT NULL,
    AssetType       VARCHAR(30)     NOT NULL,
    PublishedDate   DATE            NOT NULL,
    CONSTRAINT PK_ContentAssets PRIMARY KEY (AssetID),
    CONSTRAINT FK_CA_Creator FOREIGN KEY (CreatorID)
        REFERENCES Subscribers(SubscriberID)
);

CREATE TABLE EngagementLog (
    LogID           BIGINT          NOT NULL IDENTITY(1,1),
    SubscriberID    INT             NOT NULL,
    AssetID         INT             NOT NULL,
    EventType       VARCHAR(30)     NOT NULL,
    EventTimestamp  DATETIME2       NOT NULL DEFAULT GETDATE(),
    DurationSeconds INT             NULL,
    CONSTRAINT PK_EngagementLog PRIMARY KEY (LogID),
    CONSTRAINT FK_EL_Subscriber FOREIGN KEY (SubscriberID)
        REFERENCES Subscribers(SubscriberID),
    CONSTRAINT FK_EL_Asset FOREIGN KEY (AssetID)
        REFERENCES ContentAssets(AssetID)
);

-- ---------------------- SEED DATA --------------------------

BEGIN TRANSACTION;

INSERT INTO Subscribers (Email, FullName, PlanType, IsActive, JoinedDate)
VALUES
    ('huzaif@email.com',      'Huzaif Zuberi',      'Premium', 1, '2024-01-15'),
    ('uzair@email.com',       'Sheikh Uzair Ali',   'Basic',   1, '2024-03-01'),
    ('alice@email.com',       'Alice Williams',     'Premium', 1, '2023-11-20'),
    ('bob@email.com',         'Bob Martinez',       'Basic',   1, '2024-06-10'),
    ('charlie@email.com',     'Charlie Chen',       'Premium', 1, '2024-02-05');

INSERT INTO ContentAssets (CreatorID, Title, AssetType, PublishedDate)
VALUES
    (1, 'Advanced SQL Guide',          'Article', '2025-01-10'),
    (1, 'Python for Data Science',     'Video',   '2025-02-14'),
    (2, 'Budget Cooking 101',          'Video',   '2025-03-01'),
    (2, 'Kitchen Hacks Compilation',   'Article', '2025-03-15'),
    (2, 'Healthy Meal Prep',           'Video',   '2025-04-01'),
    (3, 'Morning Yoga Routine',        'Video',   '2024-12-01'),
    (3, 'Meditation for Beginners',    'Article', '2025-01-20'),
    (4, 'Guitar Chords Tutorial',      'Video',   '2025-05-01'),
    (5, 'Machine Learning Basics',     'Article', '2025-02-28'),
    (5, 'Deep Dive into AI',           'Video',   '2025-04-15'),
    (5, 'Neural Networks 101',         'Video',   '2025-05-20'),
    (5, 'Data Visualization Tips',     'Article', '2025-06-01');

INSERT INTO EngagementLog (SubscriberID, AssetID, EventType, EventTimestamp, DurationSeconds)
VALUES
    (1, 1, 'view', '2025-05-01 10:00', 120),
    (1, 2, 'view', '2025-05-02 11:00', 300),
    (2, 3, 'view', '2025-05-01 09:00', 180),
    (2, 4, 'view', '2025-05-03 14:00',  60),
    (2, 5, 'view', '2025-05-05 16:00', 240),
    (3, 6, 'view', '2025-05-01 08:00', 600),
    (3, 7, 'view', '2025-05-02 09:00', 120),
    (4, 8, 'view', '2025-05-10 12:00',  45),
    (5, 9, 'view', '2025-05-01 07:00', 150),
    (5, 10,'view', '2025-05-03 10:00', 400),
    (5, 11,'view', '2025-05-07 11:00', 500),
    (5, 12,'view', '2025-05-10 15:00', 200);

COMMIT TRANSACTION;

-- ============================================================
-- (A) Core Telemetry Query — CTE identifying at-risk profiles
--     Subscribers whose recent usage < global average
-- ============================================================

WITH GlobalAvgUsage AS (
    SELECT AVG(CAST(DurationSeconds AS FLOAT)) AS AvgDuration
    FROM EngagementLog
    WHERE EventTimestamp >= DATEADD(DAY, -30, GETDATE())
),
UserUsage AS (
    SELECT
        el.SubscriberID,
        AVG(CAST(el.DurationSeconds AS FLOAT)) AS UserAvg
    FROM EngagementLog el
    WHERE el.EventTimestamp >= DATEADD(DAY, -30, GETDATE())
    GROUP BY el.SubscriberID
)
SELECT
    s.SubscriberID,
    s.FullName,
    s.Email,
    s.PlanType,
    ROUND(uu.UserAvg, 2) AS UserAvgDurationSec,
    ROUND(ga.AvgDuration, 2) AS GlobalAvgDurationSec,
    'At Risk' AS ChurnIndicator
FROM Subscribers s
JOIN UserUsage uu ON s.SubscriberID = uu.SubscriberID
CROSS JOIN GlobalAvgUsage ga
WHERE s.IsActive = 1
  AND uu.UserAvg < ga.AvgDuration;

-- ============================================================
-- (B) Aggregate Filter — creators with > 5 assets but < 100
--     cumulative views
-- ============================================================

SELECT
    ca.CreatorID,
    s.FullName AS CreatorName,
    COUNT(DISTINCT ca.AssetID)   AS DistinctAssetsPublished,
    COUNT(el.LogID)              AS TotalEngagementEvents,
    COALESCE(SUM(el.DurationSeconds), 0) AS TotalViewSeconds
FROM ContentAssets ca
JOIN Subscribers s ON ca.CreatorID = s.SubscriberID
LEFT JOIN EngagementLog el ON ca.AssetID = el.AssetID
GROUP BY ca.CreatorID, s.FullName
HAVING COUNT(DISTINCT ca.AssetID) > 5
   AND COUNT(el.LogID) < 100;

-- ============================================================
-- (C) Interface Layer — reusable analytical view
--     Joins 4 tables: Subscribers, ContentAssets, EngagementLog
-- ============================================================
GO

CREATE OR ALTER VIEW vw_RiskAnalysisDashboard
AS
WITH GlobalAvg AS (
    SELECT AVG(CAST(DurationSeconds AS FLOAT)) AS AvgDuration
    FROM EngagementLog
    WHERE EventTimestamp >= DATEADD(DAY, -30, GETDATE())
),
PerUser AS (
    SELECT
        el.SubscriberID,
        COUNT(DISTINCT el.AssetID)          AS AssetsEngaged,
        SUM(el.DurationSeconds)             AS TotalDuration,
        AVG(CAST(el.DurationSeconds AS FLOAT)) AS AvgDuration,
        MAX(el.EventTimestamp)              AS LastActivity
    FROM EngagementLog el
    WHERE el.EventTimestamp >= DATEADD(DAY, -30, GETDATE())
    GROUP BY el.SubscriberID
)
SELECT
    s.SubscriberID,
    s.FullName,
    s.Email,
    s.PlanType,
    s.JoinedDate,
    DATEDIFF(DAY, s.JoinedDate, GETDATE()) AS TenureDays,
    ISNULL(pu.AssetsEngaged, 0)            AS AssetsEngaged30d,
    ISNULL(pu.TotalDuration, 0)            AS TotalDurationSec30d,
    ROUND(ISNULL(pu.AvgDuration, 0), 2)    AS AvgDurationSec30d,
    pu.LastActivity,
    ROUND(ga.AvgDuration, 2)               AS PlatformAvgDurationSec30d,
    CASE
        WHEN pu.AvgDuration IS NULL THEN 'No Activity'
        WHEN pu.AvgDuration < ga.AvgDuration THEN 'At Risk'
        ELSE 'Engaged'
    END AS RiskCategory
FROM Subscribers s
INNER JOIN ContentAssets ca ON s.SubscriberID = ca.CreatorID
LEFT JOIN PerUser pu ON s.SubscriberID = pu.SubscriberID
CROSS JOIN GlobalAvg ga;
GO

PRINT 'Challenge C - Churn Telemetry Engine objects created successfully.';
GO
