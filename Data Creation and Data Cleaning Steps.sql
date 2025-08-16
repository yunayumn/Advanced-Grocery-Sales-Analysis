-- Creating a database for the dataset

CREATE TABLE main.sales AS 
SELECT * FROM read_csv_auto('D:\DATA\Grocery\sales.csv')

CREATE TABLE main.categories AS 
SELECT * FROM read_csv_auto('D:\DATA\Grocery\categories.csv')

CREATE TABLE main.products AS 
SELECT * FROM read_csv_auto('D:\DATA\Grocery\products.csv')

CREATE TABLE main.customers AS 
SELECT * FROM read_csv_auto('D:\DATA\Grocery\customers.csv')

CREATE TABLE main.cities AS 
SELECT * FROM read_csv_auto('D:\DATA\Grocery\cities.csv')

CREATE TABLE main.countries AS 
SELECT * FROM read_csv_auto('D:\DATA\Grocery\countries.csv')

CREATE TABLE main.employees AS 
SELECT * FROM read_csv_auto('D:\DATA\Grocery\employees.csv')

-- Mini EDA

-- Checking the number of transactions

SELECT
	COUNT(*)
FROM
	mydatabase.main.sales AS s
JOIN
	mydatabase.main.products AS p
	ON s.ProductID = p.ProductID
JOIN
	mydatabase.main.customers AS cu
	ON s.CustomerID = cu.CustomerID;

-- Checking the number of products sold by RevoGrocers

SELECT
	COUNT(*)
FROM
	mydatabase.main.products AS p
JOIN
	mydatabase.main.categories AS c
	ON p.CategoryID = c.CategoryID;

-- Data Cleaning (when necessary)

-- Check IsAllergic column type from products table
SELECT
    IsAllergic
FROM
    mydatabase.main.products;

-- Setting 'Unknown' value to NULL
UPDATE mydatabase.main.products
SET IsAllergic = NULL
WHERE IsAllergic = 'Unknown';

-- Alter column type to Boolean
ALTER TABLE mydatabase.main.products
ALTER COLUMN IsAllergic TYPE BOOLEAN
	USING CAST(IsAllergic AS BOOLEAN);

-- Check for any product price (if any is below 0 or negative value)
SELECT
    ProductID,
    ProductName,
    Price
FROM
    mydatabase.main.products
WHERE
    Price <= 0;

-- Now we move on to check sales table (crucial step)

-- Check if quantity below zero
SELECT
    *
FROM
    mydatabase.main.sales
WHERE
    Quantity <= 0;

-- Check if any discount values are an anomaly (less than 0 or more than 1)
SELECT
    *
FROM
    mydatabase.main.sales
WHERE
    Discount < 0 OR Discount > 1;

-- Standardizing of column names from all tables
-- This step is optional and later depends on the company needs
-- Data is clean and ready to use!