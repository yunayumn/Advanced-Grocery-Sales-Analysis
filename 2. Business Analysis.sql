-- 1. Identify the product category that generates the highest revenue after discount.

-- Calculating total Revenue SUM, total RevenueAfterDiscount SUM, and RevenuePerDiscount for each category

SELECT
    c.CategoryName,
    SUM(s.Quantity * p.Price) AS RevenueRaw,
    SUM(s.Quantity * p.Price * (1 - s.Discount)) AS RevenueAfterDiscount,
    ((SUM(s.Quantity * p.Price))/( SUM(Discount))) AS RevenuePerDiscount
FROM
    mydatabase.main.sales AS s
JOIN
    mydatabase.main.products AS p
    ON s.ProductID = p.ProductID
JOIN
    mydatabase.main.categories AS c
    ON p.CategoryID = c.CategoryID
GROUP BY
    c.CategoryName
ORDER BY
    RevenueAfterDiscount DESC;

-- 2. Assess the relation between revenue after discount and total units sold for each product category.

-- Comparing the SUM of RevenueAfterDiscount and SUM of Quantity sold for each category

SELECT
    c.CategoryName,
    SUM(s.Quantity * p.Price * (1 - s.Discount)) AS RevenueAfterDiscount,
    SUM(s.Quantity) AS TotalUnitsSold,
    (SUM(s.Quantity * p.Price * (1 - s.Discount))/SUM(s.Quantity)) AS RevenuePerUnitSold
FROM
    mydatabase.main.sales AS s
JOIN
    mydatabase.main.products AS p
    ON s.ProductID = p.ProductID
JOIN
    mydatabase.main.categories AS c
    ON p.CategoryID = c.CategoryID
GROUP BY
    c.CategoryName
ORDER BY
    RevenueAfterDiscount DESC;

-- 3. Find the relation between revenue after discount and the number of unique customers for each product category.

-- Comparing the SUM of RevenueAfterDiscount and COUNT DISTINCT of CustomerID

SELECT
    c.CategoryName,
    SUM(s.Quantity * p.Price * (1 - s.Discount)) AS RevenueAfterDiscount,
    COUNT(DISTINCT s.CustomerID) AS UniqueCustomers,
    (SUM(s.Quantity * p.Price * (1 - s.Discount))/COUNT(DISTINCT s.CustomerID)) AS RevenuePerAverageCustomer
FROM
    mydatabase.main.sales AS s
JOIN
    mydatabase.main.products AS p
    ON s.ProductID = p.ProductID
JOIN
    mydatabase.main.categories AS c
    ON p.CategoryID = c.CategoryID
GROUP BY
    c.CategoryName
ORDER BY
    RevenueAfterDiscount DESC;

-- 4. Calculate the average price per unit for each product category in the catalog.

-- Calculating AVERAGE Price point for each category

SELECT
    c.CategoryName,
    AVG(p.Price) AS AveragePricePerUnit
FROM
    mydatabase.main.products AS p
JOIN
    mydatabase.main.categories AS c
    ON p.CategoryID = c.CategoryID
GROUP BY
    c.CategoryName
ORDER BY
    AveragePricePerUnit DESC;

-- 5. Evaluate the relation between the average price per unit and the number of buyers (unique customers) per category.

-- Comparing the AVERAGE Price point and the COUNT DISTINCT of CustomerID for each category

SELECT
    c.CategoryName,
    AVG(p.Price) AS AveragePricePerUnit,
    COUNT(DISTINCT s.CustomerID) AS UniqueCustomers
FROM
    mydatabase.main.sales AS s
JOIN
    mydatabase.main.products AS p
    ON s.ProductID = p.ProductID
JOIN
    mydatabase.main.categories AS c
    ON p.CategoryID = c.CategoryID
GROUP BY
    c.CategoryName
ORDER BY
    AveragePricePerUnit DESC;

-- 6. Which categories contribute the most to overall revenue after discount (percentage-wise)?

-- Calculates the % of Revenue SUM for each category (after discount)


