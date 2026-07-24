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
-- 1. TẠO BẢNG HỆ THỐNG, QUYỀN & CA LÀM VIỆC
-- ==========================================

CREATE TABLE [Role] (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL
);

CREATE TABLE [WorkShift] (
    ShiftID INT IDENTITY(1,1) PRIMARY KEY,
    ShiftName NVARCHAR(50) NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL
);

CREATE TABLE [Account] (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    RoleID INT NOT NULL,
    Username VARCHAR(50) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Phone VARCHAR(15) NULL,
    Email VARCHAR(100) NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    DefaultShiftID INT NULL,
    OtpCode VARCHAR(10) NULL,
    OtpExpiry DATETIME NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (RoleID) REFERENCES [Role](RoleID),
    FOREIGN KEY (DefaultShiftID) REFERENCES [WorkShift](ShiftID)
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
    Email VARCHAR(100) NULL,
    PasswordHash VARCHAR(255) NOT NULL, 
    LoyaltyPoints INT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),
    OtpCode VARCHAR(10) NULL,
    OtpExpiry DATETIME NULL,
    IsEmailVerified BIT NOT NULL DEFAULT 0, 
    FOREIGN KEY (TierID) REFERENCES [MembershipTier](TierID)
);

-- ==========================================
-- 2. TẠO BẢNG PHÒNG HÁT & THIẾT BỊ
-- ==========================================

CREATE TABLE [RoomType] (
    RoomTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeName NVARCHAR(50) NOT NULL,
    PricePerHour DECIMAL(18,2) NOT NULL,
    Description NVARCHAR(255) NULL,
    ImageURL NVARCHAR(500) NULL,
    Capacity INT NOT NULL DEFAULT 10
);

CREATE TABLE [Room] (
    RoomID INT IDENTITY(1,1) PRIMARY KEY,
    RoomTypeID INT NOT NULL,
    RoomName NVARCHAR(50) NOT NULL,
    Status NVARCHAR(50) DEFAULT 'Available',
    FOREIGN KEY (RoomTypeID) REFERENCES [RoomType](RoomTypeID)
);

CREATE TABLE [RoomImage] (
        [RoomImageId] INT IDENTITY(1,1) NOT NULL,
        [RoomTypeId] INT NOT NULL,
        [ImageUrl] NVARCHAR(500) NOT NULL,
        FOREIGN KEY (RoomTypeID) REFERENCES [RoomType](RoomTypeID)
);

CREATE TABLE [Equipment] (
    EquipmentID INT IDENTITY(1,1) PRIMARY KEY,
    RoomID INT NOT NULL,
    EquipmentName NVARCHAR(100) NOT NULL,
    SerialNumber VARCHAR(50) NULL,
    PurchaseDate DATE NULL,
    Status NVARCHAR(50) DEFAULT 'Good',
    FOREIGN KEY (RoomID) REFERENCES [Room](RoomID)
);

CREATE TABLE [MaintenanceLog] (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EquipmentID INT NOT NULL,
    ReportedByID INT NOT NULL,
    IssueDescription NVARCHAR(255) NULL,
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
    ImageUrl VARCHAR(255) NULL,
    ServiceName NVARCHAR(100) NOT NULL,
    SellingPrice DECIMAL(18,2) NOT NULL,
    Unit NVARCHAR(20) NULL,
    StockQuantity INT DEFAULT 0,
    FOREIGN KEY (CategoryID) REFERENCES [Category](CategoryID)
);

CREATE TABLE [Supplier] (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    ContactName NVARCHAR(100) NULL,
    Phone VARCHAR(15) NULL,
    Address NVARCHAR(255) NULL
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
-- 4. TẠO BẢNG NGHIỆP VỤ (KARAOKE) & ĐẶT PHÒNG
-- ==========================================

CREATE TABLE [Promotion] (
    PromotionID INT IDENTITY(1,1) PRIMARY KEY,
    PromoCode VARCHAR(20) UNIQUE NOT NULL,
    PromoName NVARCHAR(100) NOT NULL,
    DiscountPercent DECIMAL(5,2) DEFAULT 0,
    MaxDiscountAmount DECIMAL(18,2) NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL
);

CREATE TABLE [Booking] (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL, 
    CreatedByID INT NOT NULL, 
    RoomID INT NOT NULL,
    BookingTime DATETIME DEFAULT GETDATE(),
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NULL,
    Status NVARCHAR(50) DEFAULT 'Pending',
	StaffId INT NULL,
    GuestCount INT NULL DEFAULT 1,
    Note NVARCHAR(255) NULL,
    FOREIGN KEY (CustomerID) REFERENCES [Customer](CustomerID),
	FOREIGN KEY (StaffId) REFERENCES [Account](AccountID),
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
    CheckOutTime DATETIME NULL,
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
    IsService BIT NOT NULL DEFAULT 1,
    IsFulFilled BIT NOT NULL DEFAULT 0,
    Note NVARCHAR(255) NULL,
    FOREIGN KEY (InvoiceID) REFERENCES [Invoice](InvoiceID),
    FOREIGN KEY (ServiceID) REFERENCES [ServiceItem](ServiceID)
);

-- ==========================================
-- 5. TẠO BẢNG THANH TOÁN & CHI PHÍ
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
    ReferenceCode VARCHAR(100) NULL,
    FOREIGN KEY (InvoiceID) REFERENCES [Invoice](InvoiceID),
    FOREIGN KEY (MethodID) REFERENCES [PaymentMethod](MethodID)
);
CREATE TABLE [ExpenseCategory] (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(200) NOT NULL
);

CREATE TABLE [Expense] (
    ExpenseID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT NOT NULL,
    ExpenseDate DATE NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Note NVARCHAR(255) NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CategoryID) REFERENCES [ExpenseCategory](CategoryID)
);
-- ==========================================
-- 6. TẠO BẢNG PHÂN HỆ QUẢN LÝ NHÂN SỰ (HRM)
-- ==========================================

CREATE TABLE [EmployeeSchedule] (
    ScheduleID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    ShiftID INT NOT NULL,
    WorkDate DATE NOT NULL,
    Status NVARCHAR(30) NULL DEFAULT 'Scheduled',
    IsActive BIT NULL DEFAULT 1,
    FOREIGN KEY (AccountID) REFERENCES [Account](AccountID),
    FOREIGN KEY (ShiftID) REFERENCES [WorkShift](ShiftID)
);

CREATE TABLE [Attendance] (
    AttendanceID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    ScheduleID INT NULL,
    CheckInTime DATETIME NOT NULL,
    CheckOutTime DATETIME NULL,
    TotalHours DECIMAL(5,2) NULL,
    Status NVARCHAR(30) NULL DEFAULT 'OnTime',
    Note NVARCHAR(255) NULL,
    FOREIGN KEY (AccountID) REFERENCES [Account](AccountID),
    FOREIGN KEY (ScheduleID) REFERENCES [EmployeeSchedule](ScheduleID)
);

