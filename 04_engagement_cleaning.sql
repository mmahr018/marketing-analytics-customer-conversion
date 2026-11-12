-- Normalize content type; parse the `Views-Clicks` combined field defensively.
-- Malformed values become NULL instead of triggering LEFT(..., -1) errors.
-- Keep engagement date as DATE, not a formatted string, for reliable time intelligence.
SELECT
    e.EngagementID,
    e.ContentID,
    e.CampaignID,
    e.ProductID,
    CASE
        WHEN UPPER(REPLACE(LTRIM(RTRIM(e.ContentType)), ' ', '')) = 'SOCIALMEDIA'
            THEN 'SOCIAL MEDIA'
        ELSE UPPER(LTRIM(RTRIM(e.ContentType)))
    END AS ContentType,
    CASE WHEN d.delimiter_pos > 0
        THEN TRY_CONVERT(BIGINT, LEFT(e.ViewsClicksCombined, d.delimiter_pos - 1))
    END AS Views,
    CASE WHEN d.delimiter_pos > 0
        THEN TRY_CONVERT(BIGINT, SUBSTRING(e.ViewsClicksCombined, d.delimiter_pos + 1, LEN(e.ViewsClicksCombined)))
    END AS Clicks,
    e.Likes,
    TRY_CONVERT(date, e.EngagementDate) AS EngagementDate
FROM dbo.engagement_data AS e
CROSS APPLY (
    SELECT CHARINDEX('-', e.ViewsClicksCombined) AS delimiter_pos
) AS d
WHERE UPPER(LTRIM(RTRIM(e.ContentType))) <> 'NEWSLETTER';
-- Validate invalid conversions and NULL source dates before downstream reporting.
