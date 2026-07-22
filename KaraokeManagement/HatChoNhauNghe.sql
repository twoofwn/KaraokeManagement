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
    ResetPasswordToken VARCHAR(256) NULL,
    ResetPasswordTokenExpiry DATETIME NULL,
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
    GuestCount INT NULL DEFAULT 1,
    Note NVARCHAR(255) NULL,
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

CREATE TABLE [Expense] (
    ExpenseID INT IDENTITY(1,1) PRIMARY KEY,
    Category NVARCHAR(50) NOT NULL,
    ExpenseDate DATE NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Note NVARCHAR(255) NULL,
    CreatedAt DATETIME DEFAULT GETDATE()
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
    IsActive BIT NOT NULL DEFAULT 1,
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

CREATE TABLE [Payroll] (
    PayrollID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    PayPeriodMonth INT NOT NULL,
    PayPeriodYear INT NOT NULL,
    BaseSalary DECIMAL(18,2) NOT NULL,
    BonusAmount DECIMAL(18,2) NULL DEFAULT 0,
    DeductionAmount DECIMAL(18,2) NULL DEFAULT 0,
    NetSalary DECIMAL(18,2) NOT NULL,
    PaymentStatus NVARCHAR(30) NULL DEFAULT 'Unpaid',
    PaymentDate DATETIME NULL,
    Note NVARCHAR(255) NULL,
    FOREIGN KEY (AccountID) REFERENCES [Account](AccountID)
);

CREATE TABLE [EmployeeProfile] (
    ProfileID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    IdentityCardNumber VARCHAR(20) NOT NULL,
    DateOfBirth DATE NULL,
    Address NVARCHAR(255) NULL,
    HireDate DATE NOT NULL,
    BaseHourlyRate DECIMAL(18,2) NULL DEFAULT 0,
    EmploymentStatus NVARCHAR(50) NULL DEFAULT 'Active',
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

CREATE TABLE [RoomAssignment] (
    RoomAssignmentId INT IDENTITY(1,1) PRIMARY KEY,
    RoomId INT NOT NULL,
    ScheduleId INT NOT NULL,
    AssignedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (RoomId) REFERENCES [Room](RoomID),
    FOREIGN KEY (ScheduleId) REFERENCES [EmployeeSchedule](ScheduleID)
);

CREATE TABLE [LeaveRequest] (
    LeaveRequestId INT IDENTITY(1,1) PRIMARY KEY,
    AccountId INT NOT NULL,
    ScheduleId INT NOT NULL,
    Reason NVARCHAR(500) NOT NULL,
    Status VARCHAR(30) NOT NULL DEFAULT 'Pending',
    CreatedAt DATETIME NULL DEFAULT GETDATE(),
    ApprovedById INT NULL,
    FOREIGN KEY (AccountId) REFERENCES [Account](AccountID),
    FOREIGN KEY (ScheduleId) REFERENCES [EmployeeSchedule](ScheduleID),
    FOREIGN KEY (ApprovedById) REFERENCES [Account](AccountID)
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
    InvoiceID INT NOT NULL,
    CustomerID INT NOT NULL,
    StaffID INT NULL,
    Rating INT NOT NULL,
    Comment NVARCHAR(500) NULL,
    CreatedAt DATETIME NULL DEFAULT GETDATE(),
    FOREIGN KEY (InvoiceID) REFERENCES [Invoice](InvoiceID),
    FOREIGN KEY (CustomerID) REFERENCES [Customer](CustomerID),
    FOREIGN KEY (StaffID) REFERENCES [Account](AccountID)
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
INSERT INTO [Role] (RoleID, RoleName) VALUES (6, N'Customer');
INSERT INTO [Role] (RoleID, RoleName) VALUES (7, N'Service Staff');
INSERT INTO [Role] (RoleID, RoleName) VALUES (8, N'Admin');
INSERT INTO [Role] (RoleID, RoleName) VALUES (9, N'Manager');
INSERT INTO [Role] (RoleID, RoleName) VALUES (10, N'Receptionist');
SET IDENTITY_INSERT [Role] OFF;

SET IDENTITY_INSERT [MembershipTier] ON;
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (1, N'Khách Mới', 0.00, 0);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (2, N'Đồng', 5.00, 1000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (3, N'Bạc', 10.00, 3000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (4, N'V�ng', 15.00, 7000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (5, N'Kim Cương', 20.00, 15000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (6, N'Khách Mới', 0.00, 0);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (7, N'Đồng', 5.00, 1000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (8, N'Bạc', 10.00, 3000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (9, N'V�ng', 15.00, 7000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (10, N'Kim Cương', 20.00, 15000);
SET IDENTITY_INSERT [MembershipTier] OFF;

SET IDENTITY_INSERT [RoomType] ON;
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (1, N'Phòng Thường', 150000.00, N'Sức chứa 5-8 người', N'/images/rooms/standard.jpg', 5);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (2, N'Ph�ng VIP', 300000.00, N'Sức chứa 10-15 người', N'/images/rooms/vip.jpg', 15);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (3, N'Ph�ng Party', 600000.00, N'Sức chứa 30 người', N'/images/rooms/party.jpg', 30);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (4, N'Ph�ng Couple', 120000.00, N'Sức chứa 2-4 người', NULL, 10);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (5, N'Phòng Thường', 150000.00, N'Sức chứa 5-8 người', NULL, 10);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (6, N'Ph�ng VIP', 300000.00, N'Sức chứa 10-15 người', NULL, 10);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (7, N'Ph�ng Super VIP (Party)', 600000.00, N'Sức chứa 30 người', NULL, 10);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (8, N'Ph�ng Couple', 120000.00, N'Sức chứa 2-4 người', NULL, 10);
SET IDENTITY_INSERT [RoomType] OFF;

SET IDENTITY_INSERT [Category] ON;
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (1, N'Đồ Uống');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (2, N'Đồ Ăn');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (3, N'Tr�i C�y');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (4, N'Đồ Ăn');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (5, N'Tr�i C�y');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (6, N'Combo');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (7, N'Bia');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (8, N'Rượu');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (9, N'Nước Khát');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (10, N'Đồ Ăn');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (11, N'Tr�i C�y');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (12, N'Combo');
SET IDENTITY_INSERT [Category] OFF;

SET IDENTITY_INSERT [Supplier] ON;
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (1, N'Bia Nước Ngọt Thành Phát', N'Anh Th�nh', N'0901111222', N'Q10');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (2, N'Rượu Ngoại Sài Gòn', N'Chị Hương', N'0903333444', N'Q1');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (3, N'Bia Nước Ngọt Thành Phát', N'Anh Th�nh', N'0901111222', N'Q10');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (4, N'Rượu Ngoại Sài Gòn', N'Chị Hương', N'0903333444', N'Q1');
SET IDENTITY_INSERT [Supplier] OFF;

SET IDENTITY_INSERT [Promotion] ON;
INSERT INTO [Promotion] (PromotionID, PromoCode, PromoName, DiscountPercent, MaxDiscountAmount, StartDate, EndDate) VALUES (1, N'NEWYEAR', N'Giảm 20%', 20.00, 500000.00, '2024-01-01 00:00:00', '2024-01-31 00:00:00');
INSERT INTO [Promotion] (PromotionID, PromoCode, PromoName, DiscountPercent, MaxDiscountAmount, StartDate, EndDate) VALUES (2, N'NOPROMO', N'Kh�ng KM', 0.00, 0.00, '2000-01-01 00:00:00', '2099-12-31 00:00:00');
SET IDENTITY_INSERT [Promotion] OFF;

SET IDENTITY_INSERT [PaymentMethod] ON;
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (1, N'Tiền mặt');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (2, N'VNPay');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (3, N'Visa');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (4, N'Momo');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (5, N'Tiền mặt');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (6, N'VNPay');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (7, N'Visa');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (8, N'Momo');
SET IDENTITY_INSERT [PaymentMethod] OFF;

SET IDENTITY_INSERT [WorkShift] ON;
INSERT INTO [WorkShift] (ShiftID, ShiftName, StartTime, EndTime) VALUES (1, N'Ca S�ng', '08:00:00', '16:00:00');
INSERT INTO [WorkShift] (ShiftID, ShiftName, StartTime, EndTime) VALUES (2, N'Ca Chiều', '16:00:00', '00:00:00');
INSERT INTO [WorkShift] (ShiftID, ShiftName, StartTime, EndTime) VALUES (3, N'Ca Khuya', '00:00:00', '08:00:00');
SET IDENTITY_INSERT [WorkShift] OFF;

SET IDENTITY_INSERT [Holiday] ON;
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (1, N'Tết Dương Lịch 2026', '2026-01-01 00:00:00', 20.00, NULL);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (2, N'Tết Nguyên Đán 2026 (Giao Thừa)', '2026-02-16 00:00:00', 200.00, NULL);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (3, N'Tết Nguyên Đán 2026 (Mùng 1)', '2026-02-17 00:00:00', 200.00, NULL);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (4, N'Tết Nguyên Đán 2026 (Mùng 2)', '2026-02-18 00:00:00', 150.00, NULL);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (5, N'Tết Nguyên Đán 2026 (Mùng 3)', '2026-02-19 00:00:00', 100.00, NULL);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (6, N'Giỗ Tổ Hùng Vương 2026', '2026-04-26 00:00:00', 30.00, NULL);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (7, N'Ngày Giải Phóng Miền Nam', '2026-04-30 00:00:00', 50.00, NULL);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (8, N'Quốc Tế Lao Động', '2026-05-01 00:00:00', 50.00, NULL);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (9, N'Quốc Khánh', '2026-09-02 00:00:00', 40.00, NULL);
SET IDENTITY_INSERT [Holiday] OFF;

SET IDENTITY_INSERT [PricingPolicy] ON;
INSERT INTO [PricingPolicy] (PolicyID, PolicyName, PolicyType, Value, IsActive) VALUES (1, N'Phụ thu Cuối tuần (T7 & CN)', N'Weekend', 15.00, NULL);
INSERT INTO [PricingPolicy] (PolicyID, PolicyName, PolicyType, Value, IsActive) VALUES (2, N'Phụ thu Ngày lễ chung', N'Holiday', 30.00, NULL);
SET IDENTITY_INSERT [PricingPolicy] OFF;

SET IDENTITY_INSERT [CustomerAutomationRule] ON;
INSERT INTO [CustomerAutomationRule] (RuleID, RuleName, EventType, ActionPayload, IsActive) VALUES (1, N'Tự động lên hạng', N'OnPointsEarned', N'{"Threshold": 1000, "NewTier": 2}', NULL);
INSERT INTO [CustomerAutomationRule] (RuleID, RuleName, EventType, ActionPayload, IsActive) VALUES (2, N'Chúc mừng sinh nhật', N'OnBirthday', N'{"TemplateID": 1, "Discount": 20}', NULL);
SET IDENTITY_INSERT [CustomerAutomationRule] OFF;

SET IDENTITY_INSERT [Account] ON;
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, ResetPasswordToken, ResetPasswordTokenExpiry) VALUES (1, 1, N'admin_tong', N'hash1', N'Nguyễn Quản Trị', N'0900000001', N'admin@karaoke.com', '2026-06-27 21:58:47', NULL, NULL, NULL);
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, ResetPasswordToken, ResetPasswordTokenExpiry) VALUES (2, 2, N'quanly_hung', N'$2a$11$CjOg29A9Gm7.e/1W67beVOUlQOqmQpos88YYtFi7p3RhTwAFRrXy6', N'Trần Hùng (Quản Lý)', N'0900000002', N'hung@karaoke.com', '2026-06-27 21:58:47', NULL, NULL, NULL);
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, ResetPasswordToken, ResetPasswordTokenExpiry) VALUES (3, 3, N'letan_lan', N'hash3', N'Lê Thị Lan', N'0900000003', N'lan@karaoke.com', '2026-06-27 21:58:47', 1, NULL, NULL);
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, ResetPasswordToken, ResetPasswordTokenExpiry) VALUES (4, 3, N'letan_mai', N'hash4', N'Phạm Mai', N'0900000004', N'mai@karaoke.com', '2026-06-27 21:58:47', 2, NULL, NULL);
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, ResetPasswordToken, ResetPasswordTokenExpiry) VALUES (9, 3, N'servicestaff_c', N'123456', N'Ho�ng Anh Em', N'0922334455', N'hoanganhe@gmail.com', '2026-07-21 16:03:17', 3, NULL, NULL);
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, ResetPasswordToken, ResetPasswordTokenExpiry) VALUES (11, 7, N'service1', N'$2a$11$HVndyctqKCNvh4i.ViA3K.BL3A1LGNTOT9x4NK5gP7GPodRnUHUsi', N'Nguyễn Phục Vụ 1', N'0912345601', N'service1@karaoke.com', '2026-07-22 15:47:51', 1, NULL, NULL);
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, ResetPasswordToken, ResetPasswordTokenExpiry) VALUES (12, 7, N'service2', N'$2a$11$V3ktyWiSuJelX/m6bTDLVOT5q1kcy4lNE3UE3vlnd9zP8hXbtDU2C', N'Trần Phục Vụ 2', N'0912345602', N'service2@karaoke.com', '2026-07-22 15:47:51', 2, NULL, NULL);
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, ResetPasswordToken, ResetPasswordTokenExpiry) VALUES (13, 7, N'service3', N'$2a$11$XejQsKYIfIpXWWCnydOAEuklMK5pCDt6ZeXUEYQ63/UDhdAxCvE/S', N'Lê Phục Vụ 3', N'0912345603', N'service3@karaoke.com', '2026-07-22 15:47:51', 3, NULL, NULL);
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, ResetPasswordToken, ResetPasswordTokenExpiry) VALUES (14, 7, N'service4', N'hash1', N'Phạm Phục Vụ 4', N'0912345604', N'service4@karaoke.com', '2026-07-22 15:47:51', 1, NULL, NULL);
SET IDENTITY_INSERT [Account] OFF;

SET IDENTITY_INSERT [Customer] ON;
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (1, 5, N'Lê Minh Tuấn (VIP)', N'0911111111', N'tuanvip@gmail.com', 16500, '2026-06-27 21:58:47');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (2, 4, N'Nguyễn Việt Hoàng', N'0922222222', N'hoangnv@gmail.com', 8200, '2026-06-27 21:58:47');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (3, 3, N'Trần Tiến Dũng', N'0933333333', N'dungtt@gmail.com', 3500, '2026-06-27 21:58:47');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (4, 2, N'Phạm Thu Thủy', N'0944444444', N'thuypham@gmail.com', 1200, '2026-06-27 21:58:47');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (5, 1, N'Đinh Thanh Hà', N'0955555555', N'hadinh@gmail.com', 150, '2026-06-27 21:58:47');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (6, 1, N'Kh�ch V�ng Lai', N'0000000000', NULL, 0, '2026-06-27 21:58:47');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (7, 5, N'Lê Minh Tuấn (VIP)', N'0911111111', N'tuanvip@gmail.com', 16500, '2026-07-22 19:45:15');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (8, 4, N'Nguyễn Việt Hoàng', N'0922222222', N'hoangnv@gmail.com', 8200, '2026-07-22 19:45:15');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (9, 3, N'Trần Tiến Dũng', N'0933333333', N'dungtt@gmail.com', 3500, '2026-07-22 19:45:15');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (10, 2, N'Phạm Thu Thủy', N'0944444444', N'thuypham@gmail.com', 1200, '2026-07-22 19:45:15');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (11, 1, N'Đinh Thanh Hà', N'0955555555', N'hadinh@gmail.com', 150, '2026-07-22 19:45:15');
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, LoyaltyPoints, CreatedAt) VALUES (12, 1, N'Kh�ch V�ng Lai', N'0000000000', NULL, 0, '2026-07-22 19:45:15');
SET IDENTITY_INSERT [Customer] OFF;

SET IDENTITY_INSERT [Room] ON;
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (1, 1, N'Tầng 1 - 101', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (2, 1, N'Tầng 1 - 102', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (3, 1, N'Tầng 1 - 103', N'Maintenance');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (4, 4, N'Tầng 1 - 104 (Couple)', N'InUse');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (5, 2, N'Tầng 2 - 201 (VIP)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (6, 2, N'Tầng 2 - 202 (VIP)', N'InUse');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (7, 2, N'Tầng 2 - 203 (VIP)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (8, 3, N'Tầng 3 - 301 (Party)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (9, 3, N'Tầng 3 - 302 (Party)', N'InUse');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (10, 1, N'Tầng 4 - 401', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (11, 1, N'Tầng 1 - 101', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (12, 1, N'Tầng 1 - 102', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (13, 1, N'Tầng 1 - 103', N'Maintenance');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (14, 4, N'Tầng 1 - 104 (Couple)', N'InUse');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (15, 2, N'Tầng 2 - 201 (VIP)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (16, 2, N'Tầng 2 - 202 (VIP)', N'InUse');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (17, 2, N'Tầng 2 - 203 (VIP)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (18, 3, N'Tầng 3 - 301 (Party)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (19, 3, N'Tầng 3 - 302 (Party)', N'InUse');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (20, 1, N'Tầng 4 - 401', N'Available');
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
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (2, 5, 2, N'M�y k�u to', 500000.00, '2026-06-26 21:58:47');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (3, 3, 3, N'Rớt móp đầu mic', 150000.00, '2026-07-17 19:45:15');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (4, 5, 2, N'M�y k�u to', 500000.00, '2026-07-21 19:45:15');
SET IDENTITY_INSERT [MaintenanceLog] OFF;

SET IDENTITY_INSERT [ServiceItem] ON;
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (1, 1, N'Heineken', 40000.00, N'Lon', 500);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (2, 1, N'Tiger', 30000.00, N'Lon', 800);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (3, 2, N'Chivas 12', 1500000.00, N'Chai', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (4, 3, N'Aquafina', 20000.00, N'Chai', 400);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (5, 4, N'Kh� B�', 150000.00, N'Đĩa', 50);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (6, 5, N'Tr�i C�y VIP', 350000.00, N'Đĩa', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (7, 6, N'Combo Sinh Nhật', 1500000.00, N'Combo', 5);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (8, 4, N'Đào Tiên ', 3000000.00, N'EM', 5);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (9, 5, N'G� 45kg', 150000.00, N'Con', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (10, 6, N'2 tay �m 2 em ', 50000000.00, N'combo', 15);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (11, 1, N'Heineken', 40000.00, N'Lon', 500);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (12, 1, N'Tiger', 30000.00, N'Lon', 800);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (13, 2, N'Chivas 12', 1500000.00, N'Chai', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (14, 3, N'Aquafina', 20000.00, N'Chai', 400);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (15, 4, N'Kh� B�', 150000.00, N'Đĩa', 50);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (16, 5, N'Tr�i C�y VIP', 350000.00, N'Đĩa', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ServiceName, SellingPrice, Unit, StockQuantity) VALUES (17, 6, N'Combo Sinh Nhật', 1500000.00, N'Combo', 5);
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
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (5, 4, 9, 12.00, 20);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (6, 5, 10, 1000000.00, 15);
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
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (1, 1, 3, 5, '2026-06-24 21:58:47', '2026-06-25 21:58:47', '2026-06-26 01:58:47', N'Completed', 4, N'Khách gọi đặt trước');
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (2, 2, 4, 8, '2026-06-26 21:58:47', '2026-06-26 21:58:47', '2026-06-27 00:58:47', N'Completed', 10, N'Sinh nhật');
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (3, 3, 3, 4, '2026-06-27 21:58:47', '2026-06-27 21:58:47', '2026-06-27 23:58:47', N'CheckedIn', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (4, 1, 3, 1, '2026-06-12 21:58:47', '2026-06-13 21:58:47', '2026-06-13 23:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (5, 2, 3, 2, '2026-06-13 21:58:47', '2026-06-14 21:58:47', '2026-06-15 00:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (6, 3, 4, 4, '2026-06-14 21:58:47', '2026-06-15 21:58:47', '2026-06-15 23:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (7, 4, 4, 5, '2026-06-15 21:58:47', '2026-06-16 21:58:47', '2026-06-17 01:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (8, 5, 3, 6, '2026-06-16 21:58:47', '2026-06-17 21:58:47', '2026-06-18 02:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (9, 1, 3, 7, '2026-06-17 21:58:47', '2026-06-18 21:58:47', '2026-06-18 23:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (10, 2, 4, 8, '2026-06-18 21:58:47', '2026-06-19 21:58:47', '2026-06-20 00:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (11, 3, 4, 9, '2026-06-19 21:58:47', '2026-06-20 21:58:47', '2026-06-21 01:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (12, 4, 3, 10, '2026-06-20 21:58:47', '2026-06-21 21:58:47', '2026-06-21 23:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (13, 5, 3, 1, '2026-06-21 21:58:47', '2026-06-22 21:58:47', '2026-06-23 00:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (14, 1, 4, 2, '2026-06-22 21:58:47', '2026-06-23 21:58:47', '2026-06-23 23:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (15, 2, 4, 5, '2026-06-23 21:58:47', '2026-06-24 21:58:47', '2026-06-25 01:58:47', N'Completed', NULL, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (16, 1, 3, 5, '2026-07-19 19:45:15', '2026-07-20 19:45:15', '2026-07-20 23:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (17, 2, 4, 8, '2026-07-21 19:45:15', '2026-07-21 19:45:15', '2026-07-21 22:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (18, 3, 3, 4, '2026-07-22 19:45:15', '2026-07-22 19:45:15', '2026-07-22 21:45:15', N'CheckedIn', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (19, 1, 3, 1, '2026-07-07 19:45:15', '2026-07-08 19:45:15', '2026-07-08 21:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (20, 2, 3, 2, '2026-07-08 19:45:15', '2026-07-09 19:45:15', '2026-07-09 22:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (21, 3, 4, 4, '2026-07-09 19:45:15', '2026-07-10 19:45:15', '2026-07-10 21:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (22, 4, 4, 5, '2026-07-10 19:45:15', '2026-07-11 19:45:15', '2026-07-11 23:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (23, 5, 3, 6, '2026-07-11 19:45:15', '2026-07-12 19:45:15', '2026-07-13 00:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (24, 1, 3, 7, '2026-07-12 19:45:15', '2026-07-13 19:45:15', '2026-07-13 21:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (25, 2, 4, 8, '2026-07-13 19:45:15', '2026-07-14 19:45:15', '2026-07-14 22:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (26, 3, 4, 9, '2026-07-14 19:45:15', '2026-07-15 19:45:15', '2026-07-15 23:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (27, 4, 3, 10, '2026-07-15 19:45:15', '2026-07-16 19:45:15', '2026-07-16 21:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (28, 5, 3, 1, '2026-07-16 19:45:15', '2026-07-17 19:45:15', '2026-07-17 22:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (29, 1, 4, 2, '2026-07-17 19:45:15', '2026-07-18 19:45:15', '2026-07-18 21:45:15', N'Completed', 1, NULL);
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, GuestCount, Note) VALUES (30, 2, 4, 5, '2026-07-18 19:45:15', '2026-07-19 19:45:15', '2026-07-19 23:45:15', N'Completed', 1, NULL);
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
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (16, NULL, 6, 1, NULL, '2026-06-28 06:58:21', NULL, 0.00, 0.00, 0.00, 0.00, N'Unpaid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (17, 1, 5, 3, 2, '2026-07-20 19:45:15', '2026-07-20 23:45:15', 1200000.00, 2750000.00, 790000.00, 3160000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (18, 2, 8, 3, 1, '2026-07-21 19:45:15', '2026-07-21 22:45:15', 1800000.00, 1500000.00, 500000.00, 2800000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (19, 3, 4, 4, 2, '2026-07-22 19:45:15', NULL, 0.00, 0.00, 0.00, 0.00, N'Unpaid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (20, 4, 1, 3, 2, '2026-07-08 19:45:15', '2026-07-08 21:45:15', 300000.00, 140000.00, 0.00, 440000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (21, 5, 2, 3, 2, '2026-07-09 19:45:15', '2026-07-09 22:45:15', 450000.00, 80000.00, 0.00, 530000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (22, 6, 4, 4, 2, '2026-07-10 19:45:15', '2026-07-10 21:45:15', 240000.00, 190000.00, 0.00, 430000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (23, 7, 5, 4, 2, '2026-07-11 19:45:15', '2026-07-11 23:45:15', 1200000.00, 490000.00, 0.00, 1690000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (24, 8, 6, 3, 2, '2026-07-12 19:45:15', '2026-07-13 00:45:15', 1500000.00, 700000.00, 150000.00, 2050000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (25, 9, 7, 3, 2, '2026-07-13 19:45:15', '2026-07-13 21:45:15', 600000.00, 300000.00, 90000.00, 810000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (26, 10, 8, 4, 2, '2026-07-14 19:45:15', '2026-07-14 22:45:15', 1800000.00, 1500000.00, 330000.00, 2970000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (27, 11, 9, 4, 2, '2026-07-15 19:45:15', '2026-07-15 23:45:15', 2400000.00, 1500000.00, 390000.00, 3510000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (28, 12, 10, 3, 2, '2026-07-16 19:45:15', '2026-07-16 21:45:15', 300000.00, 100000.00, 0.00, 400000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (29, 13, 1, 3, 2, '2026-07-17 19:45:15', '2026-07-17 22:45:15', 450000.00, 260000.00, 0.00, 710000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (30, 14, 2, 4, 2, '2026-07-18 19:45:15', '2026-07-18 21:45:15', 300000.00, 140000.00, 0.00, 440000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (31, 15, 5, 4, 2, '2026-07-19 19:45:15', '2026-07-19 23:45:15', 1200000.00, 600000.00, 180000.00, 1620000.00, N'Paid');
SET IDENTITY_INSERT [Invoice] OFF;

SET IDENTITY_INSERT [InvoiceDetail] ON;
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (1, 1, 3, 1, 1500000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (2, 1, 6, 2, 350000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (3, 1, 5, 2, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (4, 2, 7, 1, 1500000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (5, 2, 2, 24, 30000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (6, 4, 1, 3, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (7, 4, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (8, 5, 2, 2, 30000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (9, 5, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (10, 6, 5, 1, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (11, 6, 1, 1, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (12, 7, 6, 1, 350000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (13, 7, 1, 3, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (14, 7, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (15, 8, 6, 2, 350000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (16, 9, 5, 2, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (17, 10, 7, 1, 1500000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (18, 11, 3, 1, 1500000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (19, 12, 1, 2, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (20, 12, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (21, 13, 5, 1, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (22, 13, 2, 3, 30000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (23, 13, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (24, 14, 1, 3, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (25, 14, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (26, 15, 6, 1, 350000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (27, 15, 5, 1, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (28, 15, 1, 2, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (29, 15, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (30, 1, 3, 1, 1500000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (31, 1, 6, 2, 350000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (32, 1, 5, 2, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (33, 2, 7, 1, 1500000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (34, 2, 2, 24, 30000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (35, 4, 1, 3, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (36, 4, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (37, 5, 2, 2, 30000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (38, 5, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (39, 6, 5, 1, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (40, 6, 1, 1, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (41, 7, 6, 1, 350000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (42, 7, 1, 3, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (43, 7, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (44, 8, 6, 2, 350000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (45, 9, 5, 2, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (46, 10, 7, 1, 1500000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (47, 11, 3, 1, 1500000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (48, 12, 1, 2, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (49, 12, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (50, 13, 5, 1, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (51, 13, 2, 3, 30000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (52, 13, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (53, 14, 1, 3, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (54, 14, 4, 1, 20000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (55, 15, 6, 1, 350000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (56, 15, 5, 1, 150000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (57, 15, 1, 2, 40000.00);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice) VALUES (58, 15, 4, 1, 20000.00);
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

SET IDENTITY_INSERT [Expense] ON;
INSERT INTO [Expense] (ExpenseID, Category, ExpenseDate, Amount, Note, CreatedAt) VALUES (1, N'dien', '2023-10-15 00:00:00', 5400000.00, N'Tiền điện tháng 9/2023', '2026-06-27 21:58:47');
INSERT INTO [Expense] (ExpenseID, Category, ExpenseDate, Amount, Note, CreatedAt) VALUES (2, N'baotri', '2023-10-14 00:00:00', 2100000.00, N'Sửa mic phòng VIP 1 & 2', '2026-06-27 21:58:47');
INSERT INTO [Expense] (ExpenseID, Category, ExpenseDate, Amount, Note, CreatedAt) VALUES (3, N'matbang', '2023-10-01 00:00:00', 25000000.00, N'Thuê mặt bằng tháng 10', '2026-06-27 21:58:47');
INSERT INTO [Expense] (ExpenseID, Category, ExpenseDate, Amount, Note, CreatedAt) VALUES (4, N'nuoc', '2023-09-28 00:00:00', 850000.00, N'Tiền nước T9', '2026-06-27 21:58:47');
INSERT INTO [Expense] (ExpenseID, Category, ExpenseDate, Amount, Note, CreatedAt) VALUES (5, N'khac', '2026-07-01 00:00:00', 1000.00, N'Tiền nợ', '2026-07-12 22:34:27');
INSERT INTO [Expense] (ExpenseID, Category, ExpenseDate, Amount, Note, CreatedAt) VALUES (6, N'dien', '2023-10-15 00:00:00', 5400000.00, N'Tiền điện tháng 9/2023', '2026-07-22 19:45:15');
INSERT INTO [Expense] (ExpenseID, Category, ExpenseDate, Amount, Note, CreatedAt) VALUES (7, N'baotri', '2023-10-14 00:00:00', 2100000.00, N'Sửa mic phòng VIP 1 & 2', '2026-07-22 19:45:15');
INSERT INTO [Expense] (ExpenseID, Category, ExpenseDate, Amount, Note, CreatedAt) VALUES (8, N'matbang', '2023-10-01 00:00:00', 25000000.00, N'Thuê mặt bằng tháng 10', '2026-07-22 19:45:15');
INSERT INTO [Expense] (ExpenseID, Category, ExpenseDate, Amount, Note, CreatedAt) VALUES (9, N'nuoc', '2023-09-28 00:00:00', 850000.00, N'Tiền nước T9', '2026-07-22 19:45:15');
SET IDENTITY_INSERT [Expense] OFF;

SET IDENTITY_INSERT [RoomTransferHistory] ON;
SET IDENTITY_INSERT [RoomTransferHistory] OFF;

SET IDENTITY_INSERT [EmployeeSchedule] ON;
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (1, 1, 1, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (2, 3, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (6, 3, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (7, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (8, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (9, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (10, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (11, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (12, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (13, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (14, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (15, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (16, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (17, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (18, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (19, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (20, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (21, 1, 1, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (22, 4, 2, '2026-07-20 00:00:00', N'Off', 0);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (23, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (24, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (25, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (26, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (27, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (28, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (29, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (30, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (31, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (32, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (33, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (34, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (35, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (36, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (37, 1, 2, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (38, 3, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (39, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (40, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (41, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (42, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (43, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (44, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (45, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (46, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (47, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (48, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (49, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (50, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (51, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (52, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (53, 1, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (55, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (56, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (57, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (58, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (59, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (60, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (61, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (62, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (63, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (64, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (65, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (66, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (67, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (68, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (69, 1, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (70, 3, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (71, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (72, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (73, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (74, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (75, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (76, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (77, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (78, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (79, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (80, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (81, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (82, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (83, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (84, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (85, 1, 1, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (86, 4, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (87, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (88, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (89, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (90, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (91, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (92, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (93, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (94, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (95, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (96, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (97, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (98, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (99, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (100, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (101, 1, 2, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (104, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (105, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (106, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (107, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (108, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (109, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (110, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (111, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (112, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (113, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (114, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (115, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (116, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (117, 1, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (118, 4, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (119, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (120, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (121, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (122, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (123, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (124, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (125, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (126, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (127, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (128, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (129, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (130, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (131, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (132, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (133, 1, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (134, 3, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (135, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (136, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (137, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (138, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (139, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (140, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (141, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (142, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (143, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (144, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (145, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (146, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (147, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (148, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (149, 1, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (150, 4, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (151, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (152, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (153, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (154, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (155, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (156, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (157, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (158, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (159, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (160, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (161, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (162, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (163, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (164, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (165, 1, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (166, 3, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (167, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (168, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (169, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (170, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (171, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (172, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (173, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (174, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (175, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (176, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (177, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (178, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (179, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (180, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (181, 1, 1, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (182, 4, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (183, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (184, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (185, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (186, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (187, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (188, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (189, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (190, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (191, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (192, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (193, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (194, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (195, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (196, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (197, 1, 2, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (198, 3, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (199, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (200, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (201, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (202, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (203, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (204, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (205, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (206, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (207, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (208, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (209, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (210, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (211, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (212, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (213, 1, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (214, 4, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (215, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (216, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (217, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (218, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (219, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (220, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (221, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (222, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (223, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (224, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (225, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (226, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (227, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (228, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (229, 1, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (230, 3, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (231, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (232, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (233, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (234, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (235, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (236, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (237, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (238, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (239, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (240, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (241, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (242, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (243, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (244, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (245, 1, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (246, 4, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (247, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (248, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (249, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (250, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (251, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (252, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (253, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (254, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (255, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (256, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (257, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (258, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (259, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (260, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (261, 1, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (262, 3, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (263, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (264, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (265, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (266, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (267, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (268, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (269, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (270, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (271, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (272, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (273, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (274, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (275, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (276, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (277, 1, 1, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (278, 4, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (279, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (280, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (281, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (282, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (283, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (284, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (285, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (286, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (287, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (288, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (289, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (290, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (291, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (292, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (293, 1, 2, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (294, 3, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (295, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (296, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (297, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (298, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (299, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (300, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (301, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (302, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (303, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (304, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (305, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (306, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (307, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (308, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (309, 1, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (314, 9, 3, '2026-07-20 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (317, 4, 2, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (325, 9, 3, '2026-07-22 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (326, 3, 1, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (329, 4, 2, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (332, 9, 3, '2026-07-23 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (337, 9, 3, '2026-07-24 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (338, 3, 1, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (341, 4, 2, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (344, 9, 3, '2026-07-25 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (349, 9, 3, '2026-07-26 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (350, 4, 1, '2026-07-21 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (351, 3, 1, '2026-07-27 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (352, 4, 2, '2026-07-27 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (353, 9, 3, '2026-07-27 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (354, 3, 1, '2026-07-28 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (355, 4, 2, '2026-07-28 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (356, 9, 3, '2026-07-28 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (357, 3, 1, '2026-07-29 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (358, 4, 2, '2026-07-29 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (359, 9, 3, '2026-07-29 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (360, 3, 1, '2026-07-30 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (361, 4, 2, '2026-07-30 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (362, 9, 3, '2026-07-30 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (363, 3, 1, '2026-07-31 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (364, 4, 2, '2026-07-31 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (365, 9, 3, '2026-07-31 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (366, 3, 1, '2026-08-01 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (367, 4, 2, '2026-08-01 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (368, 9, 3, '2026-08-01 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (369, 3, 1, '2026-08-02 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (370, 4, 2, '2026-08-02 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (371, 9, 3, '2026-08-02 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (372, 3, 1, '2026-08-03 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (373, 11, 1, '2026-08-03 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (374, 14, 1, '2026-08-03 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (375, 4, 2, '2026-08-03 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (376, 12, 2, '2026-08-03 00:00:00', N'Off', 0);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (377, 9, 3, '2026-08-03 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (378, 13, 3, '2026-08-03 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (379, 3, 1, '2026-08-04 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (380, 11, 1, '2026-08-04 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (381, 14, 1, '2026-08-04 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (382, 4, 2, '2026-08-04 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (383, 12, 2, '2026-08-04 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (384, 9, 3, '2026-08-04 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (385, 13, 3, '2026-08-04 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (386, 3, 1, '2026-08-05 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (387, 11, 1, '2026-08-05 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (388, 14, 1, '2026-08-05 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (389, 4, 2, '2026-08-05 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (390, 12, 2, '2026-08-05 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (391, 9, 3, '2026-08-05 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (392, 13, 3, '2026-08-05 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (393, 3, 1, '2026-08-06 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (394, 11, 1, '2026-08-06 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (395, 14, 1, '2026-08-06 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (396, 4, 2, '2026-08-06 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (397, 12, 2, '2026-08-06 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (398, 9, 3, '2026-08-06 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (399, 13, 3, '2026-08-06 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (400, 3, 1, '2026-08-07 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (401, 11, 1, '2026-08-07 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (402, 14, 1, '2026-08-07 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (403, 4, 2, '2026-08-07 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (404, 12, 2, '2026-08-07 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (405, 9, 3, '2026-08-07 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (406, 13, 3, '2026-08-07 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (407, 3, 1, '2026-08-08 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (408, 11, 1, '2026-08-08 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (409, 14, 1, '2026-08-08 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (410, 4, 2, '2026-08-08 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (411, 12, 2, '2026-08-08 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (412, 9, 3, '2026-08-08 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (413, 13, 3, '2026-08-08 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (414, 3, 1, '2026-08-09 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (415, 11, 1, '2026-08-09 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (416, 14, 1, '2026-08-09 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (417, 4, 2, '2026-08-09 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (418, 12, 2, '2026-08-09 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (419, 9, 3, '2026-08-09 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (420, 13, 3, '2026-08-09 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (421, 3, 1, '2026-08-10 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (422, 4, 2, '2026-08-10 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (423, 9, 3, '2026-08-10 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (424, 11, 1, '2026-08-10 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (425, 12, 2, '2026-08-10 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (426, 13, 3, '2026-08-10 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (427, 14, 1, '2026-08-10 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (428, 3, 1, '2026-08-11 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (429, 4, 2, '2026-08-11 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (430, 9, 3, '2026-08-11 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (431, 11, 1, '2026-08-11 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (432, 12, 2, '2026-08-11 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (433, 13, 3, '2026-08-11 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (434, 14, 1, '2026-08-11 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (435, 3, 1, '2026-08-12 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (436, 4, 2, '2026-08-12 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (437, 9, 3, '2026-08-12 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (438, 11, 1, '2026-08-12 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (439, 12, 2, '2026-08-12 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (440, 13, 3, '2026-08-12 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (441, 14, 1, '2026-08-12 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (442, 3, 1, '2026-08-13 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (443, 4, 2, '2026-08-13 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (444, 9, 3, '2026-08-13 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (445, 11, 1, '2026-08-13 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (446, 12, 2, '2026-08-13 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (447, 13, 3, '2026-08-13 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (448, 14, 1, '2026-08-13 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (449, 3, 1, '2026-08-14 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (450, 4, 2, '2026-08-14 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (451, 9, 3, '2026-08-14 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (452, 11, 1, '2026-08-14 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (453, 12, 2, '2026-08-14 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (454, 13, 3, '2026-08-14 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (455, 14, 1, '2026-08-14 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (456, 3, 1, '2026-08-15 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (457, 4, 2, '2026-08-15 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (458, 9, 3, '2026-08-15 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (459, 11, 1, '2026-08-15 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (460, 12, 2, '2026-08-15 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (461, 13, 3, '2026-08-15 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (462, 14, 1, '2026-08-15 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (463, 3, 1, '2026-08-16 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (464, 4, 2, '2026-08-16 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (465, 9, 3, '2026-08-16 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (466, 11, 1, '2026-08-16 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (467, 12, 2, '2026-08-16 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (468, 13, 3, '2026-08-16 00:00:00', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (469, 14, 1, '2026-08-16 00:00:00', N'Scheduled', 1);
SET IDENTITY_INSERT [EmployeeSchedule] OFF;

SET IDENTITY_INSERT [Attendance] ON;
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note) VALUES (1, 1, 1, '2026-07-21 08:00:00', '2026-07-21 16:00:00', 8.00, N'OnTime', N'Đi đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note) VALUES (2, 3, 2, '2026-07-21 16:00:00', NULL, NULL, N'OnTime', NULL);
SET IDENTITY_INSERT [Attendance] OFF;

SET IDENTITY_INSERT [Payroll] ON;
INSERT INTO [Payroll] (PayrollID, AccountID, PayPeriodMonth, PayPeriodYear, BaseSalary, BonusAmount, DeductionAmount, NetSalary, PaymentStatus, PaymentDate, Note) VALUES (1, 1, 7, 2026, 8000000.00, 500000.00, 0.00, 8500000.00, N'Paid', '2026-07-21 15:07:43', N'Lương tháng này');
INSERT INTO [Payroll] (PayrollID, AccountID, PayPeriodMonth, PayPeriodYear, BaseSalary, BonusAmount, DeductionAmount, NetSalary, PaymentStatus, PaymentDate, Note) VALUES (2, 3, 7, 2026, 6000000.00, 0.00, 200000.00, 5800000.00, N'Unpaid', NULL, N'Phạt đi muộn');
SET IDENTITY_INSERT [Payroll] OFF;

SET IDENTITY_INSERT [EmployeeProfile] ON;
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate, EmploymentStatus) VALUES (1, 1, N'001090123456', '1990-05-15 00:00:00', N'123 Đường A, Quận 1, TP.HCM', '2022-01-10 00:00:00', 35000.00, N'Active');
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate, EmploymentStatus) VALUES (2, 3, N'079095654321', '1995-10-20 00:00:00', N'456 Đường B, Quận 3, TP.HCM', '2023-03-01 00:00:00', 30000.00, N'Active');
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate, EmploymentStatus) VALUES (7, 9, N'052094556677', '1997-01-30 00:00:00', N'12 Cần Thơ, Ninh Kiều', '2023-05-12 00:00:00', 35000.00, N'Resigned');
SET IDENTITY_INSERT [EmployeeProfile] OFF;

SET IDENTITY_INSERT [TrainingRecord] ON;
INSERT INTO [TrainingRecord] (TrainingID, AccountID, CourseName, CompletionDate, Result) VALUES (1, 1, N'Kỹ năng PCCC', '2023-05-10 00:00:00', N'Passed');
INSERT INTO [TrainingRecord] (TrainingID, AccountID, CourseName, CompletionDate, Result) VALUES (2, 3, N'Kỹ năng Giao tiếp khách hàng', '2023-06-15 00:00:00', N'Passed');
SET IDENTITY_INSERT [TrainingRecord] OFF;

SET IDENTITY_INSERT [EmployeeTask] ON;
INSERT INTO [EmployeeTask] (TaskID, AssignedToID, CreatedByID, Title, Description, DueDate, Status) VALUES (1, 3, 1, N'Dọn dẹp phòng VIP 1', N'Lau chùi bàn ghế, kiểm tra micro', '2026-07-21 17:07:43', N'Pending');
INSERT INTO [EmployeeTask] (TaskID, AssignedToID, CreatedByID, Title, Description, DueDate, Status) VALUES (2, 4, 1, N'Kiểm kê kho bia', N'Đếm số lượng bia Tiger và Heineken', '2026-07-22 15:07:43', N'InProgress');
SET IDENTITY_INSERT [EmployeeTask] OFF;

SET IDENTITY_INSERT [RoomAssignment] ON;
SET IDENTITY_INSERT [RoomAssignment] OFF;

SET IDENTITY_INSERT [LeaveRequest] ON;
INSERT INTO [LeaveRequest] (LeaveRequestId, AccountId, ScheduleId, Reason, Status, CreatedAt, ApprovedById) VALUES (1, 4, 22, N'Nghỉ phép', N'Approved', '2026-07-21 15:54:07', 2);
INSERT INTO [LeaveRequest] (LeaveRequestId, AccountId, ScheduleId, Reason, Status, CreatedAt, ApprovedById) VALUES (2, 12, 376, N'Việc riêng', N'Approved', '2026-07-22 16:43:38', 2);
SET IDENTITY_INSERT [LeaveRequest] OFF;

SET IDENTITY_INSERT [ShiftSwapRequest] ON;
INSERT INTO [ShiftSwapRequest] (SwapRequestId, RequesterId, RequesterScheduleId, TargetId, TargetScheduleId, Status, CreatedAt, ApprovedById) VALUES (1, 1, 7, 1, 7, N'Consented', '2026-07-21 15:53:06', NULL);
INSERT INTO [ShiftSwapRequest] (SwapRequestId, RequesterId, RequesterScheduleId, TargetId, TargetScheduleId, Status, CreatedAt, ApprovedById) VALUES (2, 12, 383, 13, 385, N'Pending', '2026-07-22 16:55:21', NULL);
SET IDENTITY_INSERT [ShiftSwapRequest] OFF;

SET IDENTITY_INSERT [NotificationLog] ON;
INSERT INTO [NotificationLog] (NotificationID, BookingID, CustomerID, Channel, Recipient, MessageContent, SentStatus, SentAt) VALUES (1, 1, 1, N'SMS', N'0901234567', N'Cảm ơn quý khách đã đặt phòng tại Karaoke Management. Mã đặt phòng: #1', N'Sent', '2026-07-21 15:07:43');
INSERT INTO [NotificationLog] (NotificationID, BookingID, CustomerID, Channel, Recipient, MessageContent, SentStatus, SentAt) VALUES (2, 2, 2, N'Email', N'khachhang2@gmail.com', N'Phòng VIP 2 của quý khách đã sẵn sàng lúc 19:00', N'Sent', '2026-07-21 15:07:43');
SET IDENTITY_INSERT [NotificationLog] OFF;

SET IDENTITY_INSERT [CustomerReview] ON;
INSERT INTO [CustomerReview] (ReviewID, InvoiceID, CustomerID, StaffID, Rating, Comment, CreatedAt) VALUES (1, 1, 1, 3, 5, N'Phòng đẹp, âm thanh hay, phục vụ tốt', '2026-07-21 15:07:43');
INSERT INTO [CustomerReview] (ReviewID, InvoiceID, CustomerID, StaffID, Rating, Comment, CreatedAt) VALUES (2, 2, 2, 4, 4, N'Mồi ngon, nhưng gọi bia hơi chậm', '2026-07-21 15:07:43');
SET IDENTITY_INSERT [CustomerReview] OFF;

SET IDENTITY_INSERT [MarketingCampaign] ON;
INSERT INTO [MarketingCampaign] (CampaignID, PromotionID, CampaignName, Channel, TargetTierID, MessageTemplate, StartDate, Status) VALUES (1, NULL, N'Chúc mừng sinh nhật VIP', N'SMS', 3, N'Chúc mừng sinh nhật! Tặng bạn voucher giảm 20%', '2026-07-21 15:07:43', N'Active');
INSERT INTO [MarketingCampaign] (CampaignID, PromotionID, CampaignName, Channel, TargetTierID, MessageTemplate, StartDate, Status) VALUES (2, NULL, N'Khuyến mãi Hè sôi động', N'Email', 2, N'Giảm 10% tiền phòng cho khách hàng Gold', '2026-07-26 15:07:43', N'Draft');
SET IDENTITY_INSERT [MarketingCampaign] OFF;

SET IDENTITY_INSERT [CustomerCareLog] ON;
INSERT INTO [CustomerCareLog] (LogID, CustomerID, AccountID, InteractionType, Notes, LoggedDate) VALUES (1, 1, 1, N'Gọi điện thoại', N'Hỏi thăm sự hài lòng về dịch vụ sinh nhật tối qua', '2026-07-21 15:07:43');
INSERT INTO [CustomerCareLog] (LogID, CustomerID, AccountID, InteractionType, Notes, LoggedDate) VALUES (2, 2, 3, N'Nhắn tin', N'Gửi thông báo chương trình khuyến mãi', '2026-07-21 15:07:43');
SET IDENTITY_INSERT [CustomerCareLog] OFF;

-- Re-enable all constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all';
