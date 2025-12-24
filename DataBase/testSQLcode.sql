/* =========================================================
   GRADTEST - Talking Objects (SQL Server / SSMS)
   Full DDL: Tables + PK/FK + Key Constraints
   ========================================================= */

IF DB_ID(N'GRADTEST') IS NULL
BEGIN
    CREATE DATABASE GRADTEST;
END
GO

USE GRADTEST;
GO

/* =========================================================
   0) Safety: drop order (optional)
   Uncomment if you want a clean rebuild
   =========================================================
-- DROP TABLE IF EXISTS dbo.SearchResult, dbo.VoiceInput, dbo.SearchRequest;
-- DROP TABLE IF EXISTS dbo.InteractionLog;
-- DROP TABLE IF EXISTS dbo.ObjectTag, dbo.Tag;
-- DROP TABLE IF EXISTS dbo.ContentItemEducationLevel, dbo.ContentItemAgeGroup;
-- DROP TABLE IF EXISTS dbo.ContentAsset, dbo.ContentText, dbo.ContentItem;
-- DROP TABLE IF EXISTS dbo.ObjectIdentifier;
-- DROP TABLE IF EXISTS dbo.ObjectLocation, dbo.MuseumZone;
-- DROP TABLE IF EXISTS dbo.UserProfile, dbo.UserRole, dbo.Roles, dbo.Users;
-- DROP TABLE IF EXISTS dbo.[Session];
-- DROP TABLE IF EXISTS dbo.Era, dbo.Category, dbo.EducationLevel, dbo.AgeGroup, dbo.Language;
========================================================= */

/* =========================================================
   1) Reference Tables
   ========================================================= */

CREATE TABLE dbo.Language (
    LanguageId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Language PRIMARY KEY,
    Code            NVARCHAR(10) NOT NULL CONSTRAINT UQ_Language_Code UNIQUE,  -- AR/EN/FR
    [Name]          NVARCHAR(100) NOT NULL,
    IsActive        BIT NOT NULL CONSTRAINT DF_Language_IsActive DEFAULT(1)
);
GO

CREATE TABLE dbo.AgeGroup (
    AgeGroupId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AgeGroup PRIMARY KEY,
    [Name]          NVARCHAR(100) NOT NULL CONSTRAINT UQ_AgeGroup_Name UNIQUE, -- Kids/Teens/Adults
    MinAge          INT NULL,
    MaxAge          INT NULL
);
GO

CREATE TABLE dbo.EducationLevel (
    LevelId         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_EducationLevel PRIMARY KEY,
    [Name]          NVARCHAR(150) NOT NULL CONSTRAINT UQ_EducationLevel_Name UNIQUE, -- Primary/University/...
    RankOrder       INT NULL
);
GO

CREATE TABLE dbo.Category (
    CategoryId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Category PRIMARY KEY,
    [Name]          NVARCHAR(150) NOT NULL CONSTRAINT UQ_Category_Name UNIQUE,
    [Description]   NVARCHAR(400) NULL
);
GO

CREATE TABLE dbo.Era (
    EraId           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Era PRIMARY KEY,
    [Name]          NVARCHAR(150) NOT NULL CONSTRAINT UQ_Era_Name UNIQUE,
    StartYear       INT NULL,
    EndYear         INT NULL
);
GO

/* =========================================================
   2) Users & Access
   ========================================================= */

CREATE TABLE dbo.Users (
    UserId          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
    Email           NVARCHAR(256) NULL,
    DisplayName     NVARCHAR(150) NOT NULL,
    Phone           NVARCHAR(30) NULL,
    PasswordHash    NVARCHAR(300) NULL, -- keep NULL if you don't implement login
    IsActive        BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT(1),
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT(SYSDATETIME()),
    UpdatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Users_UpdatedAt DEFAULT(SYSDATETIME())
);
GO

-- Unique email only when it exists
CREATE UNIQUE INDEX UX_Users_Email_NotNull ON dbo.Users(Email) WHERE Email IS NOT NULL;
GO

CREATE TABLE dbo.Roles (
    RoleId          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
    RoleName        NVARCHAR(80) NOT NULL CONSTRAINT UQ_Roles_RoleName UNIQUE, -- Admin/ContentManager/RegisteredUser/Guest
    [Description]   NVARCHAR(250) NULL
);
GO

