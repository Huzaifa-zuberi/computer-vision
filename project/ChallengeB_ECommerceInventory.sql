-- ============================================================
-- Challenge B: Multi-Vendor E-Commerce Inventory Ledger
-- Author: Huzaif Zuberi & Sheikh Uzair Ali
-- Description: 3NF normalized schema, cascading constraints,
--              audit timestamps with DEFAULT / GETDATE()
-- ============================================================

-- ---------------------- DDL (3NF) --------------------------

CREATE TABLE Vendors (
    VendorID        INT             NOT NULL IDENTITY(1,1),
    VendorName      VARCHAR(100)    NOT NULL,
    ContactEmail    VARCHAR(150)    NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Vendors PRIMARY KEY (VendorID)
);

CREATE TABLE Categories (
    CategoryID      INT             NOT NULL IDENTITY(1,1),
    CategoryName    VARCHAR(100)    NOT NULL,
    ParentCategoryID INT            NULL,
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryID),
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentCategoryID)
        REFERENCES Categories(CategoryID)
);

CREATE TABLE Products (
    ProductID       INT             NOT NULL IDENTITY(1,1),
    ProductName     VARCHAR(150)    NOT NULL,
    SKU             VARCHAR(50)     NOT NULL,
    VendorID        INT             NULL,
    CategoryID      INT             NULL,
    UnitPrice       DECIMAL(10,2)   NOT NULL,
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Products PRIMARY KEY (ProductID),
    CONSTRAINT UQ_Products_SKU UNIQUE (SKU),
    CONSTRAINT FK_Products_Vendor FOREIGN KEY (VendorID)
        REFERENCES Vendors(VendorID)
        ON DELETE SET NULL,
    CONSTRAINT FK_Products_Category FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID)
        ON DELETE SET NULL
);

CREATE TABLE Warehouses (
    WarehouseID     INT             NOT NULL IDENTITY(1,1),
    WarehouseName   VARCHAR(100)    NOT NULL,
    Location        VARCHAR(200)    NOT NULL,
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Warehouses PRIMARY KEY (WarehouseID)
);

CREATE TABLE InventoryLedger (
    AdjustmentID    INT             NOT NULL IDENTITY(1,1),
    ProductID       INT             NOT NULL,
    WarehouseID     INT             NOT NULL,
    QuantityChange  INT             NOT NULL,
    RunningTotal    INT             NOT NULL,
    ReasonCode      VARCHAR(50)     NULL,
    AdjustedBy      VARCHAR(100)    NOT NULL,
    AdjustedAt      DATETIME2       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_InventoryLedger PRIMARY KEY (AdjustmentID),
    CONSTRAINT FK_IL_Product FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID)
        ON DELETE CASCADE,
    CONSTRAINT FK_IL_Warehouse FOREIGN KEY (WarehouseID)
        REFERENCES Warehouses(WarehouseID)
);

-- ---------------------- DATA SEED --------------------------

BEGIN TRANSACTION;

INSERT INTO Vendors (VendorName, ContactEmail, IsActive)
VALUES
    ('TechGear Supplies',   'tech@example.com',    1),
    ('HomeComfort Co.',     'home@example.com',    1),
    ('Huzaif Zuberi Traders','huzaif@example.com', 1);

INSERT INTO Categories (CategoryName, ParentCategoryID)
VALUES
    ('Electronics', NULL),
    ('Home & Kitchen', NULL),
    ('Mobile Phones', 1),
    ('Laptops', 1);

INSERT INTO Products (ProductName, SKU, VendorID, CategoryID, UnitPrice)
VALUES
    ('Wireless Mouse',      'WM-001',   1, 4, 29.99),
    ('Bluetooth Speaker',   'BS-002',   1, 3, 49.99),
    ('LED Desk Lamp',       'LD-003',   2, 2, 39.99),
    ('USB-C Hub',           'UC-004',   3, 4, 34.99);

INSERT INTO Warehouses (WarehouseName, Location)
VALUES
    ('Main Distribution Center', '123 Industrial Blvd, City A'),
    ('East Side Depot',          '456 Commerce Dr, City B');

INSERT INTO InventoryLedger (ProductID, WarehouseID, QuantityChange, RunningTotal, ReasonCode, AdjustedBy)
VALUES
    (1, 1,  100, 100, 'Initial Stock', 'Sheikh Uzair Ali'),
    (2, 1,   50,  50, 'Initial Stock', 'Sheikh Uzair Ali'),
    (1, 1,  -5,   95, 'Order Fulfillment', 'System'),
    (3, 2,  200, 200, 'Initial Stock', 'Huzaif Zuberi');

COMMIT TRANSACTION;

PRINT 'Challenge B - E-Commerce Inventory schema and seed data loaded successfully.';
GO
