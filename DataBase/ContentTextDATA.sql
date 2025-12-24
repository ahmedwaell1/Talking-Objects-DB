USE GRADTEST;
GO
SET NOCOUNT ON;
GO

BEGIN TRY
    BEGIN TRAN;

    INSERT INTO dbo.ContentText
    (
        ContentId,
        Title,
        Body,
        ReadingTimeSec
    )
    SELECT
        ci.ContentId,

        -- Title
        CONCAT(
            N'In-depth interpretation of object ',
            ci.ObjectId,
            N' (Content v', ci.VersionNo, N')'
        ),

        -- Body (LLM-grade, long, mixed language)
        CONCAT(
            N'Paragraph 1: This museum object represents a significant historical artifact associated with object ID ',
            ci.ObjectId,
            N'. It reflects the technological, artistic, and cultural conditions of its era. ',

            N'Paragraph 2: Researchers have studied this artifact to understand materials, craftsmanship, and symbolic meaning. ',
            N'The object contributes to broader academic discussions in archaeology, anthropology, and art history. ',

            N'Paragraph 3: From an educational perspective, this content is structured to support learners of different ages and backgrounds. ',
            N'Key concepts are explained using accessible language while preserving academic accuracy. ',

            N'Paragraph 4: For intelligent retrieval systems, the text intentionally includes semantic variety, synonyms, and contextual cues. ',
            N'This improves vector embeddings, similarity search, and large language model responses. ',

            N'Paragraph 5: Visitor-oriented narrative — Imagine standing in front of this object in a museum gallery, ',
            N'observing fine details, textures, and inscriptions that tell stories of ancient societies. ',

            N'Paragraph 6 (Arabic): هذا وصف عربي يوضح أهمية القطعة الأثرية ودورها التاريخي والثقافي، ',
            N'ويساعد أنظمة الذكاء الاصطناعي على دعم البحث متعدد اللغات واسترجاع المعرفة بدقة أعلى. ',

            N'Keywords: museum, artifact, heritage, archaeology, culture, history, education, research, semantic search, LLM.'
        ),

        -- Reading time (realistic)
        180 + (ABS(CHECKSUM(NEWID())) % 240)

    FROM dbo.ContentItem ci
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.ContentText ct
        WHERE ct.ContentId = ci.ContentId
    );

    COMMIT;
    PRINT N'✅ ContentText inserted with LONG LLM-grade bodies.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;
GO