WITH CategoryRevenue AS (
    SELECT
        c.CategoryName,
        SUM(s.Quantity * p.Price * (1 - s.Discount)) AS RevenueAfterDiscount
    FROM
        mydatabase.main.sales AS s
    JOIN
        mydatabase.main.products AS p
        ON s.ProductID = p.ProductID
    JOIN
        mydatabase.main.categories AS c
        ON p.CategoryID = c.CategoryID
    GROUP BY
        c.CategoryName
)
SELECT
    CategoryName,
    RevenueAfterDiscount,
    (RevenueAfterDiscount * 100.0 /
            (SELECT
                SUM(RevenueAfterDiscount)
            FROM
                CategoryRevenue)) AS PercentageOfTotalRevenue
FROM
    CategoryRevenue
ORDER BY
    PercentageOfTotalRevenue DESC;

-- 7. Which product categories have the highest repeat purchase rate?

-- Repeat purchase rate for each category = COUNT customers with more than 1 transaction / COUNT DISTINCT customers

WITH CustomerCategoryPurchases AS (
    SELECT
        s.CustomerID,
        p.CategoryID,
        COUNT(DISTINCT s.OrderID) AS PurchaseCount
    FROM
        Sales AS s
    JOIN
        Products AS p
        ON s.ProductID = p.ProductID
    GROUP BY
        s.CustomerID,
        p.CategoryID
), RepeatCustomersPerCategory AS (
    SELECT
        CategoryID,
        COUNT(DISTINCT CustomerID) AS RepeatCustomerCount
    FROM
        CustomerCategoryPurchases
    WHERE
        PurchaseCount > 1
    GROUP BY
        CategoryID
), TotalCustomersPerCategory AS (
    SELECT
        p.CategoryID,
        COUNT(DISTINCT s.CustomerID) AS TotalCustomerCount
    FROM
        Sales AS s
    JOIN
        Products AS p
        ON s.ProductID = p.ProductID
    GROUP BY
        p.CategoryID
)
SELECT
    c.CategoryName,
    COALESCE(rc.RepeatCustomerCount, 0) as RepeatCustomers,
    tc.TotalCustomerCount,
    (
        COALESCE(rc.RepeatCustomerCount, 0) * 100.0 / tc.TotalCustomerCount
    ) AS RepeatPurchaseRate
FROM
    Categories AS c
LEFT JOIN
    RepeatCustomersPerCategory AS rc
    ON c.CategoryID = rc.CategoryID
JOIN
    TotalCustomersPerCategory AS tc
    ON c.CategoryID = tc.CategoryID
ORDER BY
    RepeatPurchaseRate DESC;

-- 9. Find the cumulative amount of transaction of the top user (user with highest transaction value)

-- Ranking top 1 customer using RANK() then counting the SUM of sales over all time periods

WITH Top1Customer AS (
  SELECT
    s.CustomerID,
    SUM(s.Quantity * p.Price * (1 - s.Discount)) AS TotalSpent,
    RANK() OVER (ORDER BY SUM(s.Quantity * p.Price * (1 - s.Discount)) DESC) AS Ranking
  FROM
    `fsda-sql-01.grocery_dataset.sales` AS s
  JOIN
    `fsda-sql-01.grocery_dataset.products` AS p
  ON s.ProductID = p.ProductID
  JOIN
    `fsda-sql-01.grocery_dataset.customers` AS cu
  ON s.CustomerID = cu.CustomerID
  GROUP BY
    s.CustomerID
),
revenue AS (
  SELECT
    s.CustomerID,
    s.SalesDate,
    SUM(s.Quantity * p.Price * (1 - s.Discount)) AS Revenue
  FROM
    `fsda-sql-01.grocery_dataset.sales` AS s
  JOIN
    `fsda-sql-01.grocery_dataset.products` AS p
  ON s.ProductID = p.ProductID
  JOIN
    `fsda-sql-01.grocery_dataset.customers` AS cu
  ON s.CustomerID = cu.CustomerID
  JOIN Top1Customer AS t
  ON s.CustomerID = t.CustomerID
  WHERE t.Ranking = 1
  GROUP BY s.CustomerID, s.SalesDate
)
SELECT
  CustomerID,
  SalesDate,
  ROUND(Revenue, 2) AS Revenue,
  ROUND(SUM(Revenue) OVER (ORDER BY SalesDate), 2) AS CumulativeRevenue
FROM
  revenue
ORDER BY
  SalesDate;