CREATE TABLE [EmployeeProfile] (
    ProfileID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    IdentityCardNumber VARCHAR(20) NOT NULL,
    DateOfBirth DATE NULL,
    Address NVARCHAR(255) NULL,
    HireDate DATE NOT NULL,
    BaseHourlyRate DECIMAL(18,2) NULL DEFAULT 0,
    FOREIGN KEY (AccountID) REFERENCES [Account](AccountID)
);

CREATE TABLE [TrainingRecord] (
    TrainingID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    CourseName NVARCHAR(150) NOT NULL,
    CompletionDate DATE NULL,
    Result NVARCHAR(50) NULL DEFAULT 'Passed',
    FOREIGN KEY (AccountID) REFERENCES [Account](AccountID)
);

CREATE TABLE [EmployeeTask] (
    TaskID INT IDENTITY(1,1) PRIMARY KEY,
    AssignedToID INT NOT NULL,
    CreatedByID INT NOT NULL,
    Title NVARCHAR(150) NOT NULL,
    Description NVARCHAR(500) NULL,
    DueDate DATETIME NOT NULL,
    Status NVARCHAR(30) NULL DEFAULT 'Pending',
    FOREIGN KEY (AssignedToID) REFERENCES [Account](AccountID),
    FOREIGN KEY (CreatedByID) REFERENCES [Account](AccountID)
);

CREATE TABLE [LeaveRequest] (
    LeaveRequestId INT IDENTITY(1,1) PRIMARY KEY,
    AccountId INT NOT NULL,
    ScheduleId INT NULL,
    Reason NVARCHAR(500) NOT NULL,
    Status VARCHAR(30) NOT NULL DEFAULT 'Pending',
    CreatedAt DATETIME NULL DEFAULT GETDATE(),
    ApprovedById INT NULL,
    RequestedDate DATE NULL,
    ShiftId INT NULL,
    FOREIGN KEY (AccountId) REFERENCES [Account](AccountID),
    FOREIGN KEY (ScheduleId) REFERENCES [EmployeeSchedule](ScheduleID),
    FOREIGN KEY (ApprovedById) REFERENCES [Account](AccountID),
    FOREIGN KEY (ShiftId) REFERENCES [WorkShift](ShiftID)
);

CREATE TABLE [ShiftSwapRequest] (
    SwapRequestId INT IDENTITY(1,1) PRIMARY KEY,
    RequesterId INT NOT NULL,
    RequesterScheduleId INT NOT NULL,
    TargetId INT NOT NULL,
    TargetScheduleId INT NOT NULL,
    Status VARCHAR(30) NOT NULL DEFAULT 'Pending',
    CreatedAt DATETIME NULL DEFAULT GETDATE(),
    ApprovedById INT NULL,
    FOREIGN KEY (RequesterId) REFERENCES [Account](AccountID),
    FOREIGN KEY (RequesterScheduleId) REFERENCES [EmployeeSchedule](ScheduleID),
    FOREIGN KEY (TargetId) REFERENCES [Account](AccountID),
    FOREIGN KEY (TargetScheduleId) REFERENCES [EmployeeSchedule](ScheduleID),
    FOREIGN KEY (ApprovedById) REFERENCES [Account](AccountID)
);

-- ==========================================
-- 7. TẠO BẢNG PHÂN HỆ QUẢN LÝ KHÁCH HÀNG (CRM)
-- ==========================================

CREATE TABLE [NotificationLog] (
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,
    BookingID INT NULL,
    CustomerID INT NOT NULL,
    Channel VARCHAR(20) NOT NULL,
    Recipient VARCHAR(100) NOT NULL,
    MessageContent NVARCHAR(MAX) NOT NULL,
    SentStatus VARCHAR(20) NULL DEFAULT 'Pending',
    SentAt DATETIME NULL DEFAULT GETDATE(),
    FOREIGN KEY (BookingID) REFERENCES [Booking](BookingID),
    FOREIGN KEY (CustomerID) REFERENCES [Customer](CustomerID)
);

CREATE TABLE [CustomerReview] (
    ReviewID INT IDENTITY(1,1) PRIMARY KEY,
    BookingID INT NOT NULL,
    Rating INT NOT NULL,
    Comment NVARCHAR(500) NULL,
    CreatedAt DATETIME NULL DEFAULT GETDATE(),
    FOREIGN KEY (BookingID) REFERENCES Booking(BookingID)
);

CREATE TABLE [MarketingCampaign] (
    CampaignID INT IDENTITY(1,1) PRIMARY KEY,
    PromotionID INT NULL,
    CampaignName NVARCHAR(150) NOT NULL,
    Channel VARCHAR(30) NOT NULL,
    TargetTierID INT NULL,
    MessageTemplate NVARCHAR(MAX) NOT NULL,
    StartDate DATETIME NOT NULL,
    Status NVARCHAR(30) NULL DEFAULT 'Draft',
    FOREIGN KEY (PromotionID) REFERENCES [Promotion](PromotionID),
    FOREIGN KEY (TargetTierID) REFERENCES [MembershipTier](TierID)
);

CREATE TABLE [CustomerCareLog] (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    AccountID INT NOT NULL,
    InteractionType NVARCHAR(50) NOT NULL,
    Notes NVARCHAR(MAX) NOT NULL,
    LoggedDate DATETIME NULL DEFAULT GETDATE(),
    FOREIGN KEY (CustomerID) REFERENCES [Customer](CustomerID),
    FOREIGN KEY (AccountID) REFERENCES [Account](AccountID)
);

CREATE TABLE [CustomerAutomationRule] (
    RuleID INT IDENTITY(1,1) PRIMARY KEY,
    RuleName NVARCHAR(100) NOT NULL,
    EventType VARCHAR(50) NOT NULL,
    ActionPayload NVARCHAR(MAX) NOT NULL,
    IsActive BIT NULL DEFAULT 1
);

CREATE TABLE LoyalPointPolicy (
    PolicyId INT IDENTITY(1,1) PRIMARY KEY,
    AmountPerPoint DECIMAL(18, 2) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    Description NVARCHAR(255) NULL
);

-- ==========================================
-- 8. TẠO BẢNG TIÊU CHÍ GIÁ CẢ & LỊCH SỬ PHÒNG
-- ==========================================

CREATE TABLE [Holiday] (
    HolidayID INT IDENTITY(1,1) PRIMARY KEY,
    HolidayName NVARCHAR(100) NOT NULL,
    HolidayDate DATE NOT NULL,
    SurchargePercent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    IsActive BIT NULL DEFAULT 1
);

CREATE TABLE [PricingPolicy] (
    PolicyID INT IDENTITY(1,1) PRIMARY KEY,
    PolicyName NVARCHAR(100) NOT NULL,
    PolicyType VARCHAR(20) NOT NULL,
    Value DECIMAL(5,2) NOT NULL,
    IsActive BIT NULL DEFAULT 1
);

