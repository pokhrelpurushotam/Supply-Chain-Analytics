-- ============================================================
-- SUPPLY CHAIN ANALYTICS — SQL QUERIES
-- Author: Puru Pokhrel
-- Database: SQL Server (logisticsDB)
-- Dataset: 6 tables — Shipments (17,124), Orders (6,899), 
--          Inventory (630), Carriers (10), Products (6), Warehouses (3)
-- Project: End-to-End Supply Chain Performance Dashboard
-- ============================================================


-- ============================================================
-- SECTION 1: FREIGHT & CARRIER PERFORMANCE
-- ============================================================


-- Q1: Carrier Cost & Volume Summary
-- Business Question: How much total freight cost did each carrier 
-- generate, and how many shipments did they handle?
-- Concepts: SUM, COUNT, GROUP BY, ORDER BY, ROUND
-- ============================================================

SELECT Carrier, 
       ROUND(SUM(Total_Freight_Cost), 2) AS Total_Cost, 
       COUNT(Shipment_ID) AS Number_of_Shipments
FROM Shipments
GROUP BY Carrier
ORDER BY Total_Cost DESC;


-- Q2: High-Volume Carrier Filter
-- Business Question: Which carriers handled more than 1,700 shipments?
-- Concepts: HAVING (filters groups, unlike WHERE which filters rows)
-- ============================================================

SELECT Carrier, 
       COUNT(*) AS Shipments
FROM Shipments
GROUP BY Carrier
HAVING COUNT(*) > 1700;


-- Q3: On-Time Delivery Scorecard
-- Business Question: What is each carrier's OTD percentage?
-- Who is the worst performer?
-- Concepts: CAST, AVG trick on 0/1 columns, FLOAT division
-- ============================================================

SELECT Carrier, 
       COUNT(Shipment_ID) AS Load_Volume, 
       ROUND(SUM(CAST(On_Time_Delivery AS FLOAT)) / COUNT(On_Time_Delivery) * 100, 2) AS OTD_Pct
FROM Shipments
GROUP BY Carrier
ORDER BY OTD_Pct ASC;


-- Q4: Monthly Freight Spend Trend
-- Business Question: How has freight spend changed month over month?
-- Are there seasonal patterns?
-- Concepts: FORMAT (date extraction), time-series grouping
-- ============================================================

SELECT FORMAT(Ship_Date, 'yyyy-MM') AS Month,
       ROUND(SUM(Total_Freight_Cost), 2) AS Total_Cost,
       COUNT(Shipment_ID) AS Load_Volume
FROM Shipments
GROUP BY FORMAT(Ship_Date, 'yyyy-MM')
ORDER BY FORMAT(Ship_Date, 'yyyy-MM') ASC;


-- Q5: Carrier vs. Contract Target Comparison
-- Business Question: Are carriers meeting their contractual OTD targets?
-- Who is underperforming the most?
-- Concepts: JOIN (combining two tables), calculated gap analysis
-- ============================================================

SELECT S.Carrier, 
       ROUND(SUM(CAST(S.On_Time_Delivery AS FLOAT)) / COUNT(S.On_Time_Delivery) * 100, 2) AS Actual_OTD,
       ROUND(C.Target_OTD_Pct * 100, 2) AS Target_OTD,
       ROUND(SUM(CAST(S.On_Time_Delivery AS FLOAT)) / COUNT(S.On_Time_Delivery) * 100 - C.Target_OTD_Pct * 100, 2) AS Gap
FROM Shipments S
JOIN Carriers C ON S.Carrier = C.Carrier
GROUP BY S.Carrier, C.Target_OTD_Pct
ORDER BY Gap ASC;


-- ============================================================
-- SECTION 2: ORDER FULFILLMENT & CUSTOMER ANALYSIS
-- ============================================================


-- Q6: Customer Fulfillment Rate
-- Business Question: What percentage of each customer's orders 
-- were fully fulfilled? Who has the worst fulfillment rate?
-- Concepts: CASE WHEN (conditional logic), percentage calculation
-- ============================================================

SELECT Customer_Name,
       SUM(CASE WHEN Fulfillment_Status = 'Fulfilled' THEN 1 ELSE 0 END) AS Fulfilled_Orders, 
       COUNT(Order_ID) AS Total_Orders, 
       ROUND(CAST(SUM(CASE WHEN Fulfillment_Status = 'Fulfilled' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(Order_ID) * 100, 2) AS Fulfillment_Rate
FROM orders
GROUP BY Customer_Name
ORDER BY Fulfillment_Rate ASC;


-- ============================================================
-- SECTION 3: DATA EXPLORATION & VALIDATION
-- ============================================================


-- Q7: Combine All Locations (Warehouses + Shipment Destinations)
-- Business Question: What is the full list of locations in our network?
-- Concepts: UNION ALL (stacks results, keeps duplicates)
--           vs UNION (stacks results, removes duplicates)
-- ============================================================

SELECT Location AS All_Locations FROM warehouses
UNION
SELECT Destination FROM Shipments;


-- Q8: Table Row Counts (Data Validation)
-- Concepts: UNION ALL for combining multiple counts
-- ============================================================

SELECT 'Shipments' AS Table_Name, COUNT(*) AS Rows FROM Shipments
UNION ALL
SELECT 'Carriers', COUNT(*) FROM Carriers
UNION ALL
SELECT 'Warehouses', COUNT(*) FROM warehouses
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Inventory', COUNT(*) FROM inventory
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders;


-- ============================================================
-- SQL CONCEPTS REFERENCE (Interview Prep)
-- ============================================================
--
-- EXECUTION ORDER:  FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
--
-- GROUP BY RULE:    Every column in SELECT must be either:
--                   (1) in the GROUP BY clause, or
--                   (2) inside an aggregate function (SUM, AVG, COUNT, etc.)
--
-- WHERE vs HAVING:  WHERE filters rows BEFORE grouping
--                   HAVING filters groups AFTER grouping
--
-- UNION vs UNION ALL: UNION removes duplicates (slower)
--                     UNION ALL keeps everything (faster)
--
-- CAST vs CONVERT:  CAST is standard SQL (works everywhere)
--                   CONVERT is SQL Server only (extra date formatting)
--
-- INTEGER DIVISION: 471/601 = 0 (not 0.78!)
--                   Fix: CAST to FLOAT, or multiply by 100.0
--
-- NULL HANDLING:    COUNT(*) counts NULLs, COUNT(column) skips them
--                   SUM, AVG, MIN, MAX all skip NULLs
-- ============================================================
