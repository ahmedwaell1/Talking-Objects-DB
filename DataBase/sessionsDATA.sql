USE GRADTEST;
GO
SET NOCOUNT ON;
GO

BEGIN TRY
    BEGIN TRAN;

    ;WITH N AS (
        SELECT TOP (50000)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    )
    INSERT INTO dbo.[Session]
    (
        SessionId,
        DeviceType,
        LanguageId,
        AgeGroupId,
        LevelId,
        AppVersion,
        StartedAt
    )
    SELECT
        NEWID(),
        CASE
            WHEN N.n % 4 = 0 THEN N'Kiosk'
            WHEN N.n % 4 = 1 THEN N'Mobile'
            WHEN N.n % 4 = 2 THEN N'Tablet'
            ELSE N'Web'
        END,
        (SELECT TOP 1 LanguageId FROM dbo.[Language] ORDER BY NEWID()),
        (SELECT TOP 1 AgeGroupId FROM dbo.AgeGroup ORDER BY NEWID()),
        (SELECT TOP 1 LevelId FROM dbo.EducationLevel ORDER BY NEWID()),
        CONCAT(N'v', 1 + (N.n % 5), N'.', (N.n % 10)),
        DATEADD(
            minute,
            -ABS(CHECKSUM(NEWID())) % 200000,
            SYSDATETIME()
        )
    FROM N;

    COMMIT;
    PRINT N'✅ 50,000 Session rows inserted.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;
GO
