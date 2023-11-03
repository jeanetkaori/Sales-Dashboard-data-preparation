select * from [Raw Data Stock_APL];
select * from [Raw Data Stock_KFTD];

-- Pembersihan data distributor APL
ALTER TABLE [Raw Data Stock_APL]
DROP COLUMN PRINCIPAL, BUSINESS_DIVISION_1, BUSINESS_DIVISION_2, ZP_ITEM_CODE, BATCH, WAREHOUSE_CODE; /*Menghapus kolom yang tidak diperlukan*/

-- Memberikan primary key
ALTER TABLE [Raw Data Stock_APL]
ADD APL_number INT IDENTITY(1,1),  APL_ID AS 'APL_' + RIGHT('0000' + CAST(APL_number AS VARCHAR(4)), 4) PERSISTED not null; 

ALTER TABLE [Raw Data Stock_APL]
ADD CONSTRAINT PK_APL PRIMARY KEY (APL_ID);

-- Pembersihan data distributor KFTD --
ALTER TABLE [Raw Data Stock_KFTD]
DROP COLUMN Batch_SAP, Principle, Nama_Principle, Plant,Date_Manufacture, Storage_Location, Material_Number;

ALTER TABLE [Raw Data Stock_KFTD]
ADD Sub_Product NVARCHAR(50);

UPDATE [Raw Data_KFTD]
SET Sub_Product_KFTD = LEFT(Material_Description, LEN(Material_Description) - 7);


ALTER TABLE [Raw Data Stock_KFTD]
DROP COLUMN Material_Description

-- Memberikan primary key
ALTER TABLE [Raw Data Stock_KFTD]
ADD KFTD_number INT IDENTITY(1,1),  KFTD_ID AS 'KFTD_' + RIGHT('0000' + CAST(KFTD_number AS VARCHAR(4)), 4) PERSISTED not null; 

ALTER TABLE [Raw Data Stock_KFTD]
ADD CONSTRAINT PK_KFTD PRIMARY KEY (KFTD_ID);

-- Membuat table untuk power BI
CREAtE TABLE Stock_Etana (
ID_StockEtn AS 'StockEtn_' + RIGHT('00000' + CAST(StockEtn__number AS VARCHAR(5)), 5) PERSISTED not null primary key,
StockEtn__number INT IDENTITY(1,1) not null,
Product nvarchar (50),
Sub_Product nvarchar (50),
Branch nvarchar (50),
Distributor nvarchar (50),
--Sales_unit int,
--Sales_value_HNA int,
--Discount int,
--Net_Sales int,
Available_stock_qty int,
Available_stock_value int,
Exp_date DATE,
);

INSERT INTO Stock_Etana (Sub_Product, Branch, Available_stock_qty, Available_stock_value, Exp_date)
SELECT ITEM_NAME, BRANCH, AVAILABLE_QTY, AVAILABLE_VALUE, EXPDATE
FROM [Raw Data Stock_APL];

INSERT INTO Stock_Etana (Sub_Product, Branch, Available_stock_qty, Available_stock_value, Exp_date)
SELECT Sub_Product_KFTD, Cabang, Qty_Conv_Unrestricted, Total_Value_Stock_Unrestricted, SLED_BBD
FROM [Raw Data Stock_KFTD];

-- memasukkan nama distributor sesuai dengan nama cabangnya
UPDATE Stock_Etana
SET Distributor = d.Distributor
FROM Stock_Etana P
JOIN Distributor d ON P.Branch LIKE CONCAT('%', d.Distributor, '%');

-- memasukkan nama product berdasarkan nama sub product nya
UPDATE Stock_Etana
SET Stock_Etana.Product = Sub_Product.Product
FROM Stock_Etana se
JOIN Sub_Product ON se.Sub_Product = Sub_Product.Sub_Product;

SELECT Distributor, sum(Available_stock_qty) as Total_Available_stock_qty 
FROM Stock_Etana
GROUP BY Distributor;

select * from Sub_Product; 
select * from Stock_Etana;
select * from cabang_etana;

