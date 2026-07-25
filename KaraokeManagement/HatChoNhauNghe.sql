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

CREATE TABLE [CancellationReason] (
    CancellationReasonID INT IDENTITY(1,1) PRIMARY KEY,
    Code VARCHAR(50) NOT NULL UNIQUE,
    ReasonName NVARCHAR(200) NOT NULL,
    AppliesTo VARCHAR(20) NOT NULL DEFAULT 'Both',
    RequiresDetail BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    SortOrder INT NOT NULL DEFAULT 0,
    CONSTRAINT CK_CancellationReason_AppliesTo
        CHECK (AppliesTo IN ('Customer', 'Receptionist', 'Both'))
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
    CancellationReasonID INT NULL,
    CancellationReasonDetail NVARCHAR(500) NULL,
    CancelledAt DATETIME2 NULL,
    CancelledByType VARCHAR(20) NULL,
    CancelledByAccountID INT NULL,
    CancelledByCustomerID INT NULL,
    FOREIGN KEY (CustomerID) REFERENCES [Customer](CustomerID),
	FOREIGN KEY (StaffId) REFERENCES [Account](AccountID),
    FOREIGN KEY (CreatedByID) REFERENCES [Account](AccountID),
    FOREIGN KEY (RoomID) REFERENCES [Room](RoomID),
    CONSTRAINT FK_Booking_CancellationReason FOREIGN KEY (CancellationReasonID) REFERENCES [CancellationReason](CancellationReasonID),
    CONSTRAINT FK_Booking_CancelledByAccount FOREIGN KEY (CancelledByAccountID) REFERENCES [Account](AccountID),
    CONSTRAINT FK_Booking_CancelledByCustomer FOREIGN KEY (CancelledByCustomerID) REFERENCES [Customer](CustomerID),
    CONSTRAINT CK_Booking_CancelledByType
        CHECK (CancelledByType IS NULL OR CancelledByType IN ('Customer', 'Receptionist'))
);

CREATE INDEX IX_Booking_Status_CancelledAt
ON [Booking] (Status, CancelledAt)
INCLUDE (CancellationReasonID, RoomID);

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


CREATE TABLE LoyalPointPolicy (
    PolicyId INT IDENTITY(1,1) PRIMARY KEY,
    AmountPerPoint DECIMAL(18, 2) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    Description NVARCHAR(255) NULL
);

CREATE UNIQUE INDEX UX_LoyalPointPolicy_OneActive
ON LoyalPointPolicy(IsActive)
WHERE IsActive = 1;

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

-- 9.1 ROLE
SET IDENTITY_INSERT [Role] ON;
INSERT INTO [Role] (RoleID, RoleName) VALUES (1, N'Admin');
INSERT INTO [Role] (RoleID, RoleName) VALUES (2, N'Manager');
INSERT INTO [Role] (RoleID, RoleName) VALUES (3, N'Receptionist');
INSERT INTO [Role] (RoleID, RoleName) VALUES (4, N'Service Staff');
SET IDENTITY_INSERT [Role] OFF;

-- 9.2 CANCELLATION REASON
INSERT INTO [CancellationReason] (Code, ReasonName, AppliesTo, RequiresDetail, IsActive, SortOrder)
VALUES
('CUSTOMER_CHANGED_PLAN', N'Thay đổi kế hoạch', 'Customer', 0, 1, 10),
('CUSTOMER_WRONG_BOOKING', N'Đặt nhầm phòng hoặc thời gian', 'Customer', 0, 1, 20),
('CUSTOMER_COST', N'Chi phí không phù hợp', 'Customer', 0, 1, 30),
('CUSTOMER_NO_NEED', N'Không còn nhu cầu', 'Customer', 0, 1, 40),
('RECEPTIONIST_CUSTOMER_REQUEST', N'Khách hàng yêu cầu hủy', 'Receptionist', 0, 1, 50),
('RECEPTIONIST_ROOM_ISSUE', N'Phòng gặp sự cố hoặc bảo trì', 'Receptionist', 0, 1, 60),
('RECEPTIONIST_SCHEDULE_CONFLICT', N'Trùng lịch hoặc không thể phục vụ', 'Receptionist', 0, 1, 70),
('RECEPTIONIST_NO_SHOW', N'Khách không đến', 'Receptionist', 0, 1, 80),
('OTHER', N'Khác', 'Both', 1, 1, 999);

-- 9.2 WORK SHIFT
SET IDENTITY_INSERT [WorkShift] ON;
INSERT INTO [WorkShift] (ShiftID, ShiftName, StartTime, EndTime) VALUES (1, N'Ca Sáng', '08:00:00', '16:00:00');
INSERT INTO [WorkShift] (ShiftID, ShiftName, StartTime, EndTime) VALUES (2, N'Ca Chiều', '16:00:00', '00:00:00');
INSERT INTO [WorkShift] (ShiftID, ShiftName, StartTime, EndTime) VALUES (3, N'Ca Khuya', '00:00:00', '08:00:00');
SET IDENTITY_INSERT [WorkShift] OFF;