CREATE TABLE dbo.UserRole (
    UserId      INT NOT NULL,
    RoleId      INT NOT NULL,
    AssignedAt  DATETIME2(0) NOT NULL CONSTRAINT DF_UserRole_AssignedAt DEFAULT(SYSDATETIME()),
    CONSTRAINT PK_UserRole PRIMARY KEY (UserId, RoleId),
    CONSTRAINT FK_UserRole_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
    CONSTRAINT FK_UserRole_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles(RoleId)
);
GO

CREATE TABLE dbo.UserProfile (
    UserId              INT NOT NULL CONSTRAINT PK_UserProfile PRIMARY KEY,
    AgeGroupId           INT NULL,
    LevelId              INT NULL,
    PreferredLanguageId  INT NULL,
    Interests            NVARCHAR(MAX) NULL,
    AccessibilityFlags   NVARCHAR(MAX) NULL,
    CONSTRAINT FK_UserProfile_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
    CONSTRAINT FK_UserProfile_AgeGroup FOREIGN KEY (AgeGroupId) REFERENCES dbo.AgeGroup(AgeGroupId),
    CONSTRAINT FK_UserProfile_EducationLevel FOREIGN KEY (LevelId) REFERENCES dbo.EducationLevel(LevelId),
    CONSTRAINT FK_UserProfile_Language FOREIGN KEY (PreferredLanguageId) REFERENCES dbo.Language(LanguageId)
);
GO

/* =========================================================
   3) Guest Session
   ========================================================= */

CREATE TABLE dbo.[Session] (
    SessionId       UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Session PRIMARY KEY DEFAULT NEWID(),
    StartedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Session_StartedAt DEFAULT(SYSDATETIME()),
    EndedAt         DATETIME2(0) NULL,
    DeviceType      NVARCHAR(30) NOT NULL, -- Android/iOS/Web/Kiosk
    AppVersion      NVARCHAR(50) NULL,
    LanguageId      INT NULL,
    AgeGroupId      INT NULL,
    LevelId         INT NULL,
    CONSTRAINT FK_Session_Language FOREIGN KEY (LanguageId) REFERENCES dbo.Language(LanguageId),
    CONSTRAINT FK_Session_AgeGroup FOREIGN KEY (AgeGroupId) REFERENCES dbo.AgeGroup(AgeGroupId),
    CONSTRAINT FK_Session_EducationLevel FOREIGN KEY (LevelId) REFERENCES dbo.EducationLevel(LevelId)
);
GO

/* =========================================================
   4) Museum Context
   ========================================================= */

CREATE TABLE dbo.MuseumZone (
    ZoneId          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MuseumZone PRIMARY KEY,
    ZoneName        NVARCHAR(150) NOT NULL,
    Floor           NVARCHAR(50) NULL,
    [Description]   NVARCHAR(300) NULL,
    IsActive        BIT NOT NULL CONSTRAINT DF_MuseumZone_IsActive DEFAULT(1)
);
GO

/* =========================================================
   5) Object & Identification
   ========================================================= */

CREATE TABLE dbo.[Object] (
    ObjectId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Object PRIMARY KEY,
    DefaultTitle    NVARCHAR(200) NOT NULL,
    DefaultSummary  NVARCHAR(800) NULL,
    CategoryId      INT NULL,
    EraId           INT NULL,
    [Status]        NVARCHAR(30) NOT NULL, -- Draft/Published/Archived
    IsActive        BIT NOT NULL CONSTRAINT DF_Object_IsActive DEFAULT(1),
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Object_CreatedAt DEFAULT(SYSDATETIME()),
    UpdatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Object_UpdatedAt DEFAULT(SYSDATETIME()),
    SearchKeywords  NVARCHAR(500) NULL,
    CONSTRAINT FK_Object_Category FOREIGN KEY (CategoryId) REFERENCES dbo.Category(CategoryId),
    CONSTRAINT FK_Object_Era FOREIGN KEY (EraId) REFERENCES dbo.Era(EraId),
    CONSTRAINT CK_Object_Status CHECK ([Status] IN (N'Draft', N'Published', N'Archived'))
);
GO

