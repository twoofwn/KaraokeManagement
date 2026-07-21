USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'KaraokeManagementDB')
BEGIN
    ALTER DATABASE KaraokeManagementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE KaraokeManagementDB;
END
GO

CREATE DATABASE KaraokeManagementDB;
GO
USE KaraokeManagementDB;
GO

-- ==========================================
-- 1. TẠO BẢNG HỆ THỐNG & NGƯỜI DÙNG
-- ==========================================

CREATE TABLE [Role] (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL
);

CREATE TABLE [Account] (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    RoleID INT NOT NULL,
    Username VARCHAR(50) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Phone VARCHAR(15),
    Email VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    ResetPasswordToken VARCHAR(256) NULL,
    ResetPasswordTokenExpiry DATETIME NULL,
    FOREIGN KEY (RoleID) REFERENCES [Role](RoleID)
);

CREATE TABLE [MembershipTier] (
    TierID INT IDENTITY(1,1) PRIMARY KEY,
    TierName NVARCHAR(50) NOT NULL,
    DiscountPercent DECIMAL(5,2) DEFAULT 0,
    MinPoints INT DEFAULT 0
);

CREATE TABLE [Customer] (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    TierID INT NULL, 
    FullName NVARCHAR(100) NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    Email VARCHAR(100),
    LoyaltyPoints INT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (TierID) REFERENCES [MembershipTier](TierID)
);

-- ==========================================
-- 2. TẠO BẢNG PHÒNG HÁT & THIẾT BỊ
-- ==========================================

CREATE TABLE [RoomType] (
    RoomTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeName NVARCHAR(50) NOT NULL,
    PricePerHour DECIMAL(18,2) NOT NULL,
    Description NVARCHAR(255)
);

CREATE TABLE [Room] (
    RoomID INT IDENTITY(1,1) PRIMARY KEY,
    RoomTypeID INT NOT NULL,
    RoomName NVARCHAR(50) NOT NULL,
    Status NVARCHAR(50) DEFAULT 'Available',
    FOREIGN KEY (RoomTypeID) REFERENCES [RoomType](RoomTypeID)
);

CREATE TABLE [Equipment] (
    EquipmentID INT IDENTITY(1,1) PRIMARY KEY,
    RoomID INT NOT NULL,
    EquipmentName NVARCHAR(100) NOT NULL,
    SerialNumber VARCHAR(50),
    PurchaseDate DATE,
    Status NVARCHAR(50) DEFAULT 'Good',
    FOREIGN KEY (RoomID) REFERENCES [Room](RoomID)
);

CREATE TABLE [MaintenanceLog] (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EquipmentID INT NOT NULL,
    ReportedByID INT NOT NULL,
    IssueDescription NVARCHAR(255),
    RepairCost DECIMAL(18,2) DEFAULT 0,
    LogDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (EquipmentID) REFERENCES [Equipment](EquipmentID),
    FOREIGN KEY (ReportedByID) REFERENCES [Account](AccountID)
);

-- ==========================================
-- 3. TẠO BẢNG KHO & DỊCH VỤ
-- ==========================================

CREATE TABLE [Category] (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL
);

CREATE TABLE [ServiceItem] (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT NOT NULL,
    ServiceName NVARCHAR(100) NOT NULL,
    SellingPrice DECIMAL(18,2) NOT NULL,
    Unit NVARCHAR(20),
    StockQuantity INT DEFAULT 0,
    FOREIGN KEY (CategoryID) REFERENCES [Category](CategoryID)
);

CREATE TABLE [Supplier] (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    ContactName NVARCHAR(100),
    Phone VARCHAR(15),
    Address NVARCHAR(255)
);

CREATE TABLE [PurchaseOrder] (
    PO_ID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID INT NOT NULL,
    CreatedByID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(18,2) DEFAULT 0,
    FOREIGN KEY (SupplierID) REFERENCES [Supplier](SupplierID),
    FOREIGN KEY (CreatedByID) REFERENCES [Account](AccountID)
);

CREATE TABLE [PurchaseOrderDetail] (
    PODetailID INT IDENTITY(1,1) PRIMARY KEY,
    PO_ID INT NOT NULL,
    ServiceID INT NOT NULL,
    ImportPrice DECIMAL(18,2) NOT NULL,
    Quantity INT NOT NULL,
    FOREIGN KEY (PO_ID) REFERENCES [PurchaseOrder](PO_ID),
    FOREIGN KEY (ServiceID) REFERENCES [ServiceItem](ServiceID)
);

