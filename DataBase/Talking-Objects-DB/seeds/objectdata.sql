USE GRADTEST;
GO
SET NOCOUNT ON;
GO

BEGIN TRAN;

;WITH
Nums AS (
    SELECT TOP (10000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
Cat AS (
    SELECT CategoryId, ROW_NUMBER() OVER (ORDER BY CategoryId) rn FROM dbo.Category
),
Era AS (
    SELECT EraId, ROW_NUMBER() OVER (ORDER BY EraId) rn FROM dbo.Era
),
CatCnt AS (SELECT COUNT(*) c FROM dbo.Category),
EraCnt AS (SELECT COUNT(*) c FROM dbo.Era)
INSERT INTO dbo.[Object]
(DefaultTitle, DefaultSummary, CategoryId, EraId, [Status], IsActive, CreatedAt, UpdatedAt, SearchKeywords)
SELECT
    CONCAT(N'Historical Object ', n),
    CONCAT(
        N'This historical object number ', n, N' represents a significant cultural and material artifact discovered in museum collections. ',
        N'It provides deep insight into the social, political, and economic conditions of the era in which it was created. ',
        N'The object has been analyzed by historians, archaeologists, and cultural researchers for decades. ',
        N'Its materials, craftsmanship, and symbolic decorations reflect advanced techniques and belief systems. ',
        N'Today, this object is used extensively in educational programs, academic research, and digital heritage platforms.'
    ),
    c.CategoryId,
    e.EraId,
    N'Published',
    1,
    DATEADD(day, -(n % 5000), SYSDATETIME()),
    SYSDATETIME(),
    CONCAT(
        N'history;museum;artifact;culture;heritage;education;object;',
        N'ancient;analysis;research;llm;retrieval;semantic;vector;knowledge;item-', n
    )
FROM Nums
CROSS JOIN CatCnt cc
CROSS JOIN EraCnt ec
JOIN Cat c ON c.rn = ((Nums.n - 1) % cc.c) + 1
JOIN Era e ON e.rn = ((Nums.n - 1) % ec.c) + 1
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.[Object] o WHERE o.DefaultTitle = CONCAT(N'Historical Object ', n)
);

COMMIT;
GO
