---Code for creating database called Dannys Diner
CREATE DATABASE Dannys_dinerss;
---This is the code for creating the 3 tables in the Dannys Diner Database namely Sales, Menu and Members
CREATE TABLE Sales(
Customer_ID VARCHAR(10) NOT NULL,
Order_Date DATE NOT NULL,
Product_ID INT NOT NULL
);
CREATE TABLE Menu(
Product_ID INT PRIMARY KEY,
Product_Name VARCHAR(10) NOT NULL,
Price INT NOT NULL
);
CREATE TABLE Members(
Customer_ID VARCHAR (10) PRIMARY KEY NOT NULL,
Join_Date DATE NOT NULL
);
--now it is time to populate the tables... starting with the sales table
INSERT INTO Sales (Customer_ID, Order_Date, Product_ID)
VALUES ('A', '2021-01-01', 1),
('A', '2021-01-01', 2),
('A', '2021-01-07', 2),
('A', '2021-01-10', 3),
('A', '2021-01-11', 3),
('A', '2021-01-11', 3),
('B', '2021-01-01', 2),
('B', '2021-01-02', 2),
('B', '2021-01-04', 1),
('B', '2021-01-11', 1),
('B', '2021-01-16', 3),
('B', '2021-02-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-07', 3);
INSERT INTO Menu ( Product_ID, Product_Name, Price)
VALUES 
(1, 'Sushi', 10),
(2, 'Curry', 15),
(3, 'Ramen', 12);
INSERT INTO Members (Customer_ID, Join_Date)
VALUES 
('A', '2021-01-07'),
('B', '2021-01-09');

---Question 1 What is the total amount each customer spent at the restaurant.

SELECT s.Customer_ID, SUM(m.Price) AS TotalAmount
FROM Sales s
JOIN Menu m ON s.Product_ID = m.Product_ID
GROUP BY s.Customer_ID;

--Question 2: How many days has each customer visited the restaurant.

SELECT Customer_ID, COUNT(DISTINCT Order_Date) AS NumOfDaysVisited
FROM Sales
GROUP BY Customer_ID;

--Question 3: What was the first item from the menu purchased by each customer

SELECT DISTINCT s.Customer_ID, o.First_Order_Date, m.Product_ID, m.Product_Name
FROM Sales s
JOIN (SELECT Customer_ID, MIN(Order_Date) AS First_Order_Date
      FROM Sales
      GROUP BY Customer_ID) o
ON o.Customer_ID = s.Customer_ID
AND o.First_Order_Date = s.Order_Date
JOIN Menu m
ON m.Product_ID = s.Product_ID
WHERE s.Order_Date = o.First_Order_Date
ORDER BY s.Customer_ID;


--Question 4:What was the most purchased item on the menu and how many times was it purchased by all customer?

SELECT TOP 1 m.Product_Name, COUNT(*) AS Total_Purchases
FROM Sales s
JOIN Menu m ON s.Product_ID = m.Product_ID
GROUP BY m.Product_Name
ORDER BY Total_Purchases DESC;

-- Queston 4: What item was the most popular for each customer?
SELECT DISTINCT m1.Product_Name, s1.Customer_ID, s1.Total_Purchases
FROM (
    SELECT Customer_ID, Product_ID, COUNT(*) AS Total_Purchases
    FROM Sales
    GROUP BY Customer_ID, Product_ID
) s1
JOIN (
    SELECT Customer_ID, MAX(Total_Purchases) AS Max_Purchases
    FROM (
        SELECT Customer_ID, Product_ID, COUNT(*) AS Total_Purchases
        FROM Sales
        GROUP BY Customer_ID, Product_ID
    ) s2
    GROUP BY Customer_ID
) s3
ON s1.Customer_ID = s3.Customer_ID AND s1.Total_Purchases = s3.Max_Purchases
JOIN Menu m1 ON s1.Product_ID = m1.Product_ID
ORDER BY s1.Customer_ID;

--Queston 6: Which item was purchased first by the cutomer after they have became a member 

WITH Orders_After_Joining AS (
    SELECT s.Customer_ID, s.Product_ID, m.Product_Name, s.Order_Date, mem.Join_Date,
    ROW_NUMBER() OVER (PARTITION BY s.Customer_ID ORDER BY s.Order_Date) AS order_num
    FROM Sales s
    JOIN Members mem ON s.Customer_ID = mem.Customer_ID
    JOIN Menu m ON s.Product_ID = m.Product_ID
    WHERE s.Order_Date >= mem.Join_Date
)
SELECT Customer_ID, Product_ID, Product_Name AS Item_Ordered, Order_Date AS Date_Ordered
FROM Orders_After_Joining
WHERE order_num = 1
ORDER BY Customer_ID;