CREATE TABLE dbo.ObjectLocation (
    LocationId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ObjectLocation PRIMARY KEY,
    ObjectId        INT NOT NULL,
    ZoneId          INT NOT NULL,
    FromDate        DATE NULL,
    ToDate          DATE NULL,
    CONSTRAINT FK_ObjectLocation_Object FOREIGN KEY (ObjectId) REFERENCES dbo.[Object](ObjectId),
    CONSTRAINT FK_ObjectLocation_Zone FOREIGN KEY (ZoneId) REFERENCES dbo.MuseumZone(ZoneId)
);
GO

CREATE TABLE dbo.ObjectIdentifier (
    IdentifierId    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ObjectIdentifier PRIMARY KEY,
    ObjectId        INT NOT NULL,
    IdentifierType  NVARCHAR(30) NOT NULL,  -- QR/NFC/ManualCode
    IdentifierValue NVARCHAR(200) NOT NULL,
    IsPrimary       BIT NOT NULL CONSTRAINT DF_ObjectIdentifier_IsPrimary DEFAULT(0),
    IsActive        BIT NOT NULL CONSTRAINT DF_ObjectIdentifier_IsActive DEFAULT(1),
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_ObjectIdentifier_CreatedAt DEFAULT(SYSDATETIME()),
    ExpiresAt       DATETIME2(0) NULL,
    IsRevoked       BIT NULL,
    LastUsedAt      DATETIME2(0) NULL,
    CONSTRAINT FK_ObjectIdentifier_Object FOREIGN KEY (ObjectId) REFERENCES dbo.[Object](ObjectId),
    CONSTRAINT CK_ObjectIdentifier_Type CHECK (IdentifierType IN (N'QR', N'NFC', N'ManualCode')),
    CONSTRAINT UQ_ObjectIdentifier_Value UNIQUE (IdentifierValue)
);
GO

/* =========================================================
   6) Content Management
   ========================================================= */

CREATE TABLE dbo.ContentItem (
    ContentId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ContentItem PRIMARY KEY,
    ObjectId         INT NOT NULL,
    LanguageId       INT NOT NULL,
    ContentType      NVARCHAR(20) NOT NULL, -- Text/Image/Video/Audio/Mixed
    VersionNo        INT NOT NULL CONSTRAINT DF_ContentItem_VersionNo DEFAULT(1),
    [Status]         NVARCHAR(30) NOT NULL, -- Draft/Published/Archived
    Priority         INT NOT NULL CONSTRAINT DF_ContentItem_Priority DEFAULT(100),
    IsFallback       BIT NOT NULL CONSTRAINT DF_ContentItem_IsFallback DEFAULT(0),
    PublishFrom      DATETIME2(0) NULL,
    PublishTo        DATETIME2(0) NULL,
    CreatedAt        DATETIME2(0) NOT NULL CONSTRAINT DF_ContentItem_CreatedAt DEFAULT(SYSDATETIME()),
    UpdatedAt        DATETIME2(0) NOT NULL CONSTRAINT DF_ContentItem_UpdatedAt DEFAULT(SYSDATETIME()),
    CONSTRAINT FK_ContentItem_Object FOREIGN KEY (ObjectId) REFERENCES dbo.[Object](ObjectId),
    CONSTRAINT FK_ContentItem_Language FOREIGN KEY (LanguageId) REFERENCES dbo.Language(LanguageId),
    CONSTRAINT CK_ContentItem_Type CHECK (ContentType IN (N'Text', N'Image', N'Video', N'Audio', N'Mixed')),
    CONSTRAINT CK_ContentItem_Status CHECK ([Status] IN (N'Draft', N'Published', N'Archived')),
    CONSTRAINT UQ_ContentItem_ObjectLangVersion UNIQUE (ObjectId, LanguageId, VersionNo)
);
GO

CREATE TABLE dbo.ContentText (
    ContentId        INT NOT NULL CONSTRAINT PK_ContentText PRIMARY KEY,
    Title            NVARCHAR(250) NOT NULL,
    Body             NVARCHAR(MAX) NOT NULL,
    ReadingTimeSec   INT NULL,
    CONSTRAINT FK_ContentText_ContentItem FOREIGN KEY (ContentId) REFERENCES dbo.ContentItem(ContentId)
);
GO