-- ==========================================
-- 4. TẠO BẢNG NGHIỆP VỤ (KARAOKE)
-- ==========================================

CREATE TABLE [Promotion] (
    PromotionID INT IDENTITY(1,1) PRIMARY KEY,
    PromoCode VARCHAR(20) UNIQUE NOT NULL,
    PromoName NVARCHAR(100) NOT NULL,
    DiscountPercent DECIMAL(5,2) DEFAULT 0,
    MaxDiscountAmount DECIMAL(18,2),
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL
);

CREATE TABLE [Booking] (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL, 
    CreatedByID INT NOT NULL, -- KHÓA NGOẠI MỚI: Ghi nhận nhân viên tạo lệnh book
    RoomID INT NOT NULL,
    BookingTime DATETIME DEFAULT GETDATE(),
    StartTime DATETIME NOT NULL,
    EndTime DATETIME,
    Status NVARCHAR(50) DEFAULT 'Pending',
    FOREIGN KEY (CustomerID) REFERENCES [Customer](CustomerID),
    FOREIGN KEY (CreatedByID) REFERENCES [Account](AccountID),
    FOREIGN KEY (RoomID) REFERENCES [Room](RoomID)
);

CREATE TABLE [Invoice] (
    InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
    BookingID INT NULL, 
    RoomID INT NOT NULL,
    ReceptionistID INT NOT NULL,
    PromotionID INT NULL,
    CheckInTime DATETIME NOT NULL,
    CheckOutTime DATETIME,
    RoomTotal DECIMAL(18,2) DEFAULT 0,
    ServiceTotal DECIMAL(18,2) DEFAULT 0,
    DiscountAmount DECIMAL(18,2) DEFAULT 0,
    GrandTotal DECIMAL(18,2) DEFAULT 0,
    Status NVARCHAR(50) DEFAULT 'Unpaid',
    FOREIGN KEY (BookingID) REFERENCES [Booking](BookingID),
    FOREIGN KEY (RoomID) REFERENCES [Room](RoomID),
    FOREIGN KEY (ReceptionistID) REFERENCES [Account](AccountID),
    FOREIGN KEY (PromotionID) REFERENCES [Promotion](PromotionID)
);

CREATE TABLE [InvoiceDetail] (
    InvoiceDetailID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceID INT NOT NULL,
    ServiceID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (InvoiceID) REFERENCES [Invoice](InvoiceID),
    FOREIGN KEY (ServiceID) REFERENCES [ServiceItem](ServiceID)
);

-- ==========================================
-- 5. TẠO BẢNG THANH TOÁN
-- ==========================================

CREATE TABLE [PaymentMethod] (
    MethodID INT IDENTITY(1,1) PRIMARY KEY,
    MethodName NVARCHAR(50) NOT NULL
);

CREATE TABLE [PaymentTransaction] (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceID INT NOT NULL,
    MethodID INT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    TransactionDate DATETIME DEFAULT GETDATE(),
    ReferenceCode VARCHAR(100),
    FOREIGN KEY (InvoiceID) REFERENCES [Invoice](InvoiceID),
    FOREIGN KEY (MethodID) REFERENCES [PaymentMethod](MethodID)
);