-- Queston 7: Which item was purchased just before the customer become a member
WITH Orders_Before_Joining AS (
    SELECT s.Customer_ID, s.Product_ID, m.Product_Name, s.Order_Date, mem.Join_Date,
    ROW_NUMBER() OVER (PARTITION BY s.Customer_ID ORDER BY s.Order_Date DESC) AS order_num
    FROM Sales s
    JOIN Members mem ON s.Customer_ID = mem.Customer_ID
    JOIN Menu m ON s.Product_ID = m.Product_ID
    WHERE s.Order_Date < mem.Join_Date
)
SELECT Customer_ID, Product_ID, Product_Name AS Item_Ordered, Order_Date AS Date_Ordered
FROM Orders_Before_Joining
WHERE order_num = 1
ORDER BY Customer_ID;

    --Queston 8: What is the total items and amount spent for each member before they became a memeber
SELECT 
    s.Customer_ID, 
    COUNT(s.Product_ID) AS Total_Items, 
    SUM(m.Price) AS Amount_Spent
FROM 
    Sales s
    INNER JOIN Menu m ON s.Product_ID = m.Product_ID
WHERE 
    s.Order_Date < (
        SELECT Join_Date 
        FROM Members 
        WHERE Customer_ID = s.Customer_ID
    )
GROUP BY 
    s.Customer_ID;

 --Queston 9: If each $1 spent equates to 10 points and sushi has a 2x pionts multiplier - how many points would each customer have 
SELECT 
    s.Customer_ID, 
    SUM(CASE 
        WHEN s.Product_ID = 1 THEN m.Price * 2 
        ELSE m.Price 
    END * 10) AS Total_Points
FROM 
    Sales s
    INNER JOIN Menu m  ON s.Product_ID = m.Product_ID

GROUP BY 
    s.Customer_ID
ORDER BY 
s.Customer_ID;

--Queston 10 : in the first week after a customer joins the program (including thier join date) they earn 2x point on all items,
-- not just Sushi - how many points do Customer A and B have at the end of January?
SELECT 
    s.Customer_ID,
    SUM(
        CASE 
            WHEN s.Order_Date >= mem.Join_Date AND s.Order_Date <= DATEADD(WEEK, 1, mem.Join_Date)
                THEN m.Price * 20 
            WHEN m.Product_ID = 1 
                THEN m.Price * 20 
            ELSE 
                m.Price * 10 
        END
    ) AS Total_Points
FROM 
    Sales s
    INNER JOIN Menu m ON s.Product_ID = m.Product_ID
    INNER JOIN Members mem ON s.Customer_ID = mem.Customer_ID
WHERE 
    s.Order_Date >= '2021-01-01' AND s.Order_Date <= '2021-01-31' AND s.Customer_ID IN ('A', 'B')
GROUP BY 
    s.Customer_ID;

--BONUS QUESTIONS
---#1 JOIN ALL THINGS.
--The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without
---without needing to join to join the underlying tables using SQL.

----Recreate the following table output using the available data.
SELECT 
    s.Customer_ID, 
    s.Order_Date, 
    m.Product_Name, 
    m.Price, 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Members mem 
            WHERE mem.Customer_ID = s.Customer_ID AND mem.Join_Date <= s.Order_Date
        ) THEN 'Y' 
        ELSE 'N' 
    END AS Member
INTO Customer_Members
FROM 
    Sales s
    INNER JOIN Menu m ON s.Product_ID = m.Product_ID
    ORDER BY 
    s.Customer_ID, s.Order_Date, m.Product_Name

---Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for 
---non-member purchases so he expect NULL ranking values for the records when customers are not yet part of the loyalty program.

SELECT *,
CASE WHEN Member = 'Y' THEN
RANK() OVER(PARTITION BY Customer_ID, Member ORDER BY Order_Date)
END AS ranking
FROM Customer_Members
WITH FirstPurchase AS (
  SELECT  DISTINCT Customer_ID, Product_ID, MIN(Order_Date) AS FirstPurchaseDate, Order_Date
  FROM Sales
  GROUP BY Customer_ID
)
SELECT FirstPurchase.Customer_ID, FirstPurchase.FirstPurchaseDate, FirstPurchase.Product_ID, 
Menu.Product_Name AS FirstPurchaseItem 
FROM FirstPurchase
JOIN Menu ON FirstPurchase.Product_ID = Menu.Product_ID
WHERE FirstPurchaseDate = Order_Date
ORDER BY Customer_ID