CREATE TABLE dbo.ContentAsset (
    AssetId          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ContentAsset PRIMARY KEY,
    ContentId        INT NOT NULL,
    AssetType        NVARCHAR(20) NOT NULL, -- Image/Video/Audio/PDF
    Url              NVARCHAR(1000) NOT NULL,
    Caption          NVARCHAR(300) NULL,
    DurationSec      INT NULL,
    SortOrder        INT NOT NULL CONSTRAINT DF_ContentAsset_SortOrder DEFAULT(1),
    ThumbnailUrl     NVARCHAR(1000) NULL,
    CONSTRAINT FK_ContentAsset_ContentItem FOREIGN KEY (ContentId) REFERENCES dbo.ContentItem(ContentId),
    CONSTRAINT CK_ContentAsset_Type CHECK (AssetType IN (N'Image', N'Video', N'Audio', N'PDF'))
);
GO

/* =========================================================
   7) Personalization Targeting
   ========================================================= */

CREATE TABLE dbo.ContentItemAgeGroup (
    ContentId    INT NOT NULL,
    AgeGroupId   INT NOT NULL,
    CONSTRAINT PK_ContentItemAgeGroup PRIMARY KEY (ContentId, AgeGroupId),
    CONSTRAINT FK_CIAG_ContentItem FOREIGN KEY (ContentId) REFERENCES dbo.ContentItem(ContentId),
    CONSTRAINT FK_CIAG_AgeGroup FOREIGN KEY (AgeGroupId) REFERENCES dbo.AgeGroup(AgeGroupId)
);
GO

CREATE TABLE dbo.ContentItemEducationLevel (
    ContentId   INT NOT NULL,
    LevelId     INT NOT NULL,
    CONSTRAINT PK_ContentItemEducationLevel PRIMARY KEY (ContentId, LevelId),
    CONSTRAINT FK_CIEL_ContentItem FOREIGN KEY (ContentId) REFERENCES dbo.ContentItem(ContentId),
    CONSTRAINT FK_CIEL_EducationLevel FOREIGN KEY (LevelId) REFERENCES dbo.EducationLevel(LevelId)
);
GO

/* =========================================================
   8) Tagging
   ========================================================= */

CREATE TABLE dbo.Tag (
    TagId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Tag PRIMARY KEY,
    TagType      NVARCHAR(40) NOT NULL, -- Theme/Material/Period/Artist/Location/Keyword
    TagValue     NVARCHAR(200) NOT NULL,
    Synonyms     NVARCHAR(MAX) NULL,
    IsSearchable BIT NOT NULL CONSTRAINT DF_Tag_IsSearchable DEFAULT(1),
    IsActive     BIT NOT NULL CONSTRAINT DF_Tag_IsActive DEFAULT(1),
    CONSTRAINT UQ_Tag_TypeValue UNIQUE (TagType, TagValue)
);
GO

CREATE TABLE dbo.ObjectTag (
    ObjectId    INT NOT NULL,
    TagId       INT NOT NULL,
    AddedAt     DATETIME2(0) NOT NULL CONSTRAINT DF_ObjectTag_AddedAt DEFAULT(SYSDATETIME()),
    CONSTRAINT PK_ObjectTag PRIMARY KEY (ObjectId, TagId),
    CONSTRAINT FK_ObjectTag_Object FOREIGN KEY (ObjectId) REFERENCES dbo.[Object](ObjectId),
    CONSTRAINT FK_ObjectTag_Tag FOREIGN KEY (TagId) REFERENCES dbo.Tag(TagId)
);
GO

/* =========================================================
   9) Interaction & Analytics
   ========================================================= */

CREATE TABLE dbo.InteractionLog (
    InteractionId   BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_InteractionLog PRIMARY KEY,
    SessionId       UNIQUEIDENTIFIER NOT NULL,
    UserId          INT NULL,
    ObjectId        INT NOT NULL,
    IdentifierId    INT NOT NULL,
    ZoneId          INT NULL,
    InteractionType NVARCHAR(30) NOT NULL, -- Scan/View/PlayVideo/AudioPlay/Like/Save
    DeviceType      NVARCHAR(30) NOT NULL, -- Android/iOS/Web/Kiosk
    OccurredAt      DATETIME2(0) NOT NULL CONSTRAINT DF_InteractionLog_OccurredAt DEFAULT(SYSDATETIME()),
    DurationSec     INT NULL,
    ExtraMetadata   NVARCHAR(MAX) NULL,
    CONSTRAINT FK_InteractionLog_Session FOREIGN KEY (SessionId) REFERENCES dbo.[Session](SessionId),
    CONSTRAINT FK_InteractionLog_User FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
    CONSTRAINT FK_InteractionLog_Object FOREIGN KEY (ObjectId) REFERENCES dbo.[Object](ObjectId),
    CONSTRAINT FK_InteractionLog_Identifier FOREIGN KEY (IdentifierId) REFERENCES dbo.ObjectIdentifier(IdentifierId),
    CONSTRAINT FK_InteractionLog_Zone FOREIGN KEY (ZoneId) REFERENCES dbo.MuseumZone(ZoneId),
    CONSTRAINT CK_InteractionLog_Type CHECK (InteractionType IN (N'Scan', N'View', N'PlayVideo', N'AudioPlay', N'Like', N'Save'))
);
GO