CREATE TABLE [RoomPrice] (
    PriceID INT IDENTITY(1,1) PRIMARY KEY,
    RoomTypeID INT NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    PricePerHour DECIMAL(18,2) NOT NULL,
    EffectiveFrom DATE NULL,
    EffectiveTo DATE NULL,
    FOREIGN KEY (RoomTypeID) REFERENCES [RoomType](RoomTypeID)
);

CREATE TABLE [RoomTransferHistory] (
    TransferID INT IDENTITY(1,1) PRIMARY KEY,
    BookingID INT NOT NULL,
    FromRoomID INT NOT NULL,
    ToRoomID INT NOT NULL,
    TransferredAt DATETIME NOT NULL DEFAULT GETDATE(),
    Reason NVARCHAR(255) NOT NULL,
    ProcessedByID INT NOT NULL,
    FOREIGN KEY (BookingID) REFERENCES [Booking](BookingID),
    FOREIGN KEY (FromRoomID) REFERENCES [Room](RoomID),
    FOREIGN KEY (ToRoomID) REFERENCES [Room](RoomID),
    FOREIGN KEY (ProcessedByID) REFERENCES [Account](AccountID)
);
GO

-- ==========================================
-- 9. DỮ LIỆU SEED (CHÈN DỮ LIỆU MẪU)
-- ==========================================


-- Disable all constraints temporarily
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all';

SET IDENTITY_INSERT [Role] ON;
INSERT INTO [Role] (RoleID, RoleName) VALUES (1, N'Admin');
INSERT INTO [Role] (RoleID, RoleName) VALUES (2, N'Manager');
INSERT INTO [Role] (RoleID, RoleName) VALUES (3, N'Receptionist');
INSERT INTO [Role] (RoleID, RoleName) VALUES (4, N'Service Staff');
SET IDENTITY_INSERT [Role] OFF;

