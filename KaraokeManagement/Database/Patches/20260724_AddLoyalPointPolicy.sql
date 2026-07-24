SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.LoyalPointPolicy', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoyalPointPolicy (
        PolicyId INT IDENTITY(1,1) PRIMARY KEY,
        AmountPerPoint DECIMAL(18, 2) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_LoyalPointPolicy_IsActive DEFAULT 1,
        Description NVARCHAR(255) NULL
    );
END;

IF NOT EXISTS (SELECT 1 FROM dbo.LoyalPointPolicy)
BEGIN
    INSERT INTO dbo.LoyalPointPolicy (AmountPerPoint, IsActive, Description)
    VALUES (10000, 1, N'Quy đổi 10,000 VNĐ = 1 điểm tích lũy');
END;

DECLARE @ActivePolicyId INT = (
    SELECT TOP (1) PolicyId
    FROM dbo.LoyalPointPolicy
    WHERE IsActive = 1
    ORDER BY PolicyId
);

IF @ActivePolicyId IS NULL
BEGIN
    SELECT TOP (1) @ActivePolicyId = PolicyId
    FROM dbo.LoyalPointPolicy
    ORDER BY PolicyId;
END;

UPDATE dbo.LoyalPointPolicy
SET IsActive = CASE WHEN PolicyId = @ActivePolicyId THEN 1 ELSE 0 END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_LoyalPointPolicy_OneActive'
      AND object_id = OBJECT_ID(N'dbo.LoyalPointPolicy')
)
BEGIN
    CREATE UNIQUE INDEX UX_LoyalPointPolicy_OneActive
    ON dbo.LoyalPointPolicy(IsActive)
    WHERE IsActive = 1;
END;

COMMIT TRANSACTION;