/* =========================================================
   10) Search & Voice Search
   ========================================================= */

CREATE TABLE dbo.SearchRequest (
    SearchRequestId      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SearchRequest PRIMARY KEY,
    SessionId            UNIQUEIDENTIFIER NOT NULL,
    UserId               INT NULL,
    SearchType           NVARCHAR(10) NOT NULL, -- Text/Voice
    OriginalInput        NVARCHAR(400) NOT NULL,
    DetectedLanguageId   INT NOT NULL,
    ConfidenceScore      DECIMAL(5,4) NULL, -- 0.0000 - 1.0000
    RequestedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_SearchRequest_RequestedAt DEFAULT(SYSDATETIME()),
    DeviceType           NVARCHAR(30) NOT NULL,
    CONSTRAINT FK_SearchRequest_Session FOREIGN KEY (SessionId) REFERENCES dbo.[Session](SessionId),
    CONSTRAINT FK_SearchRequest_User FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
    CONSTRAINT FK_SearchRequest_Language FOREIGN KEY (DetectedLanguageId) REFERENCES dbo.Language(LanguageId),
    CONSTRAINT CK_SearchRequest_Type CHECK (SearchType IN (N'Text', N'Voice'))
);
GO

CREATE TABLE dbo.VoiceInput (
    VoiceInputId         BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VoiceInput PRIMARY KEY,
    SearchRequestId      BIGINT NOT NULL,
    AudioDurationSec     INT NULL,
    AudioFormat          NVARCHAR(20) NULL, -- wav/mp3
    SpeechEngine         NVARCHAR(40) NULL, -- Google/Azure/Local
    TranscriptText       NVARCHAR(400) NOT NULL,
    ConfidenceScore      DECIMAL(5,4) NULL,
    CONSTRAINT UQ_VoiceInput_SearchRequest UNIQUE (SearchRequestId),
    CONSTRAINT FK_VoiceInput_SearchRequest FOREIGN KEY (SearchRequestId) REFERENCES dbo.SearchRequest(SearchRequestId)
);
GO

CREATE TABLE dbo.SearchResult (
    SearchResultId       BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SearchResult PRIMARY KEY,
    SearchRequestId      BIGINT NOT NULL,
    ResultType           NVARCHAR(10) NOT NULL, -- Object/Tag/Content
    ObjectId             INT NULL,
    ContentId            INT NULL,
    TagId                INT NULL,
    RankOrder            INT NOT NULL,
    MatchScore           DECIMAL(6,4) NOT NULL,
    CONSTRAINT FK_SearchResult_SearchRequest FOREIGN KEY (SearchRequestId) REFERENCES dbo.SearchRequest(SearchRequestId),
    CONSTRAINT FK_SearchResult_Object FOREIGN KEY (ObjectId) REFERENCES dbo.[Object](ObjectId),
    CONSTRAINT FK_SearchResult_Content FOREIGN KEY (ContentId) REFERENCES dbo.ContentItem(ContentId),
    CONSTRAINT FK_SearchResult_Tag FOREIGN KEY (TagId) REFERENCES dbo.Tag(TagId),
    CONSTRAINT CK_SearchResult_Type CHECK (ResultType IN (N'Object', N'Tag', N'Content')),
    -- exactly one FK based on ResultType (enforced via CHECK):
    CONSTRAINT CK_SearchResult_OneTarget CHECK (
        (CASE WHEN ObjectId  IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN ContentId IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN TagId     IS NULL THEN 0 ELSE 1 END)
        = 1
    )
);
GO

/* =========================================================
   11) Helpful Indexes
   ========================================================= */

