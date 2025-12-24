USE GRADTEST;
GO
SET NOCOUNT ON;
GO

BEGIN TRY
    BEGIN TRAN;

    ;WITH Sess AS (
        SELECT SessionId, ROW_NUMBER() OVER (ORDER BY NEWID()) rn
        FROM dbo.[Session]
    ),
    SessCnt AS (
        SELECT COUNT(*) c FROM dbo.[Session]
    ),
    N AS (
        SELECT TOP (50000)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    )
    INSERT INTO dbo.SearchRequest
    (
        SessionId,
        UserId,
        DeviceType,
        SearchType,
        OriginalInput,
        DetectedLanguageId,
        ConfidenceScore,
        RequestedAt
    )
    SELECT
        s.SessionId,
        NULL,
        CASE
            WHEN N.n % 4 = 0 THEN N'Kiosk'
            WHEN N.n % 4 = 1 THEN N'Mobile'
            WHEN N.n % 4 = 2 THEN N'Tablet'
            ELSE N'Web'
        END,
        N'Text',
        CONCAT(
            N'I want detailed information about museum object ',
            ABS(CHECKSUM(NEWID())) % 20000 + 1,
            N'. Please explain its historical significance, materials, era, ',
            N'cultural background, and compare it with similar artifacts.'
        ),
        (SELECT TOP 1 LanguageId FROM dbo.[Language] ORDER BY NEWID()),
        CAST(0.65 + (RAND(CHECKSUM(NEWID())) * 0.34) AS decimal(5,4)),
        DATEADD(
            second,
            -ABS(CHECKSUM(NEWID())) % 800000,
            SYSDATETIME()
        )
    FROM N
    CROSS JOIN SessCnt sc
    JOIN Sess s
        ON s.rn = ((N.n - 1) % sc.c) + 1;

    COMMIT;
    PRINT N'✅ 50,000 SearchRequest rows inserted (FK-safe).';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;
GO
