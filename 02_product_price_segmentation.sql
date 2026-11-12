-- Transparent product price bands.
-- The boundaries are analysis-specific assumptions and should be documented.
SELECT
    p.ProductID,
    p.ProductName,
    p.Price,
    CASE
        WHEN p.Price IS NULL THEN 'Unknown'
        WHEN p.Price < 50 THEN 'Low'
        WHEN p.Price <= 200 THEN 'Medium'
        ELSE 'High'
    END AS PriceCategory
FROM dbo.products AS p;
