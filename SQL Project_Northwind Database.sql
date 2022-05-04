--Customer Grouping
--Request: Categorize customers into groups, based on how much they ordered in 2016. 
--The customer grouping categories are 
--0 to 1000: Low, 
--1000 to 5000: Medium, 
--5000 to 10000: High, 
--over 10000: Very High.

-- Customer Grouping with Customer and Order details
DROP VIEW IF EXISTS Customer_Grouping;

CREATE VIEW Customer_Grouping AS
WITH Cust_Group AS 
(
SELECT 
a.CustomerID, a.CompanyName AS CustomerName,
SUM(c.UnitPrice * c.Quantity) as Order_Amount
FROM [Northwind].[dbo].Customers a
JOIN [Northwind].[dbo].Orders b
ON a.CustomerID = b.CustomerID 
JOIN [Northwind].[dbo].OrderDetails c
ON c.OrderID = b.OrderID
WHERE YEAR(b.OrderDate) = 2016
GROUP BY a.CustomerID, a.CompanyName
)
SELECT Cust_Group.*, 
CASE 
WHEN Order_Amount >= 0 and Order_Amount < 1000 THEN 'Low'
WHEN Order_Amount >= 1000 and Order_Amount < 5000 THEN 'Medium'
WHEN Order_Amount >= 5000 and Order_Amount < 10000 THEN 'High'
ELSE 'Very high' END AS CustomerGroup
FROM Cust_Group;

SELECT * FROM Customer_Grouping

-- Customer Grouping with Counts and Percentage for each group
DROP VIEW IF EXISTS Customer_Grouping_Percentage;

CREATE VIEW Customer_Grouping_Percentage AS
WITH Cust_Group AS 
(
SELECT a.CustomerID, a.CompanyName AS CustomerName, 
SUM(c.UnitPrice * c.Quantity) AS Order_Amount
FROM [Northwind].[dbo].Customers a
JOIN [Northwind].[dbo].Orders b
ON a.CustomerID = b.CustomerID 
JOIN [Northwind].[dbo].OrderDetails c
ON c.OrderID = b.OrderID
WHERE YEAR(b.OrderDate) = 2016
GROUP BY a.CustomerID, a.CompanyName
),
Cust_Group_Percent AS
(
SELECT Cust_Group.*, 
CASE 
WHEN Order_Amount >= 0 and Order_Amount < 1000 THEN 'Low'
WHEN Order_Amount >= 1000 and Order_Amount < 5000 THEN 'Medium'
WHEN Order_Amount >= 5000 and Order_Amount < 10000 THEN 'High'
ELSE 'Very high' END AS Cust_Group
FROM Cust_Group
)
SELECT Cust_Group, Count_group = COUNT(Cust_Group),
Group_percent = COUNT(Cust_Group)*1.00/(SELECT COUNT(*) FROM Cust_Group)
FROM Cust_Group_Percent
GROUP BY Cust_Group;

SELECT * FROM Customer_Grouping_Percentage