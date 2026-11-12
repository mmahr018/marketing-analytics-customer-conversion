-- Trim review text and collapse repeated spaces (up to four spaces in a run).
-- For arbitrary whitespace / tabs / newlines, consider cleaning in Python or Power Query.
SELECT
    r.ReviewID,
    r.CustomerID,
    r.ProductID,
    r.ReviewDate,
    r.Rating,
    LTRIM(RTRIM(REPLACE(REPLACE(r.ReviewText, '  ', ' '), '  ', ' '))) AS ReviewText
FROM dbo.customer_reviews AS r;