CREATE TABLE [Expense] (
    ExpenseID INT IDENTITY(1,1) PRIMARY KEY,
    Category NVARCHAR(50) NOT NULL,
    ExpenseDate DATE NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Note NVARCHAR(255) NULL,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO


-- ==========================================
-- CHÈN DỮ LIỆU MẪU
-- ==========================================

INSERT INTO [Role] (RoleName) VALUES ('Admin'), ('Manager'), ('Receptionist');

INSERT INTO [MembershipTier] (TierName, DiscountPercent, MinPoints) VALUES 
(N'Khách Mới', 0.00, 0), (N'Đồng', 5.00, 1000), (N'Bạc', 10.00, 3000), (N'Vàng', 15.00, 7000), (N'Kim Cương', 20.00, 15000);

-- Tài khoản nhân viên (ID từ 1 -> 4)
INSERT INTO [Account] (RoleID, Username, PasswordHash, FullName, Phone, Email) VALUES 
(1, 'admin_tong', 'hash1', N'Nguyễn Quản Trị', '0900000001', 'admin@karaoke.com'),
(2, 'quanly_hung', 'hash2', N'Trần Hùng (Quản Lý)', '0900000002', 'hung@karaoke.com'),
(3, 'letan_lan', 'hash3', N'Lê Thị Lan (Lễ Tân ca 1)', '0900000003', 'lan@karaoke.com'),
(3, 'letan_mai', 'hash4', N'Phạm Mai (Lễ Tân ca 2)', '0900000004', 'mai@karaoke.com');

-- Khách hàng (ID từ 1 -> 6)
INSERT INTO [Customer] (TierID, FullName, Phone, Email, LoyaltyPoints) VALUES 
(5, N'Lê Minh Tuấn (VIP)', '0911111111', 'tuanvip@gmail.com', 16500),
(4, N'Nguyễn Việt Hoàng', '0922222222', 'hoangnv@gmail.com', 8200),
(3, N'Trần Tiến Dũng', '0933333333', 'dungtt@gmail.com', 3500),
(2, N'Phạm Thu Thủy', '0944444444', 'thuypham@gmail.com', 1200),
(1, N'Đinh Thanh Hà', '0955555555', 'hadinh@gmail.com', 150),
(1, N'Khách Vãng Lai', '0000000000', '', 0);

INSERT INTO [RoomType] (TypeName, PricePerHour, Description) VALUES 
(N'Phòng Thường', 150000, N'Sức chứa 5-8 người'), (N'Phòng VIP', 300000, N'Sức chứa 10-15 người'),
(N'Phòng Super VIP (Party)', 600000, N'Sức chứa 30 người'), (N'Phòng Couple', 120000, N'Sức chứa 2-4 người');

INSERT INTO [Room] (RoomTypeID, RoomName, Status) VALUES 
(1, N'Tầng 1 - 101', 'Available'), (1, N'Tầng 1 - 102', 'Available'), (1, N'Tầng 1 - 103', 'Maintenance'), 
(4, N'Tầng 1 - 104 (Couple)', 'InUse'), (2, N'Tầng 2 - 201 (VIP)', 'Available'), (2, N'Tầng 2 - 202 (VIP)', 'InUse'), 
(2, N'Tầng 2 - 203 (VIP)', 'Available'), (3, N'Tầng 3 - 301 (Party)', 'Available'), (3, N'Tầng 3 - 302 (Party)', 'InUse'), (1, N'Tầng 4 - 401', 'Available');

INSERT INTO [Equipment] (RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES 
(5, N'Tivi Samsung 65 Inch', 'SS-65-001', '2023-01-15', 'Good'), (5, N'Micro Shure', 'SH-001', '2023-01-15', 'Good'),
(6, N'Micro Shure', 'SH-003', '2023-01-15', 'Broken'), (8, N'Loa JBL', 'JBL-001', '2023-05-20', 'Good'), (3, N'Điều hòa Panasonic', 'PN-AC-001', '2022-10-10', 'Repairing');

INSERT INTO [MaintenanceLog] (EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES 
(3, 3, N'Rớt móp đầu mic', 150000, GETDATE()-5), (5, 2, N'Máy kêu to', 500000, GETDATE()-1);

INSERT INTO [Category] (CategoryName) VALUES (N'Bia'), (N'Rượu'), (N'Nước Khát'), (N'Đồ Ăn'), (N'Trái Cây'), (N'Combo');

INSERT INTO [ServiceItem] (CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES 
(1, N'Heineken', 40000, N'Lon', 500), (1, N'Tiger', 30000, N'Lon', 800), (2, N'Chivas 12', 1500000, N'Chai', 20), 
(3, N'Aquafina', 20000, N'Chai', 400), (4, N'Khô Bò', 150000, N'Đĩa', 50), (5, N'Trái Cây VIP', 350000, N'Đĩa', 20), (6, N'Combo Sinh Nhật', 1500000, N'Combo', 5);

INSERT INTO [Supplier] (SupplierName, ContactName, Phone, Address) VALUES (N'Bia Nước Ngọt Thành Phát', N'Anh Thành', '0901111222', N'Q10'), (N'Rượu Ngoại Sài Gòn', N'Chị Hương', '0903333444', N'Q1');

INSERT INTO [PurchaseOrder] (SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (1, 2, '2023-10-01', 25000000), (2, 2, '2023-10-05', 45000000);

INSERT INTO [PurchaseOrderDetail] (PO_ID, ServiceID, ImportPrice, Quantity) VALUES (1, 1, 25000, 300), (1, 2, 18000, 500), (2, 3, 1000000, 10);

INSERT INTO [Promotion] (PromoCode, PromoName, DiscountPercent, MaxDiscountAmount, StartDate, EndDate) VALUES 
('NEWYEAR', N'Giảm 20%', 20.00, 500000, '2024-01-01', '2024-01-31'), ('NOPROMO', N'Không KM', 0.00, 0, '2000-01-01', '2099-12-31');

-- CẬP NHẬT DỮ LIỆU MẪU BẢNG BOOKING:
-- Thêm cột CreatedByID (ID Nhân viên tạo lệnh book: 3 = lễ tân Lan, 4 = lễ tân Mai)
INSERT INTO [Booking] (CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status) VALUES 
(1, 3, 5, GETDATE()-3, GETDATE()-2, DATEADD(hour, 4, GETDATE()-2), 'Completed'), -- Lan book cho Tuấn
(2, 4, 8, GETDATE()-1, GETDATE()-1, DATEADD(hour, 3, GETDATE()-1), 'Completed'), -- Mai book cho Hoàng
(3, 3, 4, GETDATE(), GETDATE(), DATEADD(hour, 2, GETDATE()), 'CheckedIn');         -- Lan book cho Dũng

INSERT INTO [Invoice] (BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES 
(1, 5, 3, 2, GETDATE()-2, DATEADD(hour, 4, GETDATE()-2), 1200000, 2750000, 790000, 3160000, 'Paid'),
(2, 8, 3, 1, GETDATE()-1, DATEADD(hour, 3, GETDATE()-1), 1800000, 1500000, 500000, 2800000, 'Paid'),
(3, 4, 4, 2, GETDATE(), NULL, 0, 0, 0, 0, 'Unpaid');

INSERT INTO [InvoiceDetail] (InvoiceID, ServiceID, Quantity, UnitPrice) VALUES 
(1, 3, 1, 1500000), (1, 6, 2, 350000), (1, 5, 2, 150000), (2, 7, 1, 1500000), (2, 2, 24, 30000);

INSERT INTO [PaymentMethod] (MethodName) VALUES (N'Tiền mặt'), (N'VNPay'), (N'Visa'), (N'Momo');

INSERT INTO [PaymentTransaction] (InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES 
(1, 3, 3160000, DATEADD(hour, 4, GETDATE()-2), 'VISA-123'), (2, 1, 1000000, DATEADD(hour, 3, GETDATE()-1), NULL), (2, 4, 1800000, DATEADD(hour, 3, GETDATE()-1), 'MOMO-987');

INSERT INTO [Expense] (Category, ExpenseDate, Amount, Note) VALUES 
('dien', '2023-10-15', 5400000, N'Tiền điện tháng 9/2023'),
('baotri', '2023-10-14', 2100000, N'Sửa mic phòng VIP 1 & 2'),
('matbang', '2023-10-01', 25000000, N'Thuê mặt bằng tháng 10'),
('nuoc', '2023-09-28', 850000, N'Tiền nước T9');

-- Bổ sung dữ liệu kiểm thử cho hóa đơn (để test phân trang & bộ lọc)
INSERT INTO [Booking] (CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status) VALUES 
(1, 3, 1, GETDATE()-15, GETDATE()-14, DATEADD(hour, 2, GETDATE()-14), 'Completed'),
(2, 3, 2, GETDATE()-14, GETDATE()-13, DATEADD(hour, 3, GETDATE()-13), 'Completed'),
(3, 4, 4, GETDATE()-13, GETDATE()-12, DATEADD(hour, 2, GETDATE()-12), 'Completed'),
(4, 4, 5, GETDATE()-12, GETDATE()-11, DATEADD(hour, 4, GETDATE()-11), 'Completed'),
(5, 3, 6, GETDATE()-11, GETDATE()-10, DATEADD(hour, 5, GETDATE()-10), 'Completed'),
(1, 3, 7, GETDATE()-10, GETDATE()-9, DATEADD(hour, 2, GETDATE()-9), 'Completed'),
(2, 4, 8, GETDATE()-9, GETDATE()-8, DATEADD(hour, 3, GETDATE()-8), 'Completed'),
(3, 4, 9, GETDATE()-8, GETDATE()-7, DATEADD(hour, 4, GETDATE()-7), 'Completed'),
(4, 3, 10, GETDATE()-7, GETDATE()-6, DATEADD(hour, 2, GETDATE()-6), 'Completed'),
(5, 3, 1, GETDATE()-6, GETDATE()-5, DATEADD(hour, 3, GETDATE()-5), 'Completed'),
(1, 4, 2, GETDATE()-5, GETDATE()-4, DATEADD(hour, 2, GETDATE()-4), 'Completed'),
(2, 4, 5, GETDATE()-4, GETDATE()-3, DATEADD(hour, 4, GETDATE()-3), 'Completed');

INSERT INTO [Invoice] (BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES 
(4, 1, 3, 2, GETDATE()-14, DATEADD(hour, 2, GETDATE()-14), 300000, 140000, 0, 440000, 'Paid'),
(5, 2, 3, 2, GETDATE()-13, DATEADD(hour, 3, GETDATE()-13), 450000, 80000, 0, 530000, 'Paid'),
(6, 4, 4, 2, GETDATE()-12, DATEADD(hour, 2, GETDATE()-12), 240000, 190000, 0, 430000, 'Paid'),
(7, 5, 4, 2, GETDATE()-11, DATEADD(hour, 4, GETDATE()-11), 1200000, 490000, 0, 1690000, 'Paid'),
(8, 6, 3, 2, GETDATE()-10, DATEADD(hour, 5, GETDATE()-10), 1500000, 700000, 150000, 2050000, 'Paid'),
(9, 7, 3, 2, GETDATE()-9, DATEADD(hour, 2, GETDATE()-9), 600000, 300000, 90000, 810000, 'Paid'),
(10, 8, 4, 2, GETDATE()-8, DATEADD(hour, 3, GETDATE()-8), 1800000, 1500000, 330000, 2970000, 'Paid'),
(11, 9, 4, 2, GETDATE()-7, DATEADD(hour, 4, GETDATE()-7), 2400000, 1500000, 390000, 3510000, 'Paid'),
(12, 10, 3, 2, GETDATE()-6, DATEADD(hour, 2, GETDATE()-6), 300000, 100000, 0, 400000, 'Paid'),
(13, 1, 3, 2, GETDATE()-5, DATEADD(hour, 3, GETDATE()-5), 450000, 260000, 0, 710000, 'Paid'),
(14, 2, 4, 2, GETDATE()-4, DATEADD(hour, 2, GETDATE()-4), 300000, 140000, 0, 440000, 'Paid'),
(15, 5, 4, 2, GETDATE()-3, DATEADD(hour, 4, GETDATE()-3), 1200000, 600000, 180000, 1620000, 'Paid');

INSERT INTO [InvoiceDetail] (InvoiceID, ServiceID, Quantity, UnitPrice) VALUES 
(4, 1, 3, 40000), (4, 4, 1, 20000),
(5, 2, 2, 30000), (5, 4, 1, 20000),
(6, 5, 1, 150000), (6, 1, 1, 40000),
(7, 6, 1, 350000), (7, 1, 3, 40000), (7, 4, 1, 20000),
(8, 6, 2, 350000),
(9, 5, 2, 150000),
(10, 7, 1, 1500000),
(11, 3, 1, 1500000),
(12, 1, 2, 40000), (12, 4, 1, 20000),
(13, 5, 1, 150000), (13, 2, 3, 30000), (13, 4, 1, 20000),
(14, 1, 3, 40000), (14, 4, 1, 20000),
(15, 6, 1, 350000), (15, 5, 1, 150000), (15, 1, 2, 40000), (15, 4, 1, 20000);

INSERT INTO [PaymentTransaction] (InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES 
(4, 1, 440000, DATEADD(hour, 2, GETDATE()-14), NULL),
(5, 2, 530000, DATEADD(hour, 3, GETDATE()-13), 'VNPAY-456'),
(6, 4, 430000, DATEADD(hour, 2, GETDATE()-12), 'MOMO-111'),
(7, 3, 1690000, DATEADD(hour, 4, GETDATE()-11), 'VISA-444'),
(8, 1, 2050000, DATEADD(hour, 5, GETDATE()-10), NULL),
(9, 2, 810000, DATEADD(hour, 2, GETDATE()-9), 'VNPAY-777'),
(10, 4, 2970000, DATEADD(hour, 3, GETDATE()-8), 'MOMO-222'),
(11, 3, 3510000, DATEADD(hour, 4, GETDATE()-7), 'VISA-555'),
(12, 1, 400000, DATEADD(hour, 2, GETDATE()-6), NULL),
(13, 2, 710000, DATEADD(hour, 3, GETDATE()-5), 'VNPAY-888'),
(14, 4, 440000, DATEADD(hour, 2, GETDATE()-4), 'MOMO-333'),
(15, 3, 1620000, DATEADD(hour, 4, GETDATE()-3), 'VISA-666');
GO