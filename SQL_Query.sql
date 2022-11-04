USE WideWorldImporters
GO

--1
SELECT p.FullName,p.PhoneNumber,p.FaxNumber, c.CustomerName as Company_Name
FROM Application.People p JOIN Sales.Customers c ON p.PersonID = c.CustomerID

--2

SELECT c.CustomerName AS Company_Name
FROM Sales.Customers c LEFT JOIN Application.People p ON c.PrimaryContactPersonID = p.PersonID
WHERE c.PhoneNumber = p.PhoneNumber;

--3
SELECT CustomerName
FROM(SELECT c.CustomerID, o.OrderDate,c.CustomerName,
     ROW_NUMBER() OVER(PARTITION BY c.CustomerID ORDER BY o.OrderDate desc) as rank_num 
     FROM Sales.Customers c JOIN Sales.Orders o ON c.CustomerID = o.CustomerID) new_table
WHERE rank_num = 1 and OrderDate < '2016-01-01'

--4 
SELECT StockItemID, sum(ReceivedOuters*QuantityPerOuter) AS Total_Quantity
FROM (SELECT s.StockItemID, p1.ReceivedOuters,s.QuantityPerOuter
	  FROM Purchasing.PurchaseOrderLines p1 JOIN Warehouse.StockItems s ON p1.StockItemID = s.StockItemID
      JOIN Purchasing.PurchaseOrders p2 ON p1.PurchaseOrderID = p2.PurchaseOrderID
      WHERE year(p2.OrderDate) = 2013) AS A
GROUP BY StockItemID;


--5
SELECT DISTINCT StockItemID
FROM Purchasing.PurchaseOrderLines 
WHERE len(Description) >= 10;

--6
SELECT DISTINCT s1.StockItemID,s1.StockItemName
FROM Warehouse.StockItems s1 
JOIN Warehouse.StockItemTransactions s2 ON s1.StockItemID = s2.StockItemID
JOIN Purchasing.Suppliers p ON s1.SupplierID = p.SupplierID 
JOIN Application.Cities c ON p.DeliveryCityID = c.CityID 
JOIN Application.StateProvinces sp ON c.StateProvinceID = sp.StateProvinceID
WHERE year(s2.TransactionOccurredWhen) = 2014 and sp.StateProvinceName not in ('Alabama' , 'Georgia');


--7 
WITH Delivery as (SELECT sp.StateProvinceName, DATEDIFF(DAY,o.OrderDate,
                  cast(i.ConfirmedDeliveryTime as date)) as delivery_day
                  FROM Sales.Orders o JOIN Sales.Invoices i ON i.OrderID = o.OrderID
				  JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
                  JOIN Application.Cities ct ON c.DeliveryCityID = ct.CityID
                  FULL JOIN Application.StateProvinces sp ON ct.StateProvinceID = sp.StateProvinceID)

SELECT StateProvinceName, avg(delivery_day) as Average_delivery_day
FROM Delivery
GROUP BY StateProvinceName
ORDER BY Average_delivery_day DESC;

--8 
WITH Delivery as (SELECT sp.StateProvinceName, 
                  DATEDIFF(MONTH,o.OrderDate,cast(i.ConfirmedDeliveryTime as date)) as delivery_day
                  FROM Sales.Orders o JOIN Sales.Invoices i ON i.OrderID = o.OrderID
                  JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
                  JOIN Application.Cities ct ON c.DeliveryCityID = ct.CityID
                  FULL JOIN Application.StateProvinces sp ON ct.StateProvinceID = sp.StateProvinceID)

SELECT StateProvinceName, avg(delivery_day) as Average_delivery_month
FROM Delivery
GROUP BY StateProvinceName
ORDER BY Average_delivery_month;


--9
WITH new_table as (SELECT SUM(cast(p.ReceivedOuters * st.QuantityPerOuter as bigint)) as purchase_total,st.StockItemID
                   FROM Warehouse.StockItems st JOIN Purchasing.PurchaseOrderLines p ON p.StockItemID = st.StockItemID 
                   WHERE year(p.LastReceiptDate) = 2015
                   GROUP BY st.StockItemID)

SELECT StockItemID
FROM(SELECT s.StockItemID, sum(n.purchase_total) as purchase, sum(s.Quantity) as sold
     FROM Sales.OrderLines s JOIN new_table n ON s.StockItemID = n.StockItemID
     WHERE year(s.PickingCompletedWhen) = 2015
     GROUP BY s.StockItemID) AS A
     WHERE purchase > sold



--10

WITH Mug_sold AS (SELECT CustomerID 
FROM (SELECT o.CustomerID, sum(ol.Quantity) as mug_sold_quantity
      FROM Sales.Orders o JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
      JOIN Warehouse.StockItems s ON s.StockItemID = ol.StockItemID
      JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
      WHERE s.StockItemName like '%mug%'
      GROUP BY o.CustomerID) AS Q_table
WHERE mug_sold_quantity < 10)

SELECT c.CustomerName,c.PhoneNumber, p.FullName as Primary_contact_person_name
FROM Sales.Customers c JOIN Application.People p ON c.PrimaryContactPersonID = p.PersonID
WHERE c.CustomerID in (SELECT * FROM Mug_sold);



--11
SELECT CityName
FROM Application.Cities
WHERE ValidFrom > '2015-01-01';

--12 
SELECT s.StockItemName,c.DeliveryAddressLine1,c.DeliveryAddressLine2, 
sp.StateProvinceName, ct.CityName,co.CountryID,c.CustomerName,p.FullName,c.PhoneNumber
FROM Sales.Orders o JOIN Sales.OrderLines o1 ON o.OrderID = o1.OrderID
JOIN Warehouse.StockItems s ON s.StockItemID = o1.StockItemID
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
JOIN Application.People p ON c.PrimaryContactPersonID = p.PersonID
JOIN Application.Cities ct ON ct.CityID = c.DeliveryCityID
JOIN Application.StateProvinces sp ON sp.StateProvinceID = ct.StateProvinceID
JOIN Application.Countries co ON co.CountryID = sp.CountryID
WHERE o.OrderDate = '2014-07-01'


--13
WITH PurchaseTotal as (SELECT SUM(cast(p.ReceivedOuters * st.QuantityPerOuter as bigint)) as purchase_total,st.StockItemID
                       FROM Warehouse.StockItems st JOIN Purchasing.PurchaseOrderLines p ON p.StockItemID = st.StockItemID 
                       GROUP BY st.StockItemID)

SELECT s2.StockGroupID, sum(p.purchase_total) as total_quantity_total, sum(o.Quantity) as total_quantity_sold, 
sum(p.purchase_total)-sum(o.Quantity) as remaining_stock_quantity
FROM Warehouse.StockItems s1 LEFT JOIN Warehouse.StockItemStockGroups s2 ON s1.StockItemID = s2.StockItemID 
JOIN PurchaseTotal p ON p.StockItemID = s1.StockItemID JOIN Sales.OrderLines o ON o.StockItemID = s1.StockItemID
GROUP BY s2.StockGroupID;


--14 

WITH Max_city_item as (SELECT Cityid, MAX(Delivery_time) as Max_stock_item
                       FROM (SELECT ct.CityID, s.StockItemID, sum(o.OrderID) as Delivery_time
					         FROM Sales.Customers c JOIN Application.Cities ct ON c.DeliveryCityID = ct.CityID
							 JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
							 JOIN Sales.OrderLines ol ON ol.OrderID = o.OrderID
							 JOIN Warehouse.StockItems s ON s.StockItemID = ol.StockItemID
							 WHERE YEAR(o.ExpectedDeliveryDate) = 2016
							 GROUP BY ct.CityID, s.StockItemID) as A
						GROUP BY CityID)

SELECT c.CityID,c.CityName,
(CASE WHEN m.Max_stock_item IS NULL THEN 'NO SALES'
      ELSE str(m.Max_stock_item) END) AS City_max_stock_item
FROM Application.Cities c LEFT JOIN Max_city_item m ON c.CityID = m.CityID
ORDER BY m.Max_stock_item desc;

--15
SELECT OrderID
FROM(SELECT OrderID, count(DeliveryMethodID) as delivery_time
     FROM Sales.Invoices
     GROUP by OrderID) AS A
where delivery_time > 1;

-- 16 
SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE CustomFields like '%China%';


--17
SELECT Country_Of_Manufacture ,sum(Quantity) as Total_Quantity
FROM (SELECT ol.Quantity, s.StockItemID, 
case when s.CustomFields like '%China%' then 'China'
     when s.CustomFields like '%Japan%' then 'Japan'
	 else 'USA' END AS Country_Of_Manufacture
FROM Sales.OrderLines ol JOIN Sales.Orders o ON o.OrderID = ol.OrderID
JOIN Warehouse.StockItems s  ON s.StockItemID = ol.StockItemID
WHERE year(o.OrderDate) = 2015) AS New_table
GROUP BY Country_Of_Manufacture;


--18 
Create VIEW Stockgroup_year AS

WITH Stock_sold_year AS (SELECT StockGroupName, Sold_year,sum(Quantity) as Quantity_year
                         FROM (SELECT s3.StockGroupName,year(o.OrderDate) as Sold_year, ol.Quantity
	                           FROM Sales.OrderLines ol JOIN Sales.Orders o ON ol.OrderID = o.OrderID
                               JOIN Warehouse.StockItems s ON ol.StockItemID = s.StockItemID
                               JOIN Warehouse.StockItemStockGroups s2 ON s2.StockItemID = s.StockItemID
                               JOIN Warehouse.StockGroups s3 ON s2.StockGroupID = s3.StockGroupID) AS new_table
                         GROUP BY Sold_year,StockGroupName)

SELECT *
FROM Stock_sold_year
PIVOT(
  SUM(Quantity_year) FOR Sold_year IN([2013],[2014],[2015],[2016])
) AS Stock_sold_year_pivot;

--Display the View 
SELECT *
FROM Stockgroup_year;



--19
Create VIEW Stock_year AS

WITH Stock_sold_year1 AS (SELECT StockGroupID, Sold_year,sum(Quantity) as Quantity_year
                          FROM (SELECT s3.StockGroupID,year(o.OrderDate) as Sold_year, ol.Quantity
                                FROM Sales.OrderLines ol JOIN Sales.Orders o ON ol.OrderID = o.OrderID
                                JOIN Warehouse.StockItems s ON ol.StockItemID = s.StockItemID
                                JOIN Warehouse.StockItemStockGroups s2 ON s2.StockItemID = s.StockItemID
                                JOIN Warehouse.StockGroups s3 ON s2.StockGroupID = s3.StockGroupID) AS new_table
                                GROUP BY Sold_year,StockGroupID),
Stock_pivot as  (SELECT *
FROM Stock_sold_year1
PIVOT(
  SUM(Quantity_year) FOR StockGroupID IN([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
) AS Stock_sold_year_pivot2)

SELECT Sold_year, "1" as 'Stock_Group_Name1',"2" as 'Stock_Group_Name2',"3" as 'Stock_Group_Name3',
"4" as 'Stock_Group_Name4',"5" as 'Stock_Group_Name5', "6" as 'Stock_Group_Name6', 
"7" as 'Stock_Group_Name7',"8" as 'Stock_Group_Name8',"9" as 'Stock_Group_Name9',
"10" as 'Stock_Group_Name10'
FROM Stock_pivot;
-- Display the View 
SELECT *
FROM Stock_year;

--20
DROP FUNCTION Total_price
CREATE FUNCTION Total_price(@id INT)
RETURNS INT
AS
BEGIN
	DECLARE @price int;
	SELECT @price = T_price
	FROM (SELECT o.OrderID, sum(ol.UnitPrice * ol.Quantity) AS T_price
	FROM Sales.Orders o JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
	WHERE o.OrderID = @id 
	GROUP BY o.OrderID) AS TP
	RETURN @price
END

SELECT *, ods.Total_price(OrderID) AS Totaol_order_price
FROM Sales.Invoices ;


--21
--Create store procedure and new table

DROP PROCEDURE Orders_info
CREATE PROCEDURE Orders_info
@date date
--@OrderID int output,
--@OrderDate date output,
--@OrderTotal int output 
--@CustomerID int output

AS	SET NOCOUNT ON;
	SELECT s.OrderID, s.CustomerID, s.OrderDate INTO ods.Orders --create a new table
	FROM Sales.Orders s
	WHERE s.OrderDate = @date;
GO

-- Run store producure and store data in new table
EXECUTE Orders_info '2013-01-02'

SELECT OrderID, CustomerID,OrderDate
FROM ods.Orders


--22

CREATE TABLE ods.StockItems(
	StockItemID INT PRIMARY KEY,
	StockItemName nvarchar(100) NOT NULL,
	SupplierID INT NOT NULL,
	ColorID INT NULL,
	UnitPackageID INT NOT NULL,
	OuterPackageID INT NOT NULL,
	Brand nvarchar(50) NULL,
	Size nvarchar(20) NULL,
	LeadTimeDays INT NOT NULL,
	QuantityPerOuter INT NOT NULL,
	IsChillerStock BIT NOT NULL,
	Barcode nvarchar(50) NULL,
	TaxRate DECIMAL(18, 3) NOT NULL,
	UnitPrice DECIMAL(18, 2) NOT NULL,
	RecommendedRetailPrice DECIMAL(18, 2) NULL,
	TypicalWeightPerUnit DECIMAL(18, 3) NOT NULL,
	MarketingComments nvarchar(MAX) NULL,
	InternalComments nvarchar(MAX) NULL,
	CountryOfManufacture nvarchar(20) NULL,
	[Range] nvarchar(20) NULL,
	Shelflife nvarchar(20) NULL
)

MERGE INTO ods.StockItems AS s1
USING Warehouse.StockItems AS s2
ON s1.StockItemID = s2.StockItemID
WHEN NOT MATCHED 
THEN INSERT VALUES (s2.StockItemID, 
                    s2.StockItemName, 
					s2.SupplierID, 
					s2.ColorID, 
		            s2.UnitPackageID, 
					s2.OuterPackageID, 
					s2.Brand, 
					s2.Size, 
					s2.LeadTimeDays, 
		            s2.QuantityPerOuter, 
					s2.IsChillerStock, 
					s2.Barcode, 
					s2.TaxRate, 
					s2.UnitPrice,
		            s2.RecommendedRetailPrice, 
					s2.TypicalWeightPerUnit, 
					s2.MarketingComments,
		            s2.InternalComments, 
					JSON_VALUE(s2.CustomFields, '$.CountryOfManufacture'),
		            JSON_VALUE(s2.CustomFields, '$.Range'), 
					JSON_VALUE(s2.CustomFields, '$.ShelfLife'));

--23
--If the procedure exist, drop it
DROP PROCEDURE Orders_day
-- Create procedure
CREATE PROCEDURE Orders_day
@date date
--@OrderID int output,
--@OrderDate date output,
--@CustomerID int output
AS  SET NOCOUNT ON;

	SELECT s.OrderID, s.CustomerID, s.OrderDate 
	FROM Sales.Orders s
	WHERE datediff(day,@date,s.OrderDate) < 8 AND datediff(day,@date,s.OrderDate) > 0
GO

-- Show the informtion of next 7 days of '2013-01-01'
EXECUTE Orders_day N'2013-01-01' 

--24
DECLARE @json NVARCHAR(MAX);
SET @json = N'[
  {"StockItemName":"Panzer Video Game", 
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[6,7],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"},
  {"StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"}
]';

SELECT * INTO Json_table
FROM OPENJSON(@json)
  WITH (
    StockItemName nvarchar(MAX),
	SupplierID int '$.Supplier',
	UnitPackageID int '$.UnitPackageId',
	OuterPackageID int '$.OuterPackageId',
	Brand nvarchar(50),
	LeadTimeDays int,
	QuantityPerOuter int,
	TaxRate decimal(18,3),
	UnitPrice decimal(18,2),
	RecommendedRetailPrice decimal(18,2),
	TypicalWeightPerUnit decimal(18,3),
	CustomFileds nvarchar(max) '$.CountryOfManufacture',
	Range nvarchar(100),
	OrderDate datetime,
	DeliveryMethod nvarchar(100),
	ExpectedDeliveryDate datetime,
	SupplierReference nvarchar(100)
  )

-- In this Json file, it not contain informations about primary key column in three
-- tables(Stock Item, Pruchase Order and Order Lines). Therefore, the data from Json
-- file can not insert in to these three tables. 
 
Insert into Sales.OrderLines(Sales.OrderLines.TaxRate)(select TaxRate From Json_table)

--25
SELECT *
FROM Stock_year
FOR JSON PATH 

--26
SELECT *
FROM Stock_year
FOR XML PATH

--27
--If the procedure exist, drop it
DROP PROCEDURE Invoices_info
-- Create procedure
CREATE PROCEDURE Invoices_info
@date date

AS  SET NOCOUNT ON;

	SELECT *
	FROM Sales.Invoices
	WHERE InvoiceDate = @date
GO

SELECT OrderID, CustomerID,OrderDate
FROM ods.Orders