-- 9.3 ACCOUNT (Quản trị, Quản lý, Lễ tân, Phục vụ)
SET IDENTITY_INSERT [Account] ON;
INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (1, 1, 'admin_tong', '123456', N'Nguyễn Quản Trị', '0900000001', 'admin@karaoke.com', '2026-06-01 08:00:00', 1, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (2, 2, 'quanly_hung', '123456', N'Trần Hùng (Quản Lý)', '0900000002', 'hung@karaoke.com', '2026-06-01 08:00:00', 1, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (3, 3, 'letan_lan', '123456', N'Lê Thị Lan', '0900000003', 'lan@karaoke.com', '2026-06-01 08:00:00', 1, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (4, 3, 'letan_mai', '123456', N'Phạm Mai', '0900000004', 'mai@karaoke.com', '2026-06-01 08:00:00', 2, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (5, 2, 'quanly_minh', '123456', N'Nguyễn Văn Minh', '0900000005', 'minh@karaoke.com', '2026-06-01 08:00:00', 2, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (9, 3, 'letan_hoa', '123456', N'Lê Thị Hoa', '0900000009', 'hoa@karaoke.com', '2026-06-01 08:00:00', 3, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (10, 3, 'letan_tuan', '123456', N'Lê Tấn Tuấn', '0900000010', 'tuanlt@karaoke.com', '2026-06-01 08:00:00', 1, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (11, 4, 'service1', '123456', N'Nguyễn Phục Vụ 1', '0912345601', 'service1@karaoke.com', '2026-06-01 08:00:00', 1, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (12, 4, 'service2', '123456', N'Trần Phục Vụ 2', '0912345602', 'service2@karaoke.com', '2026-06-01 08:00:00', 2, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (13, 4, 'service3', '123456', N'Lê Phục Vụ 3', '0912345603', 'service3@karaoke.com', '2026-06-01 08:00:00', 3, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (14, 4, 'service4', '123456', N'Phạm Phục Vụ 4', '0912345604', 'service4@karaoke.com', '2026-06-01 08:00:00', 1, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (15, 4, 'service5', '123456', N'Đỗ Phục Vụ 5', '0912345605', 'service5@karaoke.com', '2026-06-01 08:00:00', 2, NULL, NULL, 1);

INSERT INTO [Account] (AccountID, RoleID, Username, PasswordHash, FullName, Phone, Email, CreatedAt, DefaultShiftID, OtpCode, OtpExpiry, IsActive) 
VALUES (16, 4, 'service6', '123456', N'Bùi Phục Vụ 6', '0912345606', 'service6@karaoke.com', '2026-06-01 08:00:00', 3, NULL, NULL, 1);
SET IDENTITY_INSERT [Account] OFF;

-- 9.4 EMPLOYEE PROFILE (Hồ sơ nhân viên)
SET IDENTITY_INSERT [EmployeeProfile] ON;
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (1, 1, '001090123456', '1990-05-15', N'123 Đường A, Quận 1, TP.HCM', '2022-01-10', 50000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (2, 2, '079095654321', '1992-08-20', N'456 Đường B, Quận 3, TP.HCM', '2022-03-01', 45000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (3, 3, '079095111222', '1996-03-10', N'789 Lê Văn Sỹ, Quận 3, TP.HCM', '2023-01-15', 35000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (4, 4, '079095333444', '1997-11-25', N'12 Nguyễn Trãi, Quận 5, TP.HCM', '2023-02-20', 35000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (5, 5, '079095555666', '1991-04-12', N'45 Điện Biên Phủ, Quận 1, TP.HCM', '2022-06-01', 45000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (6, 9, '079095777888', '1998-07-08', N'88 Cách Mạng Tháng 8, Quận 10, TP.HCM', '2023-05-10', 35000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (7, 10, '079095999000', '1995-12-05', N'102 Hoàng Văn Thụ, Q.Phú Nhuận, TP.HCM', '2023-06-15', 35000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (8, 11, '079096111222', '1999-01-18', N'15 Lý Thường Kiệt, Quận 10, TP.HCM', '2023-08-01', 30000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (9, 12, '079096333444', '2000-09-22', N'30 Phan Xích Long, Q.Phú Nhuận, TP.HCM', '2023-08-01', 30000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (10, 13, '079096555666', '1998-05-14', N'67 Trần Hưng Đạo, Quận 1, TP.HCM', '2023-09-01', 30000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (11, 14, '079096777888', '1997-03-30', N'99 Võ Thị Sáu, Quận 3, TP.HCM', '2023-09-15', 30000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (12, 15, '079096999000', '2001-06-11', N'204 Bùi Thị Xuân, Quận 1, TP.HCM', '2023-10-01', 30000.00);
INSERT INTO [EmployeeProfile] (ProfileID, AccountID, IdentityCardNumber, DateOfBirth, Address, HireDate, BaseHourlyRate) 
VALUES (13, 16, '079097111222', '2000-02-28', N'55 Nam Kỳ Khởi Nghĩa, Quận 1, TP.HCM', '2023-10-15', 30000.00);
SET IDENTITY_INSERT [EmployeeProfile] OFF;

-- 9.5 MEMBERSHIP TIER
SET IDENTITY_INSERT [MembershipTier] ON;
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (1, N'Khách Mới', 0.00, 0);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (2, N'Đồng', 5.00, 1000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (3, N'Bạc', 10.00, 3000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (4, N'Vàng', 15.00, 7000);
INSERT INTO [MembershipTier] (TierID, TierName, DiscountPercent, MinPoints) VALUES (5, N'Kim Cương', 20.00, 15000);
SET IDENTITY_INSERT [MembershipTier] OFF;

-- 9.6 LOYAL POINT POLICY
INSERT INTO LoyalPointPolicy (AmountPerPoint, IsActive, Description)
VALUES (10000.00, 1, N'Quy đổi 10,000 VNĐ = 1 điểm tích lũy');

-- 9.7 CUSTOMER (Danh sách khách hàng)
SET IDENTITY_INSERT [Customer] ON;
INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (1, 5, N'Lê Minh Tuấn (VIP)', '0911111111', 'tuanvip@gmail.com', '123456', 16500, '2026-06-01 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (2, 4, N'Nguyễn Việt Hoàng', '0922222222', 'hoangnv@gmail.com', '123456', 8200, '2026-06-01 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (3, 3, N'Trần Tiến Dũng', '0933333333', 'dungtt@gmail.com', '123456', 3500, '2026-06-01 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (4, 2, N'Phạm Thu Thủy', '0944444444', 'thuypham@gmail.com', '123456', 1200, '2026-06-01 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (5, 1, N'Đinh Thanh Hà', '0955555555', 'hadinh@gmail.com', '123456', 150, '2026-06-01 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (6, 1, N'Khách Vãng Lai', '0000000000', NULL, '123456', 0, '2026-06-01 10:00:00', NULL, NULL, 0);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (7, 5, N'Vũ Hoàng Anh', '0966666666', 'hoanganh@gmail.com', '123456', 18000, '2026-06-05 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (8, 4, N'Đặng Phương Thảo', '0977777777', 'thaodp@gmail.com', '123456', 9500, '2026-06-05 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (9, 3, N'Ngô Quốc Bảo', '0988888888', 'baonq@gmail.com', '123456', 4200, '2026-06-10 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (10, 2, N'Bùi Thị Mỹ Linh', '0999999999', 'mylinhbui@gmail.com', '123456', 1800, '2026-06-10 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (11, 1, N'Hoàng Trọng Nghĩa', '0901234567', 'nghiaht@gmail.com', '123456', 300, '2026-06-15 10:00:00', NULL, NULL, 1);

INSERT INTO [Customer] (CustomerID, TierID, FullName, Phone, Email, PasswordHash, LoyaltyPoints, CreatedAt, OtpCode, OtpExpiry, IsEmailVerified) 
VALUES (12, 1, N'Trịnh Ngọc Ánh', '0912345678', 'anhtn@gmail.com', '123456', 0, '2026-06-20 10:00:00', NULL, NULL, 1);
SET IDENTITY_INSERT [Customer] OFF;

-- 9.8 ROOM TYPE
SET IDENTITY_INSERT [RoomType] ON;
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (1, N'Phòng Thường', 150000.00, N'Sức chứa 5-8 người', 'https://noithatvieta.vn/upload/images/2021/tu-van-thiet-ke/phong-hat-binh-dan-03.jpg', 8);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (2, N'Phòng VIP', 300000.00, N'Sức chứa 10-15 người', 'https://www.vntrip.vn/cam-nang/wp-content/uploads/2020/03/top-quan-cafe-vip-nhat-ha-noi-1.jpg', 15);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (3, N'Phòng Party', 600000.00, N'Sức chứa 30 người', 'https://vietwave.com.vn/karaokebay/upload/files/sanpham/thiet_ke_phong_hat_dep_1024x576.jpg', 30);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (4, N'Phòng Couple', 120000.00, N'Sức chứa 2-4 người', 'https://noithatktv.vn/wp-content/uploads/2021/01/thiet-ke-phong-hat-karaoke-gia-dinh-1.jpg', 4);
INSERT INTO [RoomType] (RoomTypeID, TypeName, PricePerHour, Description, ImageURL, Capacity) VALUES (5, N'Phòng Super VIP (Party)', 600000.00, N'Sức chứa 30 người', 'https://noithatkaraoke.vn/upload/images/mau-phong-karaoke/phong-karaoke-2024/phong-karaoke-phong-cach-moi-nam-2024.jpg', 30);
SET IDENTITY_INSERT [RoomType] OFF;

-- 9.9 ROOM (Danh sách phòng)
SET IDENTITY_INSERT [Room] ON;
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (1, 1, N'Tầng 1 - 101', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (2, 2, N'Tầng 1 - 102', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (3, 3, N'Tầng 1 - 103', N'Maintenance');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (4, 4, N'Tầng 1 - 104 (Couple)', N'InUse');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (5, 1, N'Tầng 2 - 201', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (6, 2, N'Tầng 2 - 202 (VIP)', N'InUse');    
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (7, 3, N'Tầng 2 - 203 (Party)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (8, 4, N'Tầng 2 - 204 (Couple)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (9, 1, N'Tầng 3 - 301', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (10, 2, N'Tầng 3 - 302 (VIP)', N'InUse'); 
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (11, 3, N'Tầng 3 - 303 (Party)', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (12, 4, N'Tầng 3 - 304 (Couple)', N'InUse'); 
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (13, 1, N'Tầng 4 - 401', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (14, 2, N'Tầng 4 - 402', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (15, 4, N'Tầng 4 - 403', N'Available');
INSERT INTO [Room] (RoomID, RoomTypeID, RoomName, Status) VALUES (16, 5, N'Tầng 4 - 404 (Super VIP)', N'Available');
SET IDENTITY_INSERT [Room] OFF;

-- 9.10 ROOM IMAGE
SET IDENTITY_INSERT [RoomImage] ON;
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (1, 1, N'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (2, 1, N'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (3, 2, N'https://images.unsplash.com/photo-1566737236500-c8ac43014a67?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (4, 2, N'https://images.unsplash.com/photo-1497911270199-1c552ee64aa4?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (5, 2, N'https://images.unsplash.com/photo-1574096079513-d8259312b78a?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (6, 3, N'https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (7, 3, N'https://images.unsplash.com/photo-1470229722913-7c092db65f8c?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (8, 3, N'https://images.unsplash.com/photo-1545128485-c400e7702796?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (9, 4, N'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (10, 4, N'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (11, 5, N'https://images.unsplash.com/photo-1571115764595-644a1f56a55c?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (12, 5, N'https://images.unsplash.com/photo-1598387993281-cecf8b71a8f8?auto=format&fit=crop&q=80&w=1200');
INSERT INTO [RoomImage] (RoomImageId, RoomTypeId, ImageUrl) VALUES (13, 5, N'https://images.unsplash.com/photo-1563514755106-96db86a7f7da?auto=format&fit=crop&q=80&w=1200');
SET IDENTITY_INSERT [RoomImage] OFF;

-- 9.11 EQUIPMENT (Thiết bị phòng hát)
SET IDENTITY_INSERT [Equipment] ON;
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (1, 5, N'Tivi Samsung 65 Inch', 'SS-65-001', '2023-01-15', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (2, 5, N'Micro Shure KSM9', 'SH-001', '2023-01-15', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (3, 6, N'Micro Shure KSM9', 'SH-003', '2023-01-15', N'Broken');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (4, 8, N'Loa JBL PRX412M', 'JBL-001', '2023-05-20', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (5, 3, N'Điều hòa Panasonic 24000 BTU', 'PN-AC-001', '2022-10-10', N'Repairing');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (6, 1, N'Tivi Sony 55 Inch', 'SN-55-002', '2023-02-10', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (7, 1, N'Loa Bose 301 V', 'BS-301-001', '2023-02-10', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (8, 2, N'Amply Jagsam PA-506N', 'JG-506-001', '2023-03-01', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (9, 2, N'Micro Sennheiser EW100', 'SE-100-001', '2023-03-01', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (10, 4, N'Tivi LG 50 Inch', 'LG-50-001', '2023-04-15', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (11, 7, N'Đầu Chọn Bài VietKTV 4TB', 'VK-4TB-001', '2023-06-01', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (12, 7, N'Loa BMB CSN-500', 'BMB-500-001', '2023-06-01', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (13, 9, N'Máy Chiếu Optoma 4K', 'OP-4K-001', '2023-07-20', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (14, 10, N'Amply Crown XLi 2500', 'CR-2500-001', '2023-08-12', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (15, 11, N'Hệ Thống Đèn Laser Party', 'LS-PARTY-01', '2023-09-05', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (16, 12, N'Điều Hòa Daikin 18000 BTU', 'DK-180-001', '2023-09-20', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (17, 13, N'Tivi Samsung 55 Inch', 'SS-55-003', '2023-10-01', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (18, 14, N'Micro Shure UGX20', 'SH-UGX-001', '2023-11-15', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (19, 15, N'Loa Sub B&W 610', 'BW-610-001', '2023-12-01', N'Good');
INSERT INTO [Equipment] (EquipmentID, RoomID, EquipmentName, SerialNumber, PurchaseDate, Status) VALUES (20, 16, N'Màn Hình Cảm Ứng VietKTV 22 Inch', 'VK-22-001', '2024-01-10', N'Good');
SET IDENTITY_INSERT [Equipment] OFF;

-- 9.12 MAINTENANCE LOG (Nhật ký bảo trì)
SET IDENTITY_INSERT [MaintenanceLog] ON;
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (1, 3, 3, N'Rớt móp đầu mic', 150000.00, '2026-06-22 21:58:47');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (2, 5, 2, N'Máy kêu to, hết ga', 500000.00, '2026-06-26 21:58:47');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (3, 3, 4, N'Thay củ micro mới', 350000.00, '2026-07-10 14:30:00');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (4, 5, 5, N'Vệ sinh và nạp ga điều hòa', 400000.00, '2026-07-15 09:15:00');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (5, 15, 3, N'Cháy bóng đèn laser party', 600000.00, '2026-07-18 16:45:00');
INSERT INTO [MaintenanceLog] (LogID, EquipmentID, ReportedByID, IssueDescription, RepairCost, LogDate) VALUES (6, 16, 2, N'Hỏng van thoát nước điều hòa', 250000.00, '2026-07-22 11:20:00');
SET IDENTITY_INSERT [MaintenanceLog] OFF;

-- 9.13 CATEGORY (Danh mục dịch vụ)
SET IDENTITY_INSERT [Category] ON;
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (1, N'Đồ Uống');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (2, N'Đồ Ăn');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (3, N'Trái Cây');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (4, N'Combo');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (5, N'Bia');
INSERT INTO [Category] (CategoryID, CategoryName) VALUES (6, N'Rượu');
SET IDENTITY_INSERT [Category] OFF;

-- 9.14 SERVICE ITEM (Mặt hàng dịch vụ)
SET IDENTITY_INSERT [ServiceItem] ON;
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (1, 5, 'https://images.unsplash.com/photo-1599419685838-28e405ea05b9?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', N'Heineken', 40000.00, N'Lon', 500);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (2, 5, 'https://images.unsplash.com/photo-1624795763669-d3605b99a0cb?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', N'Tiger', 30000.00, N'Lon', 800);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (3, 6, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfaRpKLvTJqyAa2h2Pbft9SkIdv0NMNWDZNE2WwU0aFw&s=10', N'Chivas 12', 1500000.00, N'Chai', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (4, 1, 'https://sonhawater.com/wp-content/uploads/2019/10/aquafina-15-lit.jpg', N'Aquafina', 20000.00, N'Chai', 400);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (5, 2, 'https://bokhothuba.com/wp-content/uploads/2020/03/bo-kho-soi-2.jpg', N'Khô bò', 150000.00, N'Đĩa', 50);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (6, 3, 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?auto=format&fit=crop&q=80&w=600', N'Trái cây VIP loại 2', 450000.00, N'Đĩa', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (7, 4, 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?auto=format&fit=crop&q=80&w=600', N'Combo Sinh Nhật VIP', 4000000.00, N'Combo', 5);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (8, 2, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT_37y9BhxeWYbd5tpGG4ZcOpzH5LoL7Sx0V23yoNtlYA&s=10', N'Đào Tiên', 3000000.00, N'Nồi', 5);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (11, 5, 'https://product.hstatic.net/200000768759/product/bia-sai-gon-special-bun-bo-ganh_5d620d0b06814c71921dd7f9a93d620f_master.png', N'Saigon Bia', 40000.00, N'Lon', 500);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (12, 5, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTEAJDIigBoE2SlJPVg0CMhqP3Udgm9w6e4K9ScBQM94g&s=10', N'333 Bia', 30000.00, N'Lon', 800);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (13, 6, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTnc4P2O4yblkjCh7c8pyNGWelPlJy3WQnCiVf4-oeA8Q&s=10', N'Chivas 32', 1500000.00, N'Chai', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (14, 1, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoe6keF5DkVOszFGOBSaBb4-gKCPuj8LHeo6ooGMDeSw&s=10', N'Lavie', 20000.00, N'Chai', 400);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (15, 2, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcStfEu0XWU5xbEOCKjTsh5bDFm3LfqVPRSALgnv2G1sNoBguqzVDyZLc-M&s=10', N'Khô gà Mixi', 150000.00, N'Đĩa', 50);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (16, 3, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQCcjJQx2h7QZ7m_vD_fAuwQ5leiAj3JPa-TC1Su1MYXQ&s=10', N'Trái cây VIP', 350000.00, N'Đĩa', 20);
INSERT INTO [ServiceItem] (ServiceID, CategoryID, ImageUrl, ServiceName, SellingPrice, Unit, StockQuantity) 
VALUES (17, 4, 'https://images.unsplash.com/photo-1558636508-e0db3814bd1d?auto=format&fit=crop&q=80&w=600', N'Combo Sinh Nhật', 1500000.00, N'Combo', 5);
SET IDENTITY_INSERT [ServiceItem] OFF;

-- 9.15 SUPPLIER (Nhà cung cấp)
SET IDENTITY_INSERT [Supplier] ON;
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (1, N'Bia Nước Ngọt Thành Phát', N'Anh Thành', '0901111222', N'Q10, TP.HCM');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (2, N'Rượu Ngoại Sài Gòn', N'Chị Hương', '0903333444', N'Q1, TP.HCM');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (3, N'Nông Sản Thực Phẩm Việt', N'Anh Nam', '0905555666', N'Q5, TP.HCM');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (4, N'Thiết Bị Điện Máy Sài Gòn', N'Chị Mai', '0907777888', N'Q3, TP.HCM');
INSERT INTO [Supplier] (SupplierID, SupplierName, ContactName, Phone, Address) VALUES (5, N'Đá Lạnh & Giải Khát Tân Bình', N'Anh Dũng', '0909999000', N'Q.Tân Bình, TP.HCM');
SET IDENTITY_INSERT [Supplier] OFF;

-- 9.16 PURCHASE ORDER & DETAIL (Đơn nhập kho)
SET IDENTITY_INSERT [PurchaseOrder] ON;
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (1, 1, 2, '2026-06-10 09:00:00', 16500000.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (2, 2, 2, '2026-06-15 14:30:00', 10000000.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (3, 3, 5, '2026-07-01 10:15:00', 4500000.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (4, 1, 2, '2026-07-12 22:33:52', 7500000.00);
INSERT INTO [PurchaseOrder] (PO_ID, SupplierID, CreatedByID, OrderDate, TotalAmount) VALUES (5, 2, 5, '2026-07-20 16:40:00', 15000000.00);
SET IDENTITY_INSERT [PurchaseOrder] OFF;

SET IDENTITY_INSERT [PurchaseOrderDetail] ON;
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (1, 1, 1, 25000.00, 300);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (2, 1, 2, 18000.00, 500);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (3, 2, 3, 1000000.00, 10);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (4, 3, 5, 90000.00, 50);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (5, 4, 11, 25000.00, 300);
INSERT INTO [PurchaseOrderDetail] (PODetailID, PO_ID, ServiceID, ImportPrice, Quantity) VALUES (6, 5, 13, 1000000.00, 15);
SET IDENTITY_INSERT [PurchaseOrderDetail] OFF;

-- 9.17 PROMOTION (Khuyến mãi)
SET IDENTITY_INSERT [Promotion] ON;
INSERT INTO [Promotion] (PromotionID, PromoCode, PromoName, DiscountPercent, MaxDiscountAmount, StartDate, EndDate) VALUES (1, N'NEWYEAR', N'Giảm 20%', 20.00, 500000.00, '2024-01-01 00:00:00', '2026-12-31 00:00:00');
INSERT INTO [Promotion] (PromotionID, PromoCode, PromoName, DiscountPercent, MaxDiscountAmount, StartDate, EndDate) VALUES (2, N'NOPROMO', N'Không KM', 0.00, 0.00, '2000-01-01 00:00:00', '2099-12-31 00:00:00');
INSERT INTO [Promotion] (PromotionID, PromoCode, PromoName, DiscountPercent, MaxDiscountAmount, StartDate, EndDate) VALUES (3, N'SUMMER2026', N'Ưu Đãi Mùa Hè 15%', 15.00, 300000.00, '2026-06-01 00:00:00', '2026-08-31 00:00:00');
INSERT INTO [Promotion] (PromotionID, PromoCode, PromoName, DiscountPercent, MaxDiscountAmount, StartDate, EndDate) VALUES (4, N'HAPPYHOUR', N'Khung Giờ Vàng 10%', 10.00, 200000.00, '2026-01-01 00:00:00', '2026-12-31 00:00:00');
SET IDENTITY_INSERT [Promotion] OFF;

-- 9.18 PAYMENT METHOD
SET IDENTITY_INSERT [PaymentMethod] ON;
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (1, N'Tiền mặt');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (2, N'VNPay');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (3, N'Visa');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (4, N'Momo');
INSERT INTO [PaymentMethod] (MethodID, MethodName) VALUES (5, N'Chuyển khoản');
SET IDENTITY_INSERT [PaymentMethod] OFF;

-- 9.19 HOLIDAY (Ngày lễ năm 2026)
SET IDENTITY_INSERT [Holiday] ON;
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (1, N'Tết Dương Lịch 2026', '2026-01-01', 20.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (2, N'Tết Nguyên Đán 2026 (Giao Thừa)', '2026-02-16', 200.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (3, N'Tết Nguyên Đán 2026 (Mùng 1)', '2026-02-17', 200.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (4, N'Tết Nguyên Đán 2026 (Mùng 2)', '2026-02-18', 150.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (5, N'Tết Nguyên Đán 2026 (Mùng 3)', '2026-02-19', 100.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (6, N'Giỗ Tổ Hùng Vương 2026', '2026-04-26', 30.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (7, N'Ngày Giải Phóng Miền Nam', '2026-04-30', 50.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (8, N'Quốc Tế Lao Động', '2026-05-01', 50.00, 1);
INSERT INTO [Holiday] (HolidayID, HolidayName, HolidayDate, SurchargePercent, IsActive) VALUES (9, N'Quốc Khánh', '2026-09-02', 40.00, 1);
SET IDENTITY_INSERT [Holiday] OFF;

-- 9.20 PRICING POLICY
SET IDENTITY_INSERT [PricingPolicy] ON;
INSERT INTO [PricingPolicy] (PolicyID, PolicyName, PolicyType, Value, IsActive) VALUES (1, N'Phụ thu Cuối tuần (T7 & CN)', N'Weekend', 15.00, 1);
INSERT INTO [PricingPolicy] (PolicyID, PolicyName, PolicyType, Value, IsActive) VALUES (2, N'Phụ thu Ngày lễ chung', N'Holiday', 30.00, 1);
SET IDENTITY_INSERT [PricingPolicy] OFF;

-- 9.21 ROOM PRICE
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

-- =========================================================================
-- 9.22 EMPLOYEE SCHEDULE (LỊCH PHÂN CA LÀM VIỆC FULL TUẦN TỪ T2 ĐẾN CN)
-- Tuần 1: 2026-07-20 (T2) -> 2026-07-26 (CN)
-- Tuần 2: 2026-07-27 (T2) -> 2026-08-02 (CN)
-- Phủ đầy đủ 3 ca/ngày (Ca Sáng, Ca Chiều, Ca Khuya) với Lễ tân và Phục vụ
-- =========================================================================
SET IDENTITY_INSERT [EmployeeSchedule] ON;

-- TUẦN 1: 2026-07-20 (Thứ Hai)
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (1, 3, 1, '2026-07-20', N'Completed', 1); -- Ca 1 Lễ tân
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (2, 11, 1, '2026-07-20', N'Completed', 1); -- Ca 1 Phục vụ
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (3, 14, 1, '2026-07-20', N'Completed', 1); -- Ca 1 Phục vụ
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (4, 4, 2, '2026-07-20', N'Completed', 1); -- Ca 2 Lễ tân
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (5, 12, 2, '2026-07-20', N'Completed', 1); -- Ca 2 Phục vụ
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (6, 15, 2, '2026-07-20', N'Completed', 1); -- Ca 2 Phục vụ
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (7, 9, 3, '2026-07-20', N'Completed', 1); -- Ca 3 Lễ tân
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (8, 13, 3, '2026-07-20', N'Completed', 1); -- Ca 3 Phục vụ
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (9, 16, 3, '2026-07-20', N'Completed', 1); -- Ca 3 Phục vụ

-- TUẦN 1: 2026-07-21 (Thứ Ba)
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (10, 3, 1, '2026-07-21', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (11, 11, 1, '2026-07-21', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (12, 14, 1, '2026-07-21', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (13, 4, 2, '2026-07-21', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (14, 12, 2, '2026-07-21', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (15, 15, 2, '2026-07-21', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (16, 9, 3, '2026-07-21', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (17, 13, 3, '2026-07-21', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (18, 16, 3, '2026-07-21', N'Completed', 1);

-- TUẦN 1: 2026-07-22 (Thứ Tư)
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (19, 10, 1, '2026-07-22', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (20, 11, 1, '2026-07-22', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (21, 14, 1, '2026-07-22', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (22, 4, 2, '2026-07-22', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (23, 12, 2, '2026-07-22', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (24, 15, 2, '2026-07-22', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (25, 9, 3, '2026-07-22', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (26, 13, 3, '2026-07-22', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (27, 16, 3, '2026-07-22', N'Completed', 1);

-- TUẦN 1: 2026-07-23 (Thứ Năm)
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (28, 3, 1, '2026-07-23', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (29, 11, 1, '2026-07-23', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (30, 14, 1, '2026-07-23', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (31, 4, 2, '2026-07-23', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (32, 12, 2, '2026-07-23', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (33, 15, 2, '2026-07-23', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (34, 9, 3, '2026-07-23', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (35, 13, 3, '2026-07-23', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (36, 16, 3, '2026-07-23', N'Completed', 1);

-- TUẦN 1: 2026-07-24 (Thứ Sáu)
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (37, 3, 1, '2026-07-24', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (38, 11, 1, '2026-07-24', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (39, 14, 1, '2026-07-24', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (40, 4, 2, '2026-07-24', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (41, 12, 2, '2026-07-24', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (42, 15, 2, '2026-07-24', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (43, 9, 3, '2026-07-24', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (44, 13, 3, '2026-07-24', N'Completed', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (45, 16, 3, '2026-07-24', N'Completed', 1);

-- TUẦN 1: 2026-07-25 (Thứ Bảy)
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (46, 3, 1, '2026-07-25', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (47, 11, 1, '2026-07-25', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (48, 14, 1, '2026-07-25', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (49, 4, 2, '2026-07-25', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (50, 12, 2, '2026-07-25', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (51, 15, 2, '2026-07-25', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (52, 9, 3, '2026-07-25', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (53, 13, 3, '2026-07-25', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (54, 16, 3, '2026-07-25', N'Scheduled', 1);

-- TUẦN 1: 2026-07-26 (Chủ Nhật)
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (55, 10, 1, '2026-07-26', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (56, 11, 1, '2026-07-26', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (57, 14, 1, '2026-07-26', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (58, 4, 2, '2026-07-26', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (59, 12, 2, '2026-07-26', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (60, 15, 2, '2026-07-26', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (61, 9, 3, '2026-07-26', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (62, 13, 3, '2026-07-26', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (63, 16, 3, '2026-07-26', N'Scheduled', 1);

-- TUẦN 2: 2026-07-27 (Thứ Hai) đến 2026-08-02 (Chủ Nhật)
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (64, 3, 1, '2026-07-27', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (65, 11, 1, '2026-07-27', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (66, 14, 1, '2026-07-27', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (67, 4, 2, '2026-07-27', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (68, 12, 2, '2026-07-27', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (69, 15, 2, '2026-07-27', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (70, 9, 3, '2026-07-27', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (71, 13, 3, '2026-07-27', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (72, 16, 3, '2026-07-27', N'Scheduled', 1);

INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (73, 3, 1, '2026-07-28', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (74, 11, 1, '2026-07-28', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (75, 4, 2, '2026-07-28', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (76, 12, 2, '2026-07-28', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (77, 9, 3, '2026-07-28', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (78, 13, 3, '2026-07-28', N'Scheduled', 1);

INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (79, 3, 1, '2026-07-29', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (80, 11, 1, '2026-07-29', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (81, 4, 2, '2026-07-29', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (82, 12, 2, '2026-07-29', N'Scheduled', 1);

INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (83, 3, 1, '2026-07-30', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (84, 11, 1, '2026-07-30', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (85, 4, 2, '2026-07-30', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (86, 12, 2, '2026-07-30', N'Scheduled', 1);

INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (87, 3, 1, '2026-07-31', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (88, 11, 1, '2026-07-31', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (89, 4, 2, '2026-07-31', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (90, 12, 2, '2026-07-31', N'Scheduled', 1);

INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (91, 3, 1, '2026-08-01', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (92, 11, 1, '2026-08-01', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (93, 4, 2, '2026-08-01', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (94, 12, 2, '2026-08-01', N'Scheduled', 1);

INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (95, 3, 1, '2026-08-02', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (96, 11, 1, '2026-08-02', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (97, 4, 2, '2026-08-02', N'Scheduled', 1);
INSERT INTO [EmployeeSchedule] (ScheduleID, AccountID, ShiftID, WorkDate, Status, IsActive) VALUES (98, 12, 2, '2026-08-02', N'Scheduled', 1);
SET IDENTITY_INSERT [EmployeeSchedule] OFF;

-- 9.23 ATTENDANCE (Điểm danh nhân viên)
SET IDENTITY_INSERT [Attendance] ON;
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (1, 3, 1, '2026-07-20 07:55:00', '2026-07-20 16:05:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (2, 11, 2, '2026-07-20 07:58:00', '2026-07-20 16:00:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (3, 14, 3, '2026-07-20 08:15:00', '2026-07-20 16:00:00', 7.75, N'Late', N'Đi trễ 15 phút do tắc đường');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (4, 4, 4, '2026-07-20 15:50:00', '2026-07-21 00:05:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (5, 12, 5, '2026-07-20 16:00:00', '2026-07-21 00:00:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (6, 15, 6, '2026-07-20 16:05:00', '2026-07-21 00:00:00', 7.90, N'Late', N'Đi trễ 5 phút');

INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (7, 3, 10, '2026-07-21 07:50:00', '2026-07-21 16:00:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (8, 11, 11, '2026-07-21 08:00:00', '2026-07-21 16:00:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (9, 4, 13, '2026-07-21 15:55:00', '2026-07-22 00:10:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (10, 12, 14, '2026-07-21 16:00:00', '2026-07-22 00:00:00', 8.00, N'OnTime', N'Đúng giờ');

INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (11, 10, 19, '2026-07-22 07:55:00', '2026-07-22 16:00:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (12, 11, 20, '2026-07-22 08:00:00', '2026-07-22 16:00:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (13, 4, 22, '2026-07-22 15:50:00', '2026-07-23 00:00:00', 8.00, N'OnTime', N'Đúng giờ');

INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (14, 3, 28, '2026-07-23 07:58:00', '2026-07-23 16:05:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (15, 11, 29, '2026-07-23 08:00:00', '2026-07-23 16:00:00', 8.00, N'OnTime', N'Đúng giờ');

INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (16, 3, 37, '2026-07-24 07:50:00', '2026-07-24 16:00:00', 8.00, N'OnTime', N'Đúng giờ');
INSERT INTO [Attendance] (AttendanceID, AccountID, ScheduleID, CheckInTime, CheckOutTime, TotalHours, Status, Note)
VALUES (17, 11, 38, '2026-07-24 08:00:00', '2026-07-24 16:00:00', 8.00, N'OnTime', N'Đúng giờ');
SET IDENTITY_INSERT [Attendance] OFF;

-- 9.24 LEAVE REQUEST (Đơn xin nghỉ phép)
SET IDENTITY_INSERT [LeaveRequest] ON;
INSERT INTO [LeaveRequest] (LeaveRequestId, AccountId, ScheduleId, Reason, Status, CreatedAt, ApprovedById, RequestedDate, ShiftId)
VALUES (1, 14, 57, N'Bận việc gia đình tại quê', 'Approved', '2026-07-22 10:00:00', 2, '2026-07-26', 1);
INSERT INTO [LeaveRequest] (LeaveRequestId, AccountId, ScheduleId, Reason, Status, CreatedAt, ApprovedById, RequestedDate, ShiftId)
VALUES (2, 12, 68, N'Đi khám sức khỏe định kỳ', 'Pending', '2026-07-24 14:20:00', NULL, '2026-07-27', 2);
INSERT INTO [LeaveRequest] (LeaveRequestId, AccountId, ScheduleId, Reason, Status, CreatedAt, ApprovedById, RequestedDate, ShiftId)
VALUES (3, 9, 70, N'Trùng lịch thi tại trường', 'Rejected', '2026-07-23 09:15:00', 2, '2026-07-27', 3);
SET IDENTITY_INSERT [LeaveRequest] OFF;

-- 9.25 SHIFT SWAP REQUEST (Đơn xin đổi ca)
SET IDENTITY_INSERT [ShiftSwapRequest] ON;
INSERT INTO [ShiftSwapRequest] (SwapRequestId, RequesterId, RequesterScheduleId, TargetId, TargetScheduleId, Status, CreatedAt, ApprovedById)
VALUES (1, 11, 47, 14, 48, 'Approved', '2026-07-24 11:00:00', 2);
INSERT INTO [ShiftSwapRequest] (SwapRequestId, RequesterId, RequesterScheduleId, TargetId, TargetScheduleId, Status, CreatedAt, ApprovedById)
VALUES (2, 12, 68, 15, 69, 'Pending', '2026-07-25 08:30:00', NULL);
SET IDENTITY_INSERT [ShiftSwapRequest] OFF;

-- 9.26 BOOKING (Đơn đặt phòng)
SET IDENTITY_INSERT [Booking] ON;
-- Đã hoàn thành (Past)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (1, 1, 3, 5, '2026-06-24 21:58:47', '2026-06-25 21:58:47', '2026-06-26 01:58:47', N'Completed', 11, 4, N'Khách gọi đặt trước');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (2, 2, 4, 8, '2026-06-26 21:58:47', '2026-06-26 21:58:47', '2026-06-27 00:58:47', N'Completed', 12, 10, N'Sinh nhật');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (3, 3, 3, 4, '2026-06-27 21:58:47', '2026-06-27 21:58:47', '2026-06-27 23:58:47', N'Completed', 13, 2, N'Khách vãng lai');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (4, 1, 3, 1, '2026-06-12 21:58:47', '2026-06-13 21:58:47', '2026-06-13 23:58:47', N'Completed', 14, 5, N'Họp nhóm');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (9, 1, 3, 7, '2026-06-17 21:58:47', '2026-06-18 21:58:47', '2026-06-18 23:58:47', N'Completed', 13, 15, N'Liên hoan công ty');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (10, 2, 4, 8, '2026-06-18 21:58:47', '2026-06-19 21:58:47', '2026-06-20 00:58:47', N'Completed', 14, 4, N'Tiệc nhỏ');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (11, 3, 4, 9, '2026-06-19 21:58:47', '2026-06-20 21:58:47', '2026-06-21 01:58:47', N'Completed', 11, 8, N'Bạn bè họp mặt');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (13, 5, 3, 1, '2026-06-21 21:58:47', '2026-06-22 21:58:47', '2026-06-23 00:58:47', N'Completed', 13, 6, N'Hát gia đình');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (14, 1, 4, 2, '2026-06-22 21:58:47', '2026-06-23 21:58:47', '2026-06-23 23:58:47', N'Completed', 14, 10, N'Gia đình giải trí');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (15, 2, 4, 5, '2026-06-23 21:58:47', '2026-06-24 21:58:47', '2026-06-25 01:58:47', N'Completed', 11, 6, N'Khách VIP');

-- Đang sử dụng (CheckedIn) - Khớp đúng với các Room có Status = 'InUse' (Room 4, 6, 10, 12)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (6, 3, 4, 4, '2026-07-25 08:00:00', '2026-07-25 09:00:00', '2026-07-25 12:00:00', N'CheckedIn', 11, 3, N'Khách đang hát');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (8, 5, 3, 6, '2026-07-25 08:30:00', '2026-07-25 09:30:00', '2026-07-25 13:30:00', N'CheckedIn', 12, 8, N'Khách nhận phòng sớm');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (12, 4, 3, 10, '2026-07-25 07:45:00', '2026-07-25 08:30:00', '2026-07-25 12:30:00', N'CheckedIn', 12, 12, N'Tiệc công ty');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (16, 7, 4, 12, '2026-07-25 09:00:00', '2026-07-25 10:00:00', '2026-07-25 14:00:00', N'CheckedIn', 15, 4, N'Khách vãng lai vào hát');

-- Đơn chờ nhận phòng (Pending)
INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (5, 2, 3, 2, '2026-07-25 09:00:00', '2026-07-25 20:00:00', '2026-07-25 22:00:00', N'Pending', NULL, 4, N'Sinh nhật tối nay');

INSERT INTO [Booking] (BookingID, CustomerID, CreatedByID, RoomID, BookingTime, StartTime, EndTime, Status, StaffId, GuestCount, Note) 
VALUES (7, 4, 4, 5, '2026-07-25 09:30:00', '2026-07-26 17:00:00', '2026-07-26 19:00:00', N'Pending', NULL, 4, N'Đặt trước ngày mai');
SET IDENTITY_INSERT [Booking] OFF;

-- 9.27 INVOICE (Hóa đơn)
SET IDENTITY_INSERT [Invoice] ON;
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (1, 1, 5, 3, 2, '2026-06-25 21:58:47', '2026-06-26 01:58:47', 1200000.00, 2750000.00, 790000.00, 3160000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (2, 2, 8, 3, 1, '2026-06-26 21:58:47', '2026-06-27 00:58:47', 1800000.00, 1500000.00, 500000.00, 2800000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (3, 3, 4, 4, 2, '2026-06-27 21:58:47', '2026-06-27 23:58:47', 240000.00, 190000.00, 0.00, 430000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (4, 4, 1, 3, 2, '2026-06-13 21:58:47', '2026-06-13 23:58:47', 300000.00, 140000.00, 0.00, 440000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (5, 9, 7, 3, 2, '2026-06-18 21:58:47', '2026-06-18 23:58:47', 600000.00, 300000.00, 90000.00, 810000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (6, 10, 8, 4, 2, '2026-06-19 21:58:47', '2026-06-20 00:58:47', 1800000.00, 1500000.00, 330000.00, 2970000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (7, 11, 9, 4, 2, '2026-06-20 21:58:47', '2026-06-21 01:58:47', 2400000.00, 1500000.00, 390000.00, 3510000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (8, 13, 1, 3, 2, '2026-06-22 21:58:47', '2026-06-23 00:58:47', 450000.00, 260000.00, 0.00, 710000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (9, 14, 2, 4, 2, '2026-06-23 21:58:47', '2026-06-23 23:58:47', 300000.00, 140000.00, 0.00, 440000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (10, 15, 5, 4, 2, '2026-06-24 21:58:47', '2026-06-25 01:58:47', 1200000.00, 600000.00, 180000.00, 1620000.00, N'Paid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (11, 6, 4, 4, 2, '2026-07-25 09:00:00', NULL, 360000.00, 190000.00, 0.00, 550000.00, N'Unpaid');
INSERT INTO [Invoice] (InvoiceID, BookingID, RoomID, ReceptionistID, PromotionID, CheckInTime, CheckOutTime, RoomTotal, ServiceTotal, DiscountAmount, GrandTotal, Status) VALUES (12, 8, 6, 3, 3, '2026-07-25 09:30:00', NULL, 1200000.00, 450000.00, 247500.00, 1402500.00, N'Unpaid');
SET IDENTITY_INSERT [Invoice] OFF;

-- 9.28 INVOICE DETAIL (Chi tiết dịch vụ hóa đơn)
SET IDENTITY_INSERT [InvoiceDetail] ON;
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (1, 1, 3, 1, 1500000.00, 1, 1, NULL);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (2, 1, 6, 2, 450000.00, 1, 1, NULL);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (3, 1, 5, 2, 150000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (4, 2, 7, 1, 4000000.00, 1, 1, NULL);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (5, 2, 2, 10, 30000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (6, 3, 5, 1, 150000.00, 1, 1, NULL);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (7, 3, 1, 1, 40000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (8, 4, 1, 3, 40000.00, 1, 1, NULL);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (9, 4, 4, 1, 20000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (10, 5, 5, 2, 150000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (11, 6, 7, 1, 4000000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (12, 7, 3, 1, 1500000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (13, 8, 5, 1, 150000.00, 1, 1, NULL);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (14, 8, 2, 3, 30000.00, 1, 1, NULL);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (15, 8, 4, 1, 20000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (16, 9, 1, 3, 40000.00, 1, 1, NULL);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (17, 9, 4, 1, 20000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (18, 10, 6, 1, 450000.00, 1, 1, NULL);
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (19, 10, 5, 1, 150000.00, 1, 1, NULL);

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (20, 11, 5, 1, 150000.00, 1, 0, N'Mang lên phòng');
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (21, 11, 1, 1, 40000.00, 1, 0, N'Ướp lạnh');

INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (22, 12, 16, 1, 350000.00, 1, 0, N'Trái cây dĩa lớn');
INSERT INTO [InvoiceDetail] (InvoiceDetailID, InvoiceID, ServiceID, Quantity, UnitPrice, IsService, IsFulFilled, Note) VALUES (23, 12, 1, 2, 40000.00, 1, 0, N'Heineken lon');
SET IDENTITY_INSERT [InvoiceDetail] OFF;

-- 9.29 PAYMENT TRANSACTION (Giao dịch thanh toán)
SET IDENTITY_INSERT [PaymentTransaction] ON;
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (1, 1, 3, 3160000.00, '2026-06-26 01:58:47', N'VISA-123');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (2, 2, 1, 1000000.00, '2026-06-27 00:58:47', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (3, 2, 4, 1800000.00, '2026-06-27 00:58:47', N'MOMO-987');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (4, 3, 4, 430000.00, '2026-06-27 23:58:47', N'MOMO-111');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (5, 4, 1, 440000.00, '2026-06-13 23:58:47', NULL);
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (6, 5, 2, 810000.00, '2026-06-18 23:58:47', N'VNPAY-777');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (7, 6, 4, 2970000.00, '2026-06-20 00:58:47', N'MOMO-222');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (8, 7, 3, 3510000.00, '2026-06-21 01:58:47', N'VISA-555');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (9, 8, 2, 710000.00, '2026-06-23 00:58:47', N'VNPAY-888');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (10, 9, 4, 440000.00, '2026-06-23 23:58:47', N'MOMO-333');
INSERT INTO [PaymentTransaction] (TransactionID, InvoiceID, MethodID, Amount, TransactionDate, ReferenceCode) VALUES (11, 10, 3, 1620000.00, '2026-06-25 01:58:47', N'VISA-666');
SET IDENTITY_INSERT [PaymentTransaction] OFF;

-- 9.30 EXPENSE CATEGORY & EXPENSE (Chi phí vận hành)
SET IDENTITY_INSERT [ExpenseCategory] ON;
INSERT INTO [ExpenseCategory] (CategoryID, CategoryName) VALUES (1, N'Điện');
INSERT INTO [ExpenseCategory] (CategoryID, CategoryName) VALUES (2, N'Nước');
INSERT INTO [ExpenseCategory] (CategoryID, CategoryName) VALUES (3, N'Mặt bằng');
INSERT INTO [ExpenseCategory] (CategoryID, CategoryName) VALUES (4, N'Bảo trì');
INSERT INTO [ExpenseCategory] (CategoryID, CategoryName) VALUES (5, N'Marketing');
SET IDENTITY_INSERT [ExpenseCategory] OFF;

SET IDENTITY_INSERT [Expense] ON;
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (1, 1, '2026-05-15', 5400000.00, N'Tiền điện tháng 5/2026', '2026-05-15 10:00:00');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (2, 2, '2026-05-15', 850000.00, N'Tiền nước tháng 5/2026', '2026-05-15 10:00:00');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (3, 3, '2026-06-01', 25000000.00, N'Thuê mặt bằng tháng 6/2026', '2026-06-01 09:00:00');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (4, 1, '2026-06-15', 6200000.00, N'Tiền điện tháng 6/2026', '2026-06-15 10:00:00');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (5, 4, '2026-06-20', 2100000.00, N'Sửa chữa âm thanh phòng VIP', '2026-06-20 14:00:00');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (6, 3, '2026-07-01', 25000000.00, N'Thuê mặt bằng tháng 7/2026', '2026-07-01 09:00:00');
INSERT INTO [Expense] (ExpenseID, CategoryID, ExpenseDate, Amount, Note, CreatedAt) VALUES (7, 5, '2026-07-10', 3500000.00, N'Chạy quảng cáo Facebook Mùa Hè', '2026-07-10 11:30:00');
SET IDENTITY_INSERT [Expense] OFF;

-- 9.31 ROOM TRANSFER HISTORY (Lịch sử đổi phòng)
SET IDENTITY_INSERT [RoomTransferHistory] ON;
INSERT INTO [RoomTransferHistory] (TransferID, BookingID, FromRoomID, ToRoomID, TransferredAt, Reason, ProcessedByID)
VALUES (1, 2, 1, 8, '2026-06-26 22:15:00', N'Khách muốn đổi sang phòng VIP lớn hơn', 4);
SET IDENTITY_INSERT [RoomTransferHistory] OFF;

-- 9.32 NOTIFICATION LOG (Nhật ký thông báo)
SET IDENTITY_INSERT [NotificationLog] ON;
INSERT INTO [NotificationLog] (NotificationID, BookingID, CustomerID, Channel, Recipient, MessageContent, SentStatus, SentAt) 
VALUES (1, 1, 1, N'SMS', N'0911111111', N'Cảm ơn quý khách Lê Minh Tuấn đã đặt phòng tại Karaoke Management. Mã đặt phòng: #1', N'Sent', '2026-06-24 22:00:00');
INSERT INTO [NotificationLog] (NotificationID, BookingID, CustomerID, Channel, Recipient, MessageContent, SentStatus, SentAt) 
VALUES (2, 2, 2, N'Email', N'hoangnv@gmail.com', N'Phòng 204 VIP của quý khách đã sẵn sàng lúc 21:58', N'Sent', '2026-06-26 21:50:00');
INSERT INTO [NotificationLog] (NotificationID, BookingID, CustomerID, Channel, Recipient, MessageContent, SentStatus, SentAt) 
VALUES (3, 5, 2, N'SMS', N'0922222222', N'Xác nhận lịch đặt phòng 102 lúc 20:00 tối nay.', N'Sent', '2026-07-25 09:05:00');
SET IDENTITY_INSERT [NotificationLog] OFF;

-- 9.33 CUSTOMER REVIEW (Đánh giá từ khách hàng)
SET IDENTITY_INSERT [CustomerReview] ON;
INSERT INTO [CustomerReview] (ReviewID, BookingID, Rating, Comment, CreatedAt)
VALUES (1, 1, 5, N'Âm thanh rất hay, nhân viên phục vụ nhiệt tình chu đáo!', '2026-06-26 02:15:00');
INSERT INTO [CustomerReview] (ReviewID, BookingID, Rating, Comment, CreatedAt)
VALUES (2, 2, 5, N'Phòng rộng rãi sạch sẻ, trái cây tươi ngon.', '2026-06-27 01:10:00');
INSERT INTO [CustomerReview] (ReviewID, BookingID, Rating, Comment, CreatedAt)
VALUES (3, 4, 4, N'Chất lượng tốt, phục vụ nhanh chóng.', '2026-06-14 00:30:00');
SET IDENTITY_INSERT [CustomerReview] OFF;

-- Re-enable all constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all';
GO

