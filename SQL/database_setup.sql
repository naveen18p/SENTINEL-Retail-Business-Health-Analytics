CREATE DATABASE SentinelDB;
GO

USE SentinelDB;
GO
CREATE TABLE Stores
(
    StoreID INT IDENTITY(1,1) PRIMARY KEY,
    StoreName VARCHAR(100) NOT NULL,
    City VARCHAR(100),
    State VARCHAR(100),
    OpenDate DATE,
    StoreType VARCHAR(50),
    StoreStatus VARCHAR(20)
);
CREATE TABLE Customers
(
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName VARCHAR(100),
    SignupDate DATE,
    City VARCHAR(100),
    State VARCHAR(100)
);
CREATE TABLE Categories
(
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL
);
CREATE TABLE Products
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(150) NOT NULL,
    CategoryID INT,
    CostPrice DECIMAL(10,2),
    SellingPrice DECIMAL(10,2),
    ReorderLevel INT,
    IsActive BIT DEFAULT 1,

    FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID)
);
CREATE TABLE Promotions
(
    PromotionID INT IDENTITY(1,1) PRIMARY KEY,
    PromotionName VARCHAR(100),
    StartDate DATE,
    EndDate DATE,
    DiscountPercentage DECIMAL(5,2),
    CategoryID INT NULL,

    FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID)
);
CREATE TABLE Orders
(
    OrderID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATETIME2 NOT NULL,
    CustomerID INT NOT NULL,
    StoreID INT NOT NULL,
    PromotionID INT NULL,
    OrderStatus VARCHAR(30),

    FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID),

    FOREIGN KEY (StoreID)
        REFERENCES Stores(StoreID),

    FOREIGN KEY (PromotionID)
        REFERENCES Promotions(PromotionID)
);
CREATE TABLE OrderItems
(
    OrderItemID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderID BIGINT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    UnitCost DECIMAL(10,2) NOT NULL,
    DiscountPercentage DECIMAL(5,2) DEFAULT 0,

    FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID),

    FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID)
);
CREATE TABLE Returns
(
    ReturnID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderItemID BIGINT NOT NULL,
    ReturnDate DATE NOT NULL,
    ReturnQuantity INT NOT NULL,
    ReturnReason VARCHAR(150),

    FOREIGN KEY (OrderItemID)
        REFERENCES OrderItems(OrderItemID)
);
CREATE TABLE Inventory
(
    InventoryID BIGINT IDENTITY(1,1) PRIMARY KEY,
    SnapshotDate DATE NOT NULL,
    StoreID INT NOT NULL,
    ProductID INT NOT NULL,
    StockOnHand INT NOT NULL,
    ReorderPoint INT,

    FOREIGN KEY (StoreID)
        REFERENCES Stores(StoreID),

    FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID)
);
CREATE TABLE Reviews
(
    ReviewID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderID BIGINT NOT NULL,
    ReviewDate DATE,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    ReviewText VARCHAR(500),

    FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID)
);
CREATE TABLE Complaints
(
    ComplaintID BIGINT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    StoreID INT NOT NULL,
    OrderID BIGINT NULL,
    ComplaintDate DATE NOT NULL,
    ComplaintType VARCHAR(100),
    Severity VARCHAR(20),
    ComplaintStatus VARCHAR(30),
    ResolutionDays INT,

    FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID),

    FOREIGN KEY (StoreID)
        REFERENCES Stores(StoreID),

    FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID)
);