SET IDENTITY_INSERT [MembershipTier] ON;
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (1, N'Khách Mới', 0.00, 0);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (2, N'Đồng', 5.00, 1000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (3, N'Bạc', 10.00, 3000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (4, N'Vàng', 15.00, 7000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (5, N'Kim Cương', 20.00, 15000);
SET IDENTITY_INSERT [MembershipTier] OFF;

SET IDENTITY_INSERT [LoyalPointPolicy] ON;
INSERT INTO LoyalPointPolicy (AmountPerPoint, IsActive, Description)
VALUES (10000, 1, N'Quy đổi 10,000 VNĐ = 1 điểm tích lũy');
SET IDENTITY_INSERT [LoyalPointPolicy] OFF;


SET IDENTITY_INSERT [RoomType] ON;
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (1, N'Phòng Thường', 150000.00, N'Sức chứa 5-8 người', 'https://noithatvieta.vn/upload/images/2021/tu-van-thiet-ke/phong-hat-binh-dan-03.jpg', 5);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (2, N'Phòng VIP', 300000.00, N'Sức chứa 10-15 người', 'https://www.vntrip.vn/cam-nang/wp-content/uploads/2020/03/top-quan-cafe-vip-nhat-ha-noi-1.jpg', 15);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (3, N'Phòng Party', 600000.00, N'Sức chứa 30 người', 'https://vietwave.com.vn/karaokebay/upload/files/sanpham/thiet_ke_phong_hat_dep_1024x576.jpg', 30);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (4, N'Phòng Couple', 120000.00, N'Sức chứa 2-4 người', 'https://noithatktv.vn/wp-content/uploads/2021/01/thiet-ke-phong-hat-karaoke-gia-dinh-1.jpg', 10);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (5, N'Phòng Super VIP (Party)', 600000.00, N'Sức chứa 30 người', 'https://noithatkaraoke.vn/upload/images/mau-phong-karaoke/phong-karaoke-2024/phong-karaoke-phong-cach-moi-nam-2024.jpg', 10);
SET IDENTITY_INSERT [RoomType] OFF;

SET IDENTITY_INSERT [Category] ON;
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (1, N'Đồ Uống');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (2, N'Đồ Ăn');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (3, N'Trái Cây');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (4, N'Combo');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (5, N'Bia');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (6, N'Rượu');
SET IDENTITY_INSERT [Category] OFF;

SET IDENTITY_INSERT [Supplier] ON;
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (1, N'Bia Nước Ngọt Thành Phát', N'Anh Thành', N'0901111222', N'Q10');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (2, N'Rượu Ngoại Sài Gòn', N'Chị Hương', N'0903333444', N'Q1');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (3, N'Bia Nước Ngọt Thành Phát', N'Anh Thành', N'0901111222', N'Q10');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (4, N'Rượu Ngoại Sài Gòn', N'Chị Hương', N'0903333444', N'Q1');
SET IDENTITY_INSERT [Supplier] OFF;

SET IDENTITY_INSERT [Promotion] ON;
INSERT INTO [Promotion] (PromotionID, PromoCode, PromoName, DiscountPercent, MaxDiscountAmount, StartDate, EndDate) VALUES (1, N'NEWYEAR', N'Giảm 20%', 20.00, 500000.00, '2024-01-01 00:00:00', '2024-01-31 00:00:00');
INSERT INTO [Promotion] (PromotionID, PromoCode, PromoName, DiscountPercent, MaxDiscountAmount, StartDate, EndDate) VALUES (2, N'NOPROMO', N'Không KM', 0.00, 0.00, '2000-01-01 00:00:00', '2099-12-31 00:00:00');
SET IDENTITY_INSERT [Promotion] OFF;

SET IDENTITY_INSERT [PaymentMethod] ON;
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (1, N'Tiền mặt');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (2, N'VNPay');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (3, N'Visa');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (4, N'Momo');
SET IDENTITY_INSERT [PaymentMethod] OFF;

SET IDENTITY_INSERT [WorkShift] ON;
INSERT INTO [WorkShift] (ShiftID, ShiftName, StartTime, EndTime) VALUES (1, N'Ca Sáng', '08:00:00', '16:00:00');
INSERT INTO [WorkShift] (ShiftID, ShiftName, StartTime, EndTime) VALUES (2, N'Ca Chiều', '16:00:00', '00:00:00');
INSERT INTO [WorkShift] (ShiftID, ShiftName, StartTime, EndTime) VALUES (3, N'Ca Khuya', '00:00:00', '08:00:00');
SET IDENTITY_INSERT [WorkShift] OFF;

SET IDENTITY_INSERT [Holiday] ON;
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (1, N'Tết Dương Lịch 2026', '2026-01-01 00:00:00', 20.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (2, N'Tết Nguyên Đán 2026 (Giao Thừa)', '2026-02-16 00:00:00', 200.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (3, N'Tết Nguyên Đán 2026 (Mùng 1)', '2026-02-17 00:00:00', 200.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (4, N'Tết Nguyên Đán 2026 (Mùng 2)', '2026-02-18 00:00:00', 150.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (5, N'Tết Nguyên Đán 2026 (Mùng 3)', '2026-02-19 00:00:00', 100.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (6, N'Giỗ Tổ Hùng Vương 2026', '2026-04-26 00:00:00', 30.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (7, N'Ngày Giải Phóng Miền Nam', '2026-04-30 00:00:00', 50.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (8, N'Quốc Tế Lao Động', '2026-05-01 00:00:00', 50.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (9, N'Quốc Khánh', '2026-09-02 00:00:00', 40.00, 1);
SET IDENTITY_INSERT [Holiday] OFF;

SET IDENTITY_INSERT [PricingPolicy] ON;
INSERT INTO [PricingPolicy] (PolicyID, PolicyName, PolicyType, Value, IsActive) VALUES (1, N'Phụ thu Cuối tuần (T7 & CN)', N'Weekend', 15.00, 1);
INSERT INTO [PricingPolicy] (PolicyID, PolicyName, PolicyType, Value, IsActive) VALUES (2, N'Phụ thu Ngày lễ chung', N'Holiday', 30.00, 1);
SET IDENTITY_INSERT [PricingPolicy] OFF;

SET IDENTITY_INSERT [CustomerAutomationRule] ON;
INSERT INTO [CustomerAutomationRule] (RuleID, RuleName, EventType, ActionPayload, IsActive) VALUES (1, N'Tự động lên hạng', N'OnPointsEarned', N'{"Threshold": 1000, "NewTier": 2}', NULL);
INSERT INTO [CustomerAutomationRule] (RuleID, RuleName, EventType, ActionPayload, IsActive) VALUES (2, N'Chúc mừng sinh nhật', N'OnBirthday', N'{"TemplateID": 1, "Discount": 20}', NULL);
SET IDENTITY_INSERT [CustomerAutomationRule] OFF;

SET IDENTITY_INSERT [Account] ON;

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (1, 1, 'admin_tong', '123456', N'Nguyễn Quản Trị', '0900000001', 'admin@karaoke.com', '2026-06-27 21:58:47', NULL, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (2, 2, 'quanly_hung', '123456', N'Trần Hùng (Quản Lý)', '0900000002', 'hung@karaoke.com', '2026-06-27 21:58:47', NULL, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (3, 3, 'letan_lan', '123456', N'Lê Thị Lan', '0900000003', 'lan@karaoke.com', '2026-06-27 21:58:47', 1, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (4, 3, 'letan_mai', '123456', N'Phạm Mai', '0900000004', 'mai@karaoke.com', '2026-06-27 21:58:47', 2, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (9, 3, 'servicestaff_c', '123456', N'Hoàng Anh Em', '0922334455', 'hoanganhe@gmail.com', '2026-07-21 16:03:17', 3, NULL, NULL, 0);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (11, 4, 'service1', '123456', N'Nguyễn Phục Vụ 1', '0912345601', 'service1@karaoke.com', '2026-07-22 15:47:51', 1, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (12, 4, 'service2', '123456', N'Trần Phục Vụ 2', '0912345602', 'service2@karaoke.com', '2026-07-22 15:47:51', 2, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (13, 4, 'service3', '123456', N'Lê Phục Vụ 3', '0912345603', 'service3@karaoke.com', '2026-07-22 15:47:51', 3, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (14, 4, 'service4', '123456', N'Phạm Phục Vụ 4', '0912345604', 'service4@karaoke.com', '2026-07-22 15:47:51', 1, NULL, NULL, 1);

SET IDENTITY_INSERT [Account] OFF;

SET IDENTITY_INSERT [Customer] ON;

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (1, 5, N'Lê Minh Tuấn (VIP)', '0911111111', 'tuanvip@gmail.com', '123456', 16500, '2026-06-27 21:58:47', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (2, 4, N'Nguyễn Việt Hoàng', '0922222222', 'hoangnv@gmail.com', '123456', 8200, '2026-06-27 21:58:47', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (3, 3, N'Trần Tiến Dũng', '0933333333', 'dungtt@gmail.com', '123456', 3500, '2026-06-27 21:58:47', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (4, 2, N'Phạm Thu Thủy', '0944444444', 'thuypham@gmail.com', '123456', 1200, '2026-06-27 21:58:47', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (5, 1, N'Đinh Thanh Hà', '0955555555', 'hadinh@gmail.com', '123456', 150, '2026-06-27 21:58:47', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (6, 1, N'Khách Vãng Lai', '0000000000', NULL, '123456', 0, '2026-06-27 21:58:47', NULL, NULL, 0);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (7, 5, N'Lê Minh Tuấn (VIP)', '0911111111', 'tuanvip@gmail.com', '123456', 16500, '2026-07-22 19:45:15', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (8, 4, N'Nguyễn Việt Hoàng', '0922222222', 'hoangnv@gmail.com', '123456', 8200, '2026-07-22 19:45:15', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (9, 3, N'Trần Tiến Dũng', '0933333333', 'dungtt@gmail.com', '123456', 3500, '2026-07-22 19:45:15', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (10, 2, N'Phạm Thu Thủy', '0944444444', 'thuypham@gmail.com', '123456', 1200, '2026-07-22 19:45:15', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (11, 1, N'Đinh Thanh Hà', '0955555555', 'hadinh@gmail.com', '123456', 150, '2026-07-22 19:45:15', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (12, 1, N'Khách Vãng Lai', '0000000000', NULL, '123456', 0, '2026-07-22 19:45:15', NULL, NULL, 0);

SET IDENTITY_INSERT [Customer] OFF;

SET IDENTITY_INSERT [Room] ON;

INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (1, 1, N'Tầng 1 - 101', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (2, 2, N'Tầng 1 - 102', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (3, 3, N'Tầng 1 - 103', N'Maintenance');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (4, 4, N'Tầng 1 - 104 (Couple)', N'InUse');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (5, 1, N'Tầng 2 - 201 (VIP)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (6, 2, N'Tầng 2 - 202 (VIP)', N'InUse');    
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (7, 3, N'Tầng 2 - 203 (VIP)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (8, 4, N'Tầng 2 - 204 (VIP)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (9, 1, N'Tầng 3 - 301 (Party)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (10, 2, N'Tầng 3 - 302 (Party)', N'InUse'); 
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (11, 3, N'Tầng 3 - 303 (Party)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (12, 4, N'Tầng 3 - 304 (Party)', N'InUse'); 
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (13, 1, N'Tầng 4 - 401', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (14, 2, N'Tầng 4 - 402', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (15, 4, N'Tầng 4 - 403', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (16, 5, N'Tầng 4 - 404 (Super VIP)', N'Available');

SET IDENTITY_INSERT [Room] OFF;

SET IDENTITY_INSERT [Equipment] ON;
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (1, 5, N'Tivi Samsung 65 Inch', N'SS-65-001', '2023-01-15 00:00:00', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (2, 5, N'Micro Shure', N'SH-001', '2023-01-15 00:00:00', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (3, 6, N'Micro Shure', N'SH-003', '2023-01-15 00:00:00', N'Broken');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (4, 8, N'Loa JBL', N'JBL-001', '2023-05-20 00:00:00', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (5, 3, N'Điều hòa Panasonic', N'PN-AC-001', '2022-10-10 00:00:00', N'Repairing');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (6, 5, N'Tivi Samsung 65 Inch', N'SS-65-001', '2023-01-15 00:00:00', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (7, 5, N'Micro Shure', N'SH-001', '2023-01-15 00:00:00', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (8, 6, N'Micro Shure', N'SH-003', '2023-01-15 00:00:00', N'Broken');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (9, 8, N'Loa JBL', N'JBL-001', '2023-05-20 00:00:00', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (10, 3, N'Điều hòa Panasonic', N'PN-AC-001', '2022-10-10 00:00:00', N'Repairing');
SET IDENTITY_INSERT [Equipment] OFF;

SET IDENTITY_INSERT [MaintenanceLog] ON;
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (1, 3, 3, N'Rớt móp đầu mic', 150000.00, '2026-06-22 21:58:47');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (2, 5, 2, N'Máy kêu to', 500000.00, '2026-06-26 21:58:47');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (3, 3, 3, N'Rớt móp đầu mic', 150000.00, '2026-07-17 19:45:15');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (4, 5, 2, N'Máy kêu to', 500000.00, '2026-07-21 19:45:15');
SET IDENTITY_INSERT [MaintenanceLog] OFF;

SET IDENTITY_INSERT [ServiceItem] ON;
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (1, 5, 'https://images.unsplash.com/photo-1599419685838-28e405ea05b9?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', N'Heineken', 40000.00, N'Lon', 500);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (2, 5, 'https://images.unsplash.com/photo-1624795763669-d3605b99a0cb?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', N'Tiger', 30000.00, N'Lon', 800);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (11, 5, 'https://product.hstatic.net/200000768759/product/bia-sai-gon-special-bun-bo-ganh_5d620d0b06814c71921dd7f9a93d620f_master.png', N'Saigon Bia', 40000.00, N'Lon', 500);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (12, 5, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTEAJDIigBoE2SlJPVg0CMhqP3Udgm9w6e4K9ScBQM94g&s=10', N'333 Bia', 30000.00, N'Lon', 800);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (3, 6, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfaRpKLvTJqyAa2h2Pbft9SkIdv0NMNWDZNE2WwU0aFw&s=10', N'Chivas 12', 1500000.00, N'Chai', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (13, 6, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTnc4P2O4yblkjCh7c8pyNGWelPlJy3WQnCiVf4-oeA8Q&s=10', N'Chivas 32', 1500000.00, N'Chai', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (4, 1, 'https://sonhawater.com/wp-content/uploads/2019/10/aquafina-15-lit.jpg', N'Aquafina', 20000.00, N'Chai', 400);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (14, 1, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoe6keF5DkVOszFGOBSaBb4-gKCPuj8LHeo6ooGMDeSw&s=10', N'Lavie', 20000.00, N'Chai', 400);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (5, 2, 'https://bokhothuba.com/wp-content/uploads/2020/03/bo-kho-soi-2.jpg', N'Khô bò', 150000.00, N'Đĩa', 50);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (15, 2, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcStfEu0XWU5xbEOCKjTsh5bDFm3LfqVPRSALgnv2G1sNoBguqzVDyZLc-M&s=10', N'Khô gà Mixi', 150000.00, N'Đĩa', 50);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (6, 3, 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?auto=format&fit=crop&q=80&w=600', N'Trái cây VIP loại 2', 450000.00, N'Đĩa', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (8, 2, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT_37y9BhxeWYbd5tpGG4ZcOpzH5LoL7Sx0V23yoNtlYA&s=10', N'Đào Tiên', 3000000.00, N'EM', 5);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (16, 3, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQCcjJQx2h7QZ7m_vD_fAuwQ5leiAj3JPa-TC1Su1MYXQ&s=10', N'Trái cây VIP', 350000.00, N'Đĩa', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (7, 4, 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?auto=format&fit=crop&q=80&w=600', N'Combo Sinh Nhật VIP', 4000000.00, N'Combo', 5);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (17, 4, 'https://images.unsplash.com/photo-1558636508-e0db3814bd1d?auto=format&fit=crop&q=80&w=600', N'Combo Sinh Nhật', 1500000.00, N'Combo', 5);
SET IDENTITY_INSERT [ServiceItem] OFF;

SET IDENTITY_INSERT [PurchaseOrder] ON;
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (1, 1, 2, '2023-10-01 00:00:00', 25000000.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (2, 2, 2, '2023-10-05 00:00:00', 45000000.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (3, 1, 2, '2026-07-12 22:33:52', 7500000.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (4, 1, 2, '2026-07-12 22:35:10', 240.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (5, 1, 2, '2026-07-12 22:49:08', 15000000.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (6, 1, 2, '2023-10-01 00:00:00', 25000000.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (7, 2, 2, '2023-10-05 00:00:00', 45000000.00);
SET IDENTITY_INSERT [PurchaseOrder] OFF;

SET IDENTITY_INSERT [PurchaseOrderDetail] ON;
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (1, 1, 1, 25000.00, 300);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (2, 1, 2, 18000.00, 500);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (3, 2, 3, 1000000.00, 10);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (4, 3, 8, 1500000.00, 5);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (5, 4, 11, 12.00, 20);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (6, 5, 12, 1000000.00, 15);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (7, 1, 1, 25000.00, 300);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (8, 1, 2, 18000.00, 500);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (9, 2, 3, 1000000.00, 10);
SET IDENTITY_INSERT [PurchaseOrderDetail] OFF;

SET IDENTITY_INSERT [RoomPrice] ON;
INSERT INTO [RoomPrice] (PriceID, RoomTypeID, StartTime, EndTime, PricePerHour, EffectiveFrom, EffectiveTo) VALUES (1, 1, '08:00:00', '17:00:00', 120000.00, NULL, NULL);
INSERT INTO [RoomPrice] (PriceID, RoomTypeID, StartTime, EndTime, PricePerHour, EffectiveFrom, EffectiveTo) VALUES (2, 1, '17:00:00', '23:59:59', 180000.00, NULL, NULL);
INSERT INTO [RoomPrice] (PriceID, RoomTypeID, StartTime, EndTime, PricePerHour, EffectiveFrom, EffectiveTo) VALUES (3, 2, '08:00:00', '17:00:00', 220000.00, NULL, NULL);
INSERT INTO [RoomPrice] (PriceID, RoomTypeID, StartTime, EndTime, PricePerHour, EffectiveFrom, EffectiveTo) VALUES (4, 2, '17:00:00', '23:59:59', 300000.00, NULL, NULL);
INSERT INTO [RoomPrice] (PriceID, RoomTypeID, StartTime, EndTime, PricePerHour, EffectiveFrom, EffectiveTo) VALUES (5, 3, '08:00:00', '17:00:00', 400000.00, NULL, NULL);
INSERT INTO [RoomPrice] (PriceID, RoomTypeID, StartTime, EndTime, PricePerHour, EffectiveFrom, EffectiveTo) VALUES (6, 3, '17:00:00', '23:59:59', 500000.00, NULL, NULL);
INSERT INTO [RoomPrice] (PriceID, RoomTypeID, StartTime, EndTime, PricePerHour, EffectiveFrom, EffectiveTo) VALUES (7, 4, '08:00:00', '17:00:00', 90000.00, NULL, NULL);
INSERT INTO [RoomPrice] (PriceID, RoomTypeID, StartTime, EndTime, PricePerHour, EffectiveFrom, EffectiveTo) VALUES (8, 4, '17:00:00', '23:59:59', 120000.00, NULL, NULL);
SET IDENTITY_INSERT [RoomPrice] OFF;

SET IDENTITY_INSERT [Booking] ON;

-- Đơn phòng 5 (Đã hoàn thành trong quá khứ)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (1, 1, 3, 5, '2026-06-24 21:58:47', '2026-06-25 21:58:47', '2026-06-26 01:58:47', N'Completed', 11, 4, N'Khách gọi đặt trước');

-- Đơn phòng 8 (Đã hoàn thành trong quá khứ)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (2, 2, 4, 8, '2026-06-26 21:58:47', '2026-06-26 21:58:47', '2026-06-27 00:58:47', N'Completed', 12, 10, N'Sinh nhật');

-- Đơn phòng 4 (Đã hoàn thành trong quá khứ)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (3, 3, 3, 4, '2026-06-27 21:58:47', '2026-06-27 21:58:47', '2026-06-27 23:58:47', N'Completed', 13, NULL, NULL);

-- Đơn phòng 1 (Đã hoàn thành trong quá khứ)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (4, 1, 3, 1, '2026-06-12 21:58:47', '2026-06-13 21:58:47', '2026-06-13 23:58:47', N'Completed', 14, NULL, NULL);

-- Đơn phòng 2 (Chờ nhận phòng ngày mai -> Phòng 2 vẫn Available)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (5, 2, 3, 2, '2026-07-24 21:58:47', '2026-07-25 20:00:00', '2026-07-25 22:00:00', N'Pending', NULL, 4, N'Sinh nhật');

-- 🟢 ĐẮT PHÒNG 4: Đang sử dụng (CheckedIn) -> Khớp với Room 4 (InUse)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (6, 3, 4, 4, '2026-07-24 15:00:00', '2026-07-24 17:00:00', '2026-07-24 22:00:00', N'CheckedIn', 11, 3, N'Khách đang hát');

-- Đơn phòng 5 (Chờ nhận phòng ngày mai -> Phòng 5 vẫn Available)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (7, 4, 4, 5, '2026-07-24 10:00:00', '2026-07-25 17:00:00', '2026-07-25 19:00:00', N'Pending', NULL, 4, N'Có thể đến muộn 10p');

-- 🟢 ĐẶT PHÒNG 6: Đang sử dụng (CheckedIn) -> Khớp với Room 6 (InUse)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (8, 5, 3, 6, '2026-07-24 16:00:00', '2026-07-24 17:30:00', '2026-07-24 21:30:00', N'CheckedIn', 12, 2, N'Khách nhận phòng sớm');

-- Đơn lịch sử (Completed)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (9, 1, 3, 7, '2026-06-17 21:58:47', '2026-06-18 21:58:47', '2026-06-18 23:58:47', N'Completed', 13, NULL, NULL);

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (10, 2, 4, 8, '2026-06-18 21:58:47', '2026-06-19 21:58:47', '2026-06-20 00:58:47', N'Completed', 14, NULL, NULL);

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (11, 3, 4, 9, '2026-06-19 21:58:47', '2026-06-20 21:58:47', '2026-06-21 01:58:47', N'Completed', 11, NULL, NULL);

-- 🟢 ĐẶT PHÒNG 10: Đang sử dụng (CheckedIn) -> Khớp với Room 10 (InUse)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (12, 4, 3, 10, '2026-07-24 14:00:00', '2026-07-24 16:30:00', '2026-07-24 20:30:00', N'CheckedIn', 12, 8, N'Tiệc công ty');

-- Đơn lịch sử (Completed)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (13, 5, 3, 1, '2026-06-21 21:58:47', '2026-06-22 21:58:47', '2026-06-23 00:58:47', N'Completed', 13, NULL, NULL);

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (14, 1, 4, 2, '2026-06-22 21:58:47', '2026-06-23 21:58:47', '2026-06-23 23:58:47', N'Completed', 14, NULL, NULL);

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (15, 2, 4, 5, '2026-06-23 21:58:47', '2026-06-24 21:58:47', '2026-06-25 01:58:47', N'Completed', 11, NULL, NULL);

-- 🟢 ĐẶT PHÒNG 12: Bổ sung mới -> Đang sử dụng (CheckedIn) -> Khớp với Room 12 (InUse)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (16, 5, 4, 12, '2026-07-24 15:30:00', '2026-07-24 17:00:00', '2026-07-24 21:00:00', N'CheckedIn', 12, 12, N'Khách vãng lai vào thẳng');

SET IDENTITY_INSERT [Booking] OFF;

SET IDENTITY_INSERT [Invoice] ON;
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (1, 1, 5, 3, 2, '2026-06-25 21:58:47', '2026-06-26 01:58:47', 1200000.00, 2750000.00, 790000.00, 3160000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (2, 2, 8, 3, 1, '2026-06-26 21:58:47', '2026-06-27 00:58:47', 1800000.00, 1500000.00, 500000.00, 2800000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (3, 3, 4, 4, 2, '2026-06-27 21:58:47', NULL, 0.00, 0.00, 0.00, 0.00, N'Unpaid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (4, 4, 1, 3, 2, '2026-06-13 21:58:47', '2026-06-13 23:58:47', 300000.00, 140000.00, 0.00, 440000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (5, 5, 2, 3, 2, '2026-06-14 21:58:47', '2026-06-15 00:58:47', 450000.00, 80000.00, 0.00, 530000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (6, 6, 4, 4, 2, '2026-06-15 21:58:47', '2026-06-15 23:58:47', 240000.00, 190000.00, 0.00, 430000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (7, 7, 5, 4, 2, '2026-06-16 21:58:47', '2026-06-17 01:58:47', 1200000.00, 490000.00, 0.00, 1690000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (8, 8, 6, 3, 2, '2026-06-17 21:58:47', '2026-06-18 02:58:47', 1500000.00, 700000.00, 150000.00, 2050000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (9, 9, 7, 3, 2, '2026-06-18 21:58:47', '2026-06-18 23:58:47', 600000.00, 300000.00, 90000.00, 810000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (10, 10, 8, 4, 2, '2026-06-19 21:58:47', '2026-06-20 00:58:47', 1800000.00, 1500000.00, 330000.00, 2970000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (11, 11, 9, 4, 2, '2026-06-20 21:58:47', '2026-06-21 01:58:47', 2400000.00, 1500000.00, 390000.00, 3510000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (12, 12, 10, 3, 2, '2026-06-21 21:58:47', '2026-06-21 23:58:47', 300000.00, 100000.00, 0.00, 400000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (13, 13, 1, 3, 2, '2026-06-22 21:58:47', '2026-06-23 00:58:47', 450000.00, 260000.00, 0.00, 710000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (14, 14, 2, 4, 2, '2026-06-23 21:58:47', '2026-06-23 23:58:47', 300000.00, 140000.00, 0.00, 440000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (15, 15, 5, 4, 2, '2026-06-24 21:58:47', '2026-06-25 01:58:47', 1200000.00, 600000.00, 180000.00, 1620000.00, N'Paid');
SET IDENTITY_INSERT [Invoice] OFF;

SET IDENTITY_INSERT [InvoiceDetail] ON;
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (1, 1, 3, 1, 1500000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (2, 1, 6, 2, 350000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (3, 1, 5, 2, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (4, 2, 7, 1, 1500000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (5, 2, 2, 24, 30000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (6, 4, 1, 3, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (7, 4, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (8, 5, 2, 2, 30000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (9, 5, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (10, 6, 5, 1, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (11, 6, 1, 1, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (12, 7, 6, 1, 350000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (13, 7, 1, 3, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (14, 7, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (15, 8, 6, 2, 350000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (16, 9, 5, 2, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (17, 10, 7, 1, 1500000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (18, 11, 3, 1, 1500000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (19, 12, 1, 2, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (20, 12, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (21, 13, 5, 1, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (22, 13, 2, 3, 30000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (23, 13, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (24, 14, 1, 3, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (25, 14, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (26, 15, 6, 1, 350000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (27, 15, 5, 1, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (28, 15, 1, 2, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (29, 15, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (30, 1, 3, 1, 1500000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (31, 1, 6, 2, 350000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (32, 1, 5, 2, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (33, 2, 7, 1, 1500000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (34, 2, 2, 24, 30000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (35, 4, 1, 3, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (36, 4, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (37, 5, 2, 2, 30000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (38, 5, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (39, 6, 5, 1, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (40, 6, 1, 1, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (41, 7, 6, 1, 350000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (42, 7, 1, 3, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (43, 7, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (44, 8, 6, 2, 350000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (45, 9, 5, 2, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (46, 10, 7, 1, 1500000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (47, 11, 3, 1, 1500000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (48, 12, 1, 2, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (49, 12, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (50, 13, 5, 1, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (51, 13, 2, 3, 30000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (52, 13, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (53, 14, 1, 3, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (54, 14, 4, 1, 20000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (55, 15, 6, 1, 350000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (56, 15, 5, 1, 150000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (57, 15, 1, 2, 40000.00, 1, 0);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled) VALUES (58, 15, 4, 1, 20000.00, 1, 0);
SET IDENTITY_INSERT [InvoiceDetail] OFF;

SET IDENTITY_INSERT [PaymentTransaction] ON;
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (1, 1, 3, 3160000.00, '2026-06-26 01:58:47', N'VISA-123');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (2, 2, 1, 1000000.00, '2026-06-27 00:58:47', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (3, 2, 4, 1800000.00, '2026-06-27 00:58:47', N'MOMO-987');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (4, 4, 1, 440000.00, '2026-06-13 23:58:47', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (5, 5, 2, 530000.00, '2026-06-15 00:58:47', N'VNPAY-456');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (6, 6, 4, 430000.00, '2026-06-15 23:58:47', N'MOMO-111');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (7, 7, 3, 1690000.00, '2026-06-17 01:58:47', N'VISA-444');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (8, 8, 1, 2050000.00, '2026-06-18 02:58:47', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (9, 9, 2, 810000.00, '2026-06-18 23:58:47', N'VNPAY-777');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (10, 10, 4, 2970000.00, '2026-06-20 00:58:47', N'MOMO-222');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (11, 11, 3, 3510000.00, '2026-06-21 01:58:47', N'VISA-555');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (12, 12, 1, 400000.00, '2026-06-21 23:58:47', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (13, 13, 2, 710000.00, '2026-06-23 00:58:47', N'VNPAY-888');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (14, 14, 4, 440000.00, '2026-06-23 23:58:47', N'MOMO-333');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (15, 15, 3, 1620000.00, '2026-06-25 01:58:47', N'VISA-666');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (16, 1, 3, 3160000.00, '2026-07-20 23:45:15', N'VISA-123');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (17, 2, 1, 1000000.00, '2026-07-21 22:45:15', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (18, 2, 4, 1800000.00, '2026-07-21 22:45:15', N'MOMO-987');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (19, 4, 1, 440000.00, '2026-07-08 21:45:15', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (20, 5, 2, 530000.00, '2026-07-09 22:45:15', N'VNPAY-456');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (21, 6, 4, 430000.00, '2026-07-10 21:45:15', N'MOMO-111');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (22, 7, 3, 1690000.00, '2026-07-11 23:45:15', N'VISA-444');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (23, 8, 1, 2050000.00, '2026-07-13 00:45:15', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (24, 9, 2, 810000.00, '2026-07-13 21:45:15', N'VNPAY-777');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (25, 10, 4, 2970000.00, '2026-07-14 22:45:15', N'MOMO-222');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (26, 11, 3, 3510000.00, '2026-07-15 23:45:15', N'VISA-555');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (27, 12, 1, 400000.00, '2026-07-16 21:45:15', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (28, 13, 2, 710000.00, '2026-07-17 22:45:15', N'VNPAY-888');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (29, 14, 4, 440000.00, '2026-07-18 21:45:15', N'MOMO-333');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (30, 15, 3, 1620000.00, '2026-07-19 23:45:15', N'VISA-666');
SET IDENTITY_INSERT [PaymentTransaction] OFF;

SET IDENTITY_INSERT [ExpenseCategory] ON;
INSERT INTO [ExpenseCategory] (CategoryID, CategoryName) VALUES (1, N'Điện');
INSERT INTO [ExpenseCategory] (CategoryID, CategoryName) VALUES (2, N'Nước');
INSERT INTO [ExpenseCategory] (CategoryID, CategoryName) VALUES (3, N'Mặt bằng');
INSERT INTO [ExpenseCategory] (CategoryID, CategoryName) VALUES (4, N'Bảo trì');
SET IDENTITY_INSERT [ExpenseCategory] OFF;

SET IDENTITY_INSERT [Expense] ON;
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (1, 1, '2023-10-15 00:00:00', 5400000.00, N'Tiền điện tháng 9/2023', '2026-06-27 21:58:47');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (2, 4, '2023-10-14 00:00:00', 2100000.00, N'Sửa mic phòng VIP 1 & 2', '2026-06-27 21:58:47');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (3, 3, '2023-10-01 00:00:00', 25000000.00, N'Thuê mặt bằng tháng 10', '2026-06-27 21:58:47');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (4, 2, '2023-09-28 00:00:00', 850000.00, N'Tiền nước T9', '2026-06-27 21:58:47');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (6, 1, '2023-10-15 00:00:00', 5400000.00, N'Tiền điện tháng 9/2023', '2026-07-22 19:45:15');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (7, 4, '2023-10-14 00:00:00', 2100000.00, N'Sửa mic phòng VIP 1 & 2', '2026-07-22 19:45:15');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (8, 3, '2023-10-01 00:00:00', 25000000.00, N'Thuê mặt bằng tháng 10', '2026-07-22 19:45:15');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (9, 2, '2023-09-28 00:00:00', 850000.00, N'Tiền nước T9', '2026-07-22 19:45:15');
SET IDENTITY_INSERT [Expense] OFF;

SET IDENTITY_INSERT [RoomTransferHistory] ON;
SET IDENTITY_INSERT [RoomTransferHistory] OFF;

SET IDENTITY_INSERT [EmployeeProfile] ON;
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) VALUES (1, 1, N'001090123456', '1990-05-15 00:00:00', N'123 Đường A, Quận 1, TP.HCM', '2022-01-10 00:00:00', 35000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) VALUES (2, 3, N'079095654321', '1995-10-20 00:00:00', N'456 Đường B, Quận 3, TP.HCM', '2023-03-01 00:00:00', 30000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) VALUES (7, 9, N'052094556677', '1997-01-30 00:00:00', N'12 Cần Thơ, Ninh Kiều', '2023-05-12 00:00:00', 35000.00);
SET IDENTITY_INSERT [EmployeeProfile] OFF;

SET IDENTITY_INSERT [TrainingRecord] ON;
INSERT INTO [TrainingRecord] (TrainingID, AccountID, CourseName, CompletionDate, Result) VALUES (1, 1, N'Kỹ năng PCCC', '2023-05-10 00:00:00', N'Passed');
INSERT INTO [TrainingRecord] (TrainingID, AccountID, CourseName, CompletionDate, Result) VALUES (2, 3, N'Kỹ năng Giao tiếp khách hàng', '2023-06-15 00:00:00', N'Passed');
SET IDENTITY_INSERT [TrainingRecord] OFF;

SET IDENTITY_INSERT [EmployeeTask] ON;
INSERT INTO [EmployeeTask] (TaskID, AssignedToID, CreatedByID, Title, Description, DueDate, Status) VALUES (1, 3, 1, N'Dọn dẹp phòng VIP 1', N'Lau chùi bàn ghế, kiểm tra micro', '2026-07-21 17:07:43', N'Pending');
INSERT INTO [EmployeeTask] (TaskID, AssignedToID, CreatedByID, Title, Description, DueDate, Status) VALUES (2, 4, 1, N'Kiểm kê kho bia', N'Đếm số lượng bia Tiger và Heineken', '2026-07-22 15:07:43', N'InProgress');
SET IDENTITY_INSERT [EmployeeTask] OFF;

SET IDENTITY_INSERT [NotificationLog] ON;
INSERT INTO [NotificationLog] (NotificationID, BookingID, CustomerID, Channel, Recipient, MessageContent, SentStatus, SentAt) VALUES (1, 1, 1, N'SMS', N'0901234567', N'Cảm ơn quý khách đã đặt phòng tại Karaoke Management. Mã đặt phòng: #1', N'Sent', '2026-07-21 15:07:43');
INSERT INTO [NotificationLog] (NotificationID, BookingID, CustomerID, Channel, Recipient, MessageContent, SentStatus, SentAt) VALUES (2, 2, 2, N'Email', N'khachhang2@gmail.com', N'Phòng VIP 2 của quý khách đã sẵn sàng lúc 19:00', N'Sent', '2026-07-21 15:07:43');
SET IDENTITY_INSERT [NotificationLog] OFF;

SET IDENTITY_INSERT [MarketingCampaign] ON;
INSERT INTO [MarketingCampaign] (CampaignID, PromotionID, CampaignName, Channel, TargetTierID, MessageTemplate, StartDate, Status) VALUES (1, NULL, N'Chúc mừng sinh nhật VIP', N'SMS', 3, N'Chúc mừng sinh nhật! Tặng bạn voucher giảm 20%', '2026-07-21 15:07:43', N'Active');
INSERT INTO [MarketingCampaign] (CampaignID, PromotionID, CampaignName, Channel, TargetTierID, MessageTemplate, StartDate, Status) VALUES (2, NULL, N'Khuyến mãi Hè sôi động', N'Email', 2, N'Giảm 10% tiền phòng cho khách hàng Gold', '2026-07-26 15:07:43', N'Draft');
SET IDENTITY_INSERT [MarketingCampaign] OFF;

SET IDENTITY_INSERT [CustomerCareLog] ON;
INSERT INTO [CustomerCareLog] (LogID, CustomerID, AccountID, InteractionType, Notes, LoggedDate) VALUES (1, 1, 1, N'Gọi điện thoại', N'Hỏi thăm sự hài lòng về dịch vụ sinh nhật tối qua', '2026-07-21 15:07:43');
INSERT INTO [CustomerCareLog] (LogID, CustomerID, AccountID, InteractionType, Notes, LoggedDate) VALUES (2, 2, 3, N'Nhắn tin', N'Gửi thông báo chương trình khuyến mãi', '2026-07-21 15:07:43');
SET IDENTITY_INSERT [CustomerCareLog] OFF;

SET IDENTITY_INSERT [RoomImage] ON;
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (1, 1, N'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (2, 1, N'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (3, 2, N'https://images.unsplash.com/photo-1566737236500-c8ac43014a67?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (4, 2, N'https://images.unsplash.com/photo-1497911270199-1c552ee64aa4?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (5, 2, N'https://images.unsplash.com/photo-1574096079513-d8259312b78a?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (6, 3, N'https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (7, 3, N'https://images.unsplash.com/photo-1470229722913-7c092db65f8c?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (8, 3, N'https://images.unsplash.com/photo-1545128485-c400e7702796?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (9, 4, N'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (10, 4, N'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (11, 5, N'https://images.unsplash.com/photo-1571115764595-644a1f56a55c?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (12, 5, N'https://images.unsplash.com/photo-1598387993281-cecf8b71a8f8?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) 
VALUES (13, 5, N'https://images.unsplash.com/photo-1563514755106-96db86a7f7da?auto=format&fit=crop&q=80&w=1200');
SET IDENTITY_INSERT [RoomImage] OFF;

-- Re-enable all constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all';
