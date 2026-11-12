-- Enrich customer records with country and city.
-- LEFT JOIN preserves customers without a matching geography record.
SELECT
    c.CustomerID,
    c.CustomerName,
    c.Email,
    c.Gender,
    c.Age,
    g.Country,
    g.City
FROM dbo.customers AS c
LEFT JOIN dbo.geography AS g
    ON c.GeographyID = g.GeographyID;
-- Privacy note: do not export names/emails to a public repository or dashboard.
