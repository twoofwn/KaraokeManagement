SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.CancellationReason', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CancellationReason (
        CancellationReasonID INT IDENTITY(1,1) PRIMARY KEY,
        Code VARCHAR(50) NOT NULL,
        ReasonName NVARCHAR(200) NOT NULL,
        AppliesTo VARCHAR(20) NOT NULL
            CONSTRAINT DF_CancellationReason_AppliesTo DEFAULT 'Both',
        RequiresDetail BIT NOT NULL
            CONSTRAINT DF_CancellationReason_RequiresDetail DEFAULT 0,
        IsActive BIT NOT NULL
            CONSTRAINT DF_CancellationReason_IsActive DEFAULT 1,
        SortOrder INT NOT NULL
            CONSTRAINT DF_CancellationReason_SortOrder DEFAULT 0,
        CONSTRAINT UQ_CancellationReason_Code UNIQUE (Code),
        CONSTRAINT CK_CancellationReason_AppliesTo
            CHECK (AppliesTo IN ('Customer', 'Receptionist', 'Both'))
    );
END;

MERGE dbo.CancellationReason AS target
USING (VALUES
    ('CUSTOMER_CHANGED_PLAN', N'Thay đổi kế hoạch', 'Customer', CAST(0 AS BIT), 10),
    ('CUSTOMER_WRONG_BOOKING', N'Đặt nhầm phòng hoặc thời gian', 'Customer', CAST(0 AS BIT), 20),
    ('CUSTOMER_COST', N'Chi phí không phù hợp', 'Customer', CAST(0 AS BIT), 30),
    ('CUSTOMER_NO_NEED', N'Không còn nhu cầu', 'Customer', CAST(0 AS BIT), 40),
    ('RECEPTIONIST_CUSTOMER_REQUEST', N'Khách hàng yêu cầu hủy', 'Receptionist', CAST(0 AS BIT), 50),
    ('RECEPTIONIST_ROOM_ISSUE', N'Phòng gặp sự cố hoặc bảo trì', 'Receptionist', CAST(0 AS BIT), 60),
    ('RECEPTIONIST_SCHEDULE_CONFLICT', N'Trùng lịch hoặc không thể phục vụ', 'Receptionist', CAST(0 AS BIT), 70),
    ('RECEPTIONIST_NO_SHOW', N'Khách không đến', 'Receptionist', CAST(0 AS BIT), 80),
    ('OTHER', N'Khác', 'Both', CAST(1 AS BIT), 999)
) AS source (Code, ReasonName, AppliesTo, RequiresDetail, SortOrder)
ON target.Code = source.Code
WHEN MATCHED THEN
    UPDATE SET
        ReasonName = source.ReasonName,
        AppliesTo = source.AppliesTo,
        RequiresDetail = source.RequiresDetail,
        SortOrder = source.SortOrder,
        IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (Code, ReasonName, AppliesTo, RequiresDetail, IsActive, SortOrder)
    VALUES (source.Code, source.ReasonName, source.AppliesTo, source.RequiresDetail, 1, source.SortOrder);

IF COL_LENGTH(N'dbo.Booking', N'CancellationReasonID') IS NULL
    ALTER TABLE dbo.Booking ADD CancellationReasonID INT NULL;

IF COL_LENGTH(N'dbo.Booking', N'CancellationReasonDetail') IS NULL
    ALTER TABLE dbo.Booking ADD CancellationReasonDetail NVARCHAR(500) NULL;

IF COL_LENGTH(N'dbo.Booking', N'CancelledAt') IS NULL
    ALTER TABLE dbo.Booking ADD CancelledAt DATETIME2 NULL;

IF COL_LENGTH(N'dbo.Booking', N'CancelledByType') IS NULL
    ALTER TABLE dbo.Booking ADD CancelledByType VARCHAR(20) NULL;

IF COL_LENGTH(N'dbo.Booking', N'CancelledByAccountID') IS NULL
    ALTER TABLE dbo.Booking ADD CancelledByAccountID INT NULL;

IF COL_LENGTH(N'dbo.Booking', N'CancelledByCustomerID') IS NULL
    ALTER TABLE dbo.Booking ADD CancelledByCustomerID INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Booking_CancellationReason')
    EXEC(N'ALTER TABLE dbo.Booking ADD CONSTRAINT FK_Booking_CancellationReason
        FOREIGN KEY (CancellationReasonID) REFERENCES dbo.CancellationReason(CancellationReasonID);');

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Booking_CancelledByAccount')
    EXEC(N'ALTER TABLE dbo.Booking ADD CONSTRAINT FK_Booking_CancelledByAccount
        FOREIGN KEY (CancelledByAccountID) REFERENCES dbo.Account(AccountID);');

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Booking_CancelledByCustomer')
    EXEC(N'ALTER TABLE dbo.Booking ADD CONSTRAINT FK_Booking_CancelledByCustomer
        FOREIGN KEY (CancelledByCustomerID) REFERENCES dbo.Customer(CustomerID);');

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_Booking_CancelledByType'
)
    EXEC(N'ALTER TABLE dbo.Booking ADD CONSTRAINT CK_Booking_CancelledByType
        CHECK (CancelledByType IS NULL OR CancelledByType IN (''Customer'', ''Receptionist''));');

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Booking_Status_CancelledAt'
      AND object_id = OBJECT_ID(N'dbo.Booking')
)
    EXEC(N'CREATE INDEX IX_Booking_Status_CancelledAt
        ON dbo.Booking(Status, CancelledAt)
        INCLUDE (CancellationReasonID, RoomID);');

COMMIT TRANSACTION;