CREATE INDEX IX_ContentItem_Object_Lang_Status ON dbo.ContentItem(ObjectId, LanguageId, [Status]);
CREATE INDEX IX_InteractionLog_Object_OccurredAt ON dbo.InteractionLog(ObjectId, OccurredAt DESC);
CREATE INDEX IX_SearchRequest_RequestedAt_Type ON dbo.SearchRequest(RequestedAt DESC, SearchType);
CREATE INDEX IX_Tag_TagValue ON dbo.Tag(TagValue);
GO

/* =========================================================
   Done
   ========================================================= */
PRINT 'GRADTEST schema created successfully.';
GO

USE GRADTEST;
GO

-- Languages
INSERT INTO Language (Code, Name) VALUES
(N'AR', N'Arabic'),
(N'EN', N'English');

-- Age Groups
INSERT INTO AgeGroup (Name, MinAge, MaxAge) VALUES
(N'Kids', 6, 12),
(N'Teens', 13, 18),
(N'Adults', 19, 60);

-- Education Levels
INSERT INTO EducationLevel (Name, RankOrder) VALUES
(N'Primary', 1),
(N'Secondary', 2),
(N'University', 3);

-- Categories
INSERT INTO Category (Name, Description) VALUES
(N'Statue', N'Ancient statues'),
(N'Artifact', N'Historical artifacts');

-- Eras
INSERT INTO Era (Name, StartYear, EndYear) VALUES
(N'Ancient Egypt', -3000, -30);
GO

-- Roles
INSERT INTO Roles (RoleName, Description) VALUES
(N'Admin', N'System administrator'),
(N'ContentManager', N'Manages museum content'),
(N'RegisteredUser', N'Regular user'),
(N'Guest', N'Guest visitor');

-- Users
INSERT INTO Users (Email, DisplayName)
VALUES
(N'admin@museum.com', N'Museum Admin'),
(N'user1@mail.com', N'Ahmed Ali');

-- User Roles
INSERT INTO UserRole (UserId, RoleId)
SELECT U.UserId, R.RoleId
FROM Users U CROSS JOIN Roles R
WHERE U.Email = N'admin@museum.com' AND R.RoleName = N'Admin';

INSERT INTO UserRole (UserId, RoleId)
SELECT U.UserId, R.RoleId
FROM Users U CROSS JOIN Roles R
WHERE U.Email = N'user1@mail.com' AND R.RoleName = N'RegisteredUser';

-- User Profile
INSERT INTO UserProfile (UserId, AgeGroupId, LevelId, PreferredLanguageId)
SELECT 
    U.UserId,
    AG.AgeGroupId,
    EL.LevelId,
    L.LanguageId
FROM Users U
JOIN AgeGroup AG ON AG.Name = N'Adults'
JOIN EducationLevel EL ON EL.Name = N'University'
JOIN Language L ON L.Code = 'English'
WHERE U.Email = N'user1@mail.com';
GO
USE GRADTEST;
GO

SELECT 
    U.UserId,
    U.Email,
    U.DisplayName,
    U.Phone,
    U.PasswordHash,
    U.IsActive,
    U.CreatedAt,
    U.UpdatedAt,

    UP.AgeGroupId,
    UP.LevelId,
    UP.PreferredLanguageId,
    UP.Interests,
    UP.AccessibilityFlags
FROM dbo.Users U
LEFT JOIN dbo.UserProfile UP
    ON UP.UserId = U.UserId
ORDER BY U.UserId;
INSERT INTO Users (Email, DisplayName)
VALUES
(N'Ahmedwael@mail.com', N'Ahmed ahmned wael');
 INSERT INTO UserProfile (UserId, AgeGroupId, LevelId, PreferredLanguageId)
SELECT 
    U.UserId,
    AG.AgeGroupId,
    EL.LevelId,
    L.LanguageId
FROM Users U
JOIN AgeGroup AG ON AG.Name = N'Adults'
JOIN EducationLevel EL ON EL.Name = N'University'
JOIN Language L ON L.Code = 'English'
WHERE U.Email = N'Ahmedwael@mail.com';
GO

INSERT INTO Users (Email, DisplayName)
VALUES
(N'DrAhmedsalah@museum.com', N'dr Ahmed Salah');
INSERT INTO Users (Email, DisplayName,PasswordHash)
VALUES
(N'mohammed@museum.com', N'mohammed','A123jjj');