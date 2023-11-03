select * from [Raw Data Sales_APL];
select * from [Raw Data Sales_KFTD];
select * from [Stock_Etana];
drop table Repeat_Customer;

-- Merge date and time column
ALTER TABLE [Raw Data Sales_APL]
ADD transaction_datetime DATETIME, manuf_datetime DATETIME;
UPDATE [Raw Data Sales_APL]
SET transaction_datetime = CAST(TRANSACTION_DATE AS DATETIME) + CAST(TRANSACTION_TIME AS DATETIME);

UPDATE [Raw Data Sales_APL]
SET manuf_datetime = CAST(MANUF_DATE AS DATETIME) + CAST(MANUF_TIME AS DATETIME);

ALTER TABLE [Raw Data Sales_KFTD]
ADD transaction_datetime DATETIME, manuf_datetime DATETIME;
UPDATE [Raw Data Sales_KFTD]
SET transaction_datetime = CAST(POSTING_DATE AS DATETIME) + CAST(POSTING_TIME AS DATETIME);

UPDATE [Raw Data Sales_KFTD]
SET manuf_datetime = CAST(MANUFACTURING_DATE AS DATETIME) + CAST(MANUFACTURING_TIME AS DATETIME);

-- untuk ngecek
SELECT
    POSTING_DATE,
    POSTING_TIME,
    CAST(POSTING_DATE AS DATETIME) + CAST(POSTING_TIME AS DATETIME) AS transaction_datetime
FROM
    [Raw Data Sales_KFTD];

SELECT
    MANUFACTURING_DATE,
    MANUFACTURING_TIME,
    CAST(MANUFACTURING_DATE AS DATETIME) + CAST(MANUFACTURING_TIME AS DATETIME) AS manuf_datetime
FROM
    [Raw Data Sales_KFTD];

-- Menghitung lead time
ALTER TABLE [Raw Data Sales_APL]
ADD lead_time_update FLOAT;
UPDATE [Raw Data Sales_APL]
SET lead_time_update = ROUND(DATEDIFF(SECOND, transaction_datetime, manuf_datetime) / 3600.0,2);

SELECT
    transaction_datetime,
    manuf_datetime,
    ROUND(DATEDIFF(SECOND, transaction_datetime, manuf_datetime) / 3600.0,2) AS lead_time
FROM
    [Raw Data Sales_APL];

ALTER TABLE [Raw Data Sales_KFTD]
ADD lead_time_update FLOAT;
UPDATE [Raw Data Sales_KFTD]
SET lead_time_update = ROUND(DATEDIFF(SECOND, transaction_datetime, manuf_datetime) / 3600.0,2);

UPDATE [Raw Data Sales_KFTD]
SET ITEM_NAME = LEFT(ITEM_NAME, LEN(ITEM_NAME) - 7);

SELECT
    transaction_datetime,
    manuf_datetime,
    ROUND(DATEDIFF(SECOND, transaction_datetime, manuf_datetime) / 3600.0, 2) AS lead_time
FROM
    [Raw Data Sales_KFTD];

select * from [Raw Data Pekerja];


-- Membuat table untuk sales
CREATE TABLE Sales_ETANA (
ID_SalesETANA AS 'SalesEtn_' + RIGHT('00000' + CAST(SalesETANA_number AS VARCHAR(5)), 5) PERSISTED not null primary key,
SalesETANA_number INT IDENTITY(1,1) not null,
Transaction_date DATE,
Manuf_date DATE,
Transaction_datetime DATETIME, 
Manuf_datetime DATETIME,
Lead_time float (50),
Sales_person nvarchar (50),-- foreign key references [Raw Data Pekerja](EMPLOYEE_CODE),
Product nvarchar (50),
Sub_Product nvarchar (50),
Branch nvarchar (50),
Customer_Name nvarchar (100),
Distributor nvarchar (50),
Forecasted_Sales_unit int,
Sales_unit int,
Sales_value int,
Discount int,
Net_Sales int,
Net_Profit int,
Gross_Profit int,
);

INSERT INTO Sales_ETANA (Transaction_date, Manuf_date, Transaction_datetime, Manuf_datetime, Sales_person, Sub_Product, Customer_Name, Branch, Forecasted_Sales_unit, Sales_unit, Sales_value, Net_Sales, Net_Profit, Gross_Profit, Distributor)
SELECT TRANSACTION_DATE, MANUF_DATE, transaction_datetime, manuf_datetime, SALES_PERSON, ITEM_NAME,CUSTOMER_NAME, BRANCH, SALES_FORECAST, SALES_UNIT, SALES_VALUE, NET_SALES, NET_PROFIT, GROSS_PROFIT, 'APL' AS Distributor
FROM [Raw Data Sales_APL];

INSERT INTO Sales_ETANA (Transaction_date, Manuf_date, Transaction_datetime, Manuf_datetime, Sales_person, Sub_Product, Customer_Name, Branch, Forecasted_Sales_unit, Sales_unit, Net_Sales, Net_Profit, Gross_Profit, Distributor)
SELECT POSTING_DATE, MANUFACTURING_DATE, transaction_datetime, manuf_datetime, SALES_PERSON, ITEM_NAME, CUSTOMER_NAME, BRANCH, FORECAST_SALES_UNIT, SALES_UNITS, SALES_VALUE, NET_PROFIT, GROSS_PROFIT,'KFTD' AS Distributor
FROM [Raw Data Sales_KFTD];

-- memasukkan nama product berdasarkan nama sub product nya
UPDATE Sales_ETANA
SET Product = SUBSTRING(Sub_Product, 1, CHARINDEX(' ', Sub_Product) - 1)
WHERE (NOT Sub_Product = 'MICACURA') AND (NOT Sub_Product = 'HEALIVE');

UPDATE Sales_ETANA
SET Product = 'MICACURA'
WHERE Sub_Product = 'MICACURA';

UPDATE Sales_ETANA
SET Product = 'HEALIVE'
WHERE Sub_Product = 'HEALIVE';

-- menghitung lead time
UPDATE Sales_ETANA
SET Lead_time = ROUND(DATEDIFF(SECOND, Transaction_datetime, Manuf_datetime) / 3600.0,2);

select * from Sales_ETANA;


