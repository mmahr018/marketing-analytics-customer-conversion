-- Normalize stage, retain the earliest JourneyID per logical journey key,
-- then calculate date-level average duration from deduplicated records.
-- Confirm that these columns define true duplicates for your business context.
WITH normalized AS (
    SELECT
        j.JourneyID,
        j.CustomerID,
        j.ProductID,
        j.VisitDate,
        UPPER(LTRIM(RTRIM(j.Stage))) AS Stage,
        j.[Action] AS [Action],
        j.Duration,
        ROW_NUMBER() OVER (
            PARTITION BY j.CustomerID, j.ProductID, j.VisitDate,
                         UPPER(LTRIM(RTRIM(j.Stage))), j.[Action]
            ORDER BY j.JourneyID
        ) AS row_num
    FROM dbo.customer_journey AS j
),
deduplicated AS (
    SELECT JourneyID, CustomerID, ProductID, VisitDate, Stage, [Action], Duration
    FROM normalized
    WHERE row_num = 1
)
SELECT
    JourneyID,
    CustomerID,
    ProductID,
    VisitDate,
    Stage,
    [Action],
    COALESCE(
        CAST(Duration AS DECIMAL(18,2)),
        AVG(CAST(Duration AS DECIMAL(18,2))) OVER (PARTITION BY VisitDate)
    ) AS Duration
FROM deduplicated;
-- If every record on a date has NULL duration, the imputed value remains NULL.
