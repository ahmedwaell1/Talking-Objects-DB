USE GRADTEST;
GO
SET NOCOUNT ON;
GO

/* =========================================================
   FIXED OBJECT SEEDER (FK-SAFE) + LOCATION + QR IDENTIFIER
   Ensures Category/Era/MuseumZone exist then inserts 500 Objects
   ========================================================= */

BEGIN TRY
    BEGIN TRAN;

    /* 1) Ensure minimal master rows exist (ONLY if empty) */
    IF NOT EXISTS (SELECT 1 FROM dbo.Category)
    BEGIN
        INSERT INTO dbo.Category ([Name],[Description])
        VALUES
        (N'Artifacts',N'Historical artifacts'),
        (N'Painting',N'Paintings and visual art'),
        (N'Sculpture',N'3D artworks and statues');
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Era)
    BEGIN
        INSERT INTO dbo.Era ([Name],StartYear,EndYear)
        VALUES
        (N'Ancient',-3000,500),
        (N'Medieval',500,1500),
        (N'Modern',1700,1950);
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.MuseumZone)
    BEGIN
        INSERT INTO dbo.MuseumZone (ZoneName,Floor,[Description],IsActive)
        VALUES
        (N'Main Hall',N'G',N'Central hall',1),
        (N'Gallery A',N'1',N'Gallery A',1),
        (N'Gallery B',N'1',N'Gallery B',1);
    END

    /* 2) Insert 500 Objects (FK-safe pick) */
    ;WITH Cat AS (
        SELECT CategoryId, ROW_NUMBER() OVER (ORDER BY CategoryId) AS rn
        FROM dbo.Category
    ),
    Era AS (
        SELECT EraId, ROW_NUMBER() OVER (ORDER BY EraId) AS rn
        FROM dbo.Era
    ),
    CatCnt AS (SELECT COUNT(*) AS c FROM dbo.Category),
    EraCnt AS (SELECT COUNT(*) AS c FROM dbo.Era),
    N AS (
        SELECT TOP (500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    )
    INSERT INTO dbo.[Object]
        (DefaultTitle, DefaultSummary, CategoryId, EraId, [Status], IsActive, CreatedAt, UpdatedAt, SearchKeywords)
    SELECT
        CONCAT(N'Museum Object #', n.n),
        CONCAT(N'Sample summary for object #', n.n, N' (seed data).'),
        c.CategoryId,
        e.EraId,
        N'Published',
        1,
        DATEADD(day, -(n.n % 180), SYSDATETIME()),
        SYSDATETIME(),
        CONCAT(N'keyword', n.n, N';museum;scan;object')
    FROM N
    CROSS JOIN CatCnt cc
    CROSS JOIN EraCnt ec
    JOIN Cat c ON c.rn = ((n.n - 1) % NULLIF(cc.c,0)) + 1
    JOIN Era e ON e.rn = ((n.n - 1) % NULLIF(ec.c,0)) + 1
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.[Object] o
        WHERE o.DefaultTitle = CONCAT(N'Museum Object #', n.n)
    );

    /* 3) Insert ObjectLocation for latest 500 objects (FK-safe zone pick) */
    ;WITH Z AS (
        SELECT ZoneId, ROW_NUMBER() OVER (ORDER BY ZoneId) AS rn
        FROM dbo.MuseumZone
    ),
    ZCnt AS (SELECT COUNT(*) AS c FROM dbo.MuseumZone),
    L AS (
        SELECT TOP (500)
            o.ObjectId,
            ROW_NUMBER() OVER (ORDER BY o.ObjectId DESC) AS rn
        FROM dbo.[Object] o
        ORDER BY o.ObjectId DESC
    )
    INSERT INTO dbo.ObjectLocation (ObjectId, ZoneId, FromDate, ToDate)
    SELECT
        l.ObjectId,
        z.ZoneId,
        DATEADD(day, -(ABS(CHECKSUM(NEWID())) % 365), CAST(GETDATE() AS date)),
        NULL
    FROM L l
    CROSS JOIN ZCnt zc
    JOIN Z z ON z.rn = ((l.rn - 1) % NULLIF(zc.c,0)) + 1
    WHERE NOT EXISTS (SELECT 1 FROM dbo.ObjectLocation ol WHERE ol.ObjectId = l.ObjectId);

    /* 4) Insert QR identifiers for latest 500 objects */
    ;WITH L2 AS (
        SELECT TOP (500) o.ObjectId
        FROM dbo.[Object] o
        ORDER BY o.ObjectId DESC
    )
    INSERT INTO dbo.ObjectIdentifier
        (ObjectId, IdentifierType, IdentifierValue, IsPrimary, IsActive, ExpiresAt, IsRevoked, LastUsedAt)
    SELECT
        l2.ObjectId,
        N'QR',
        CONCAT(N'QR-OBJ-', l2.ObjectId),
        1, 1,
        NULL, 0, NULL
    FROM L2 l2
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.ObjectIdentifier oi
        WHERE oi.ObjectId = l2.ObjectId AND oi.IdentifierType = N'QR'
    );

    COMMIT;

    PRINT N'✅ Inserted: 500 Objects + ObjectLocation + QR Identifiers (FK-safe).';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;
GO


SELECT
  (SELECT COUNT(*) FROM dbo.[Object]) AS ObjectsCount,
  (SELECT COUNT(*) FROM dbo.ObjectLocation) AS LocationsCount,
  (SELECT COUNT(*) FROM dbo.ObjectIdentifier) AS IdentifiersCount;
