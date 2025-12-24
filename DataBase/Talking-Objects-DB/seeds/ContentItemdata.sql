USE GRADTEST;
GO
SET NOCOUNT ON;
GO

BEGIN TRAN;

;WITH Obj AS (
    SELECT ObjectId, ROW_NUMBER() OVER (ORDER BY ObjectId) rn
    FROM dbo.[Object]
),
Lang AS (
    SELECT LanguageId, ROW_NUMBER() OVER (ORDER BY LanguageId) rn
    FROM dbo.[Language]
),
Nums AS (
    SELECT TOP (5) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) n
    FROM sys.all_objects
)
INSERT INTO dbo.ContentItem
(
    ObjectId,
    LanguageId,
    ContentType,
    VersionNo,
    Status,
    Priority,
    IsFallback
)
SELECT
    o.ObjectId,
    l.LanguageId,
    CASE 
        WHEN Nums.n = 1 THEN N'Mixed'
        WHEN Nums.n = 2 THEN N'Text'
        WHEN Nums.n = 3 THEN N'Audio'
        ELSE N'Mixed'
    END,
    Nums.n,
    N'Published',
    1000 - (Nums.n * 10),
    CASE WHEN Nums.n = 1 THEN 1 ELSE 0 END
FROM Obj o
CROSS JOIN Lang l
CROSS JOIN Nums
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.ContentItem ci
    WHERE ci.ObjectId = o.ObjectId
      AND ci.LanguageId = l.LanguageId
      AND ci.VersionNo = Nums.n
);

COMMIT;
GO
