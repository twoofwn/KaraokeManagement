USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'KaraokeManagementDB')
BEGIN
    ALTER DATABASE KaraokeManagementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE KaraokeManagementDB;
END
GO

USE [master]
GO
/****** Object:  Database [KaraokeManagementDB]    Script Date: 7/22/2026 5:24:54 PM ******/
CREATE DATABASE [KaraokeManagementDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'KaraokeManagementDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\KaraokeManagementDB.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'KaraokeManagementDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\KaraokeManagementDB_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [KaraokeManagementDB] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [KaraokeManagementDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [KaraokeManagementDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [KaraokeManagementDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [KaraokeManagementDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET  ENABLE_BROKER 
GO
ALTER DATABASE [KaraokeManagementDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [KaraokeManagementDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET RECOVERY FULL 
GO
ALTER DATABASE [KaraokeManagementDB] SET  MULTI_USER 
GO
ALTER DATABASE [KaraokeManagementDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [KaraokeManagementDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [KaraokeManagementDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [KaraokeManagementDB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [KaraokeManagementDB] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [KaraokeManagementDB] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'KaraokeManagementDB', N'ON'
GO
ALTER DATABASE [KaraokeManagementDB] SET QUERY_STORE = ON
GO
ALTER DATABASE [KaraokeManagementDB] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [KaraokeManagementDB]
GO
/****** Object:  Table [dbo].[Account]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account](
	[AccountID] [int] IDENTITY(1,1) NOT NULL,
	[RoleID] [int] NOT NULL,
	[Username] [varchar](50) NOT NULL,
	[PasswordHash] [varchar](255) NOT NULL,
	[FullName] [nvarchar](100) NOT NULL,
	[Phone] [varchar](15) NULL,
	[Email] [varchar](100) NULL,
	[CreatedAt] [datetime] NULL,
	[DefaultShiftID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[AccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Attendance]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Attendance](
	[AttendanceID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NOT NULL,
	[ScheduleID] [int] NULL,
	[CheckInTime] [datetime] NOT NULL,
	[CheckOutTime] [datetime] NULL,
	[TotalHours] [decimal](5, 2) NULL,
	[Status] [nvarchar](30) NULL,
	[Note] [nvarchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[AttendanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Booking]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Booking](
	[BookingID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NOT NULL,
	[CreatedByID] [int] NOT NULL,
	[RoomID] [int] NOT NULL,
	[BookingTime] [datetime] NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[GuestCount] [int] NULL,
	[Note] [nvarchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[BookingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Category]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Category](
	[CategoryID] [int] IDENTITY(1,1) NOT NULL,
	[CategoryName] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Customer]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customer](
	[CustomerID] [int] IDENTITY(1,1) NOT NULL,
	[TierID] [int] NULL,
	[FullName] [nvarchar](100) NOT NULL,
	[Phone] [varchar](15) NOT NULL,
	[Email] [varchar](100) NULL,
	[LoyaltyPoints] [int] NULL,
	[CreatedAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CustomerAutomationRule]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerAutomationRule](
	[RuleID] [int] IDENTITY(1,1) NOT NULL,
	[RuleName] [nvarchar](100) NOT NULL,
	[EventType] [varchar](50) NOT NULL,
	[ActionPayload] [nvarchar](max) NOT NULL,
	[IsActive] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[RuleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CustomerCareLog]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerCareLog](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NOT NULL,
	[AccountID] [int] NOT NULL,
	[InteractionType] [nvarchar](50) NOT NULL,
	[Notes] [nvarchar](max) NOT NULL,
	[LoggedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CustomerReview]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerReview](
	[ReviewID] [int] IDENTITY(1,1) NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[StaffID] [int] NULL,
	[Rating] [int] NOT NULL,
	[Comment] [nvarchar](500) NULL,
	[CreatedAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ReviewID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmployeeProfile]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeProfile](
	[ProfileID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NOT NULL,
	[IdentityCardNumber] [varchar](20) NOT NULL,
	[DateOfBirth] [date] NULL,
	[Address] [nvarchar](255) NULL,
	[HireDate] [date] NOT NULL,
	[BaseHourlyRate] [decimal](18, 2) NULL,
	[EmploymentStatus] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ProfileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmployeeSchedule]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeSchedule](
	[ScheduleID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NOT NULL,
	[ShiftID] [int] NOT NULL,
	[WorkDate] [date] NOT NULL,
	[Status] [nvarchar](30) NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ScheduleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmployeeTask]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeTask](
	[TaskID] [int] IDENTITY(1,1) NOT NULL,
	[AssignedToID] [int] NOT NULL,
	[CreatedByID] [int] NOT NULL,
	[Title] [nvarchar](150) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[DueDate] [datetime] NOT NULL,
	[Status] [nvarchar](30) NULL,
PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Equipment]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Equipment](
	[EquipmentID] [int] IDENTITY(1,1) NOT NULL,
	[RoomID] [int] NOT NULL,
	[EquipmentName] [nvarchar](100) NOT NULL,
	[SerialNumber] [varchar](50) NULL,
	[PurchaseDate] [date] NULL,
	[Status] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[EquipmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Expense]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Expense](
	[ExpenseID] [int] IDENTITY(1,1) NOT NULL,
	[Category] [nvarchar](50) NOT NULL,
	[ExpenseDate] [date] NOT NULL,
	[Amount] [decimal](18, 2) NOT NULL,
	[Note] [nvarchar](255) NULL,
	[CreatedAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ExpenseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Invoice]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Invoice](
	[InvoiceID] [int] IDENTITY(1,1) NOT NULL,
	[BookingID] [int] NULL,
	[RoomID] [int] NOT NULL,
	[ReceptionistID] [int] NOT NULL,
	[PromotionID] [int] NULL,
	[CheckInTime] [datetime] NOT NULL,
	[CheckOutTime] [datetime] NULL,
	[RoomTotal] [decimal](18, 2) NULL,
	[ServiceTotal] [decimal](18, 2) NULL,
	[DiscountAmount] [decimal](18, 2) NULL,
	[GrandTotal] [decimal](18, 2) NULL,
	[Status] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[InvoiceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[InvoiceDetail]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceDetail](
	[InvoiceDetailID] [int] IDENTITY(1,1) NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[ServiceID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[InvoiceDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LeaveRequest]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaveRequest](
	[LeaveRequestId] [int] IDENTITY(1,1) NOT NULL,
	[AccountId] [int] NOT NULL,
	[ScheduleId] [int] NOT NULL,
	[Reason] [nvarchar](500) NOT NULL,
	[Status] [varchar](30) NOT NULL,
	[CreatedAt] [datetime] NULL,
	[ApprovedById] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[LeaveRequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MaintenanceLog]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaintenanceLog](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[EquipmentID] [int] NOT NULL,
	[ReportedByID] [int] NOT NULL,
	[IssueDescription] [nvarchar](255) NULL,
	[RepairCost] [decimal](18, 2) NULL,
	[LogDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MarketingCampaign]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MarketingCampaign](
	[CampaignID] [int] IDENTITY(1,1) NOT NULL,
	[PromotionID] [int] NULL,
	[CampaignName] [nvarchar](150) NOT NULL,
	[Channel] [varchar](30) NOT NULL,
	[TargetTierID] [int] NULL,
	[MessageTemplate] [nvarchar](max) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[Status] [nvarchar](30) NULL,
PRIMARY KEY CLUSTERED 
(
	[CampaignID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MembershipTier]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MembershipTier](
	[TierID] [int] IDENTITY(1,1) NOT NULL,
	[TierName] [nvarchar](50) NOT NULL,
	[DiscountPercent] [decimal](5, 2) NULL,
	[MinPoints] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[TierID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NotificationLog]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NotificationLog](
	[NotificationID] [int] IDENTITY(1,1) NOT NULL,
	[BookingID] [int] NULL,
	[CustomerID] [int] NOT NULL,
	[Channel] [varchar](20) NOT NULL,
	[Recipient] [varchar](100) NOT NULL,
	[MessageContent] [nvarchar](max) NOT NULL,
	[SentStatus] [varchar](20) NULL,
	[SentAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[NotificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PaymentMethod]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaymentMethod](
	[MethodID] [int] IDENTITY(1,1) NOT NULL,
	[MethodName] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MethodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PaymentTransaction]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaymentTransaction](
	[TransactionID] [int] IDENTITY(1,1) NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[MethodID] [int] NOT NULL,
	[Amount] [decimal](18, 2) NOT NULL,
	[TransactionDate] [datetime] NULL,
	[ReferenceCode] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[TransactionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Payroll]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payroll](
	[PayrollID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NOT NULL,
	[PayPeriodMonth] [int] NOT NULL,
	[PayPeriodYear] [int] NOT NULL,
	[BaseSalary] [decimal](18, 2) NOT NULL,
	[BonusAmount] [decimal](18, 2) NULL,
	[DeductionAmount] [decimal](18, 2) NULL,
	[NetSalary] [decimal](18, 2) NOT NULL,
	[PaymentStatus] [nvarchar](30) NULL,
	[PaymentDate] [datetime] NULL,
	[Note] [nvarchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[PayrollID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Promotion]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Promotion](
	[PromotionID] [int] IDENTITY(1,1) NOT NULL,
	[PromoCode] [varchar](20) NOT NULL,
	[PromoName] [nvarchar](100) NOT NULL,
	[DiscountPercent] [decimal](5, 2) NULL,
	[MaxDiscountAmount] [decimal](18, 2) NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PromotionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PurchaseOrder]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PurchaseOrder](
	[PO_ID] [int] IDENTITY(1,1) NOT NULL,
	[SupplierID] [int] NOT NULL,
	[CreatedByID] [int] NOT NULL,
	[OrderDate] [datetime] NULL,
	[TotalAmount] [decimal](18, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[PO_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PurchaseOrderDetail]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PurchaseOrderDetail](
	[PODetailID] [int] IDENTITY(1,1) NOT NULL,
	[PO_ID] [int] NOT NULL,
	[ServiceID] [int] NOT NULL,
	[ImportPrice] [decimal](18, 2) NOT NULL,
	[Quantity] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PODetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Role]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Role](
	[RoleID] [int] IDENTITY(1,1) NOT NULL,
	[RoleName] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RoleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Room]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Room](
	[RoomID] [int] IDENTITY(1,1) NOT NULL,
	[RoomTypeID] [int] NOT NULL,
	[RoomName] [nvarchar](50) NOT NULL,
	[Status] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[RoomID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RoomAssignment]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RoomAssignment](
	[RoomAssignmentId] [int] IDENTITY(1,1) NOT NULL,
	[RoomId] [int] NOT NULL,
	[ScheduleId] [int] NOT NULL,
	[AssignedAt] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RoomAssignmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RoomType]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RoomType](
	[RoomTypeID] [int] IDENTITY(1,1) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
	[PricePerHour] [decimal](18, 2) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[ImageURL] [nvarchar](500) NULL,
	[Capacity] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RoomTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ServiceItem]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ServiceItem](
	[ServiceID] [int] IDENTITY(1,1) NOT NULL,
	[CategoryID] [int] NOT NULL,
	[ServiceName] [nvarchar](100) NOT NULL,
	[SellingPrice] [decimal](18, 2) NOT NULL,
	[Unit] [nvarchar](20) NULL,
	[StockQuantity] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ServiceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ShiftSwapRequest]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ShiftSwapRequest](
	[SwapRequestId] [int] IDENTITY(1,1) NOT NULL,
	[RequesterId] [int] NOT NULL,
	[RequesterScheduleId] [int] NOT NULL,
	[TargetId] [int] NOT NULL,
	[TargetScheduleId] [int] NOT NULL,
	[Status] [varchar](30) NOT NULL,
	[CreatedAt] [datetime] NULL,
	[ApprovedById] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[SwapRequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Supplier]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Supplier](
	[SupplierID] [int] IDENTITY(1,1) NOT NULL,
	[SupplierName] [nvarchar](100) NOT NULL,
	[ContactName] [nvarchar](100) NULL,
	[Phone] [varchar](15) NULL,
	[Address] [nvarchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[SupplierID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TrainingRecord]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TrainingRecord](
	[TrainingID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NOT NULL,
	[CourseName] [nvarchar](150) NOT NULL,
	[CompletionDate] [date] NULL,
	[Result] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[TrainingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WorkShift]    Script Date: 7/22/2026 5:24:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkShift](
	[ShiftID] [int] IDENTITY(1,1) NOT NULL,
	[ShiftName] [nvarchar](50) NOT NULL,
	[StartTime] [time](7) NOT NULL,
	[EndTime] [time](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ShiftID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[Account] ON 

INSERT [dbo].[Account] ([AccountID], [RoleID], [Username], [PasswordHash], [FullName], [Phone], [Email], [CreatedAt], [DefaultShiftID]) VALUES (1, 1, N'admin_tong', N'hash1', N'Nguyễn Quản Trị', N'0900000001', N'admin@karaoke.com', CAST(N'2026-06-27T21:58:47.780' AS DateTime), NULL)
INSERT [dbo].[Account] ([AccountID], [RoleID], [Username], [PasswordHash], [FullName], [Phone], [Email], [CreatedAt], [DefaultShiftID]) VALUES (2, 2, N'quanly_hung', N'$2a$11$CjOg29A9Gm7.e/1W67beVOUlQOqmQpos88YYtFi7p3RhTwAFRrXy6', N'Trần Hùng (Quản Lý)', N'0900000002', N'hung@karaoke.com', CAST(N'2026-06-27T21:58:47.780' AS DateTime), NULL)
INSERT [dbo].[Account] ([AccountID], [RoleID], [Username], [PasswordHash], [FullName], [Phone], [Email], [CreatedAt], [DefaultShiftID]) VALUES (3, 3, N'letan_lan', N'hash3', N'Lê Thị Lan', N'0900000003', N'lan@karaoke.com', CAST(N'2026-06-27T21:58:47.780' AS DateTime), 1)
INSERT [dbo].[Account] ([AccountID], [RoleID], [Username], [PasswordHash], [FullName], [Phone], [Email], [CreatedAt], [DefaultShiftID]) VALUES (4, 3, N'letan_mai', N'hash4', N'Phạm Mai', N'0900000004', N'mai@karaoke.com', CAST(N'2026-06-27T21:58:47.780' AS DateTime), 2)
INSERT [dbo].[Account] ([AccountID], [RoleID], [Username], [PasswordHash], [FullName], [Phone], [Email], [CreatedAt], [DefaultShiftID]) VALUES (9, 3, N'servicestaff_c', N'123456', N'Hoàng Anh Em', N'0922334455', N'hoanganhe@gmail.com', CAST(N'2026-07-21T16:03:17.567' AS DateTime), 3)
INSERT [dbo].[Account] ([AccountID], [RoleID], [Username], [PasswordHash], [FullName], [Phone], [Email], [CreatedAt], [DefaultShiftID]) VALUES (11, 7, N'service1', N'$2a$11$HVndyctqKCNvh4i.ViA3K.BL3A1LGNTOT9x4NK5gP7GPodRnUHUsi', N'Nguyễn Phục Vụ 1', N'0912345601', N'service1@karaoke.com', CAST(N'2026-07-22T15:47:51.053' AS DateTime), 1)
INSERT [dbo].[Account] ([AccountID], [RoleID], [Username], [PasswordHash], [FullName], [Phone], [Email], [CreatedAt], [DefaultShiftID]) VALUES (12, 7, N'service2', N'$2a$11$V3ktyWiSuJelX/m6bTDLVOT5q1kcy4lNE3UE3vlnd9zP8hXbtDU2C', N'Trần Phục Vụ 2', N'0912345602', N'service2@karaoke.com', CAST(N'2026-07-22T15:47:51.053' AS DateTime), 2)
INSERT [dbo].[Account] ([AccountID], [RoleID], [Username], [PasswordHash], [FullName], [Phone], [Email], [CreatedAt], [DefaultShiftID]) VALUES (13, 7, N'service3', N'$2a$11$XejQsKYIfIpXWWCnydOAEuklMK5pCDt6ZeXUEYQ63/UDhdAxCvE/S', N'Lê Phục Vụ 3', N'0912345603', N'service3@karaoke.com', CAST(N'2026-07-22T15:47:51.053' AS DateTime), 3)
INSERT [dbo].[Account] ([AccountID], [RoleID], [Username], [PasswordHash], [FullName], [Phone], [Email], [CreatedAt], [DefaultShiftID]) VALUES (14, 7, N'service4', N'hash1', N'Phạm Phục Vụ 4', N'0912345604', N'service4@karaoke.com', CAST(N'2026-07-22T15:47:51.053' AS DateTime), 1)
SET IDENTITY_INSERT [dbo].[Account] OFF
GO
SET IDENTITY_INSERT [dbo].[Attendance] ON 

INSERT [dbo].[Attendance] ([AttendanceID], [AccountID], [ScheduleID], [CheckInTime], [CheckOutTime], [TotalHours], [Status], [Note]) VALUES (1, 1, 1, CAST(N'2026-07-21T08:00:00.000' AS DateTime), CAST(N'2026-07-21T16:00:00.000' AS DateTime), CAST(8.00 AS Decimal(5, 2)), N'OnTime', N'Äi Ä‘Ãºng giá»')
INSERT [dbo].[Attendance] ([AttendanceID], [AccountID], [ScheduleID], [CheckInTime], [CheckOutTime], [TotalHours], [Status], [Note]) VALUES (2, 3, 2, CAST(N'2026-07-21T16:00:00.000' AS DateTime), NULL, NULL, N'OnTime', NULL)
SET IDENTITY_INSERT [dbo].[Attendance] OFF
GO
SET IDENTITY_INSERT [dbo].[Booking] ON 

INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (1, 1, 3, 5, CAST(N'2026-06-24T21:58:47.787' AS DateTime), CAST(N'2026-06-25T21:58:47.787' AS DateTime), CAST(N'2026-06-26T01:58:47.787' AS DateTime), N'Completed', 4, N'KhÃ¡ch gá»i Ä‘áº·t trÆ°á»›c')
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (2, 2, 4, 8, CAST(N'2026-06-26T21:58:47.787' AS DateTime), CAST(N'2026-06-26T21:58:47.787' AS DateTime), CAST(N'2026-06-27T00:58:47.787' AS DateTime), N'Completed', 10, N'Sinh nháº­t')
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (3, 3, 3, 4, CAST(N'2026-06-27T21:58:47.787' AS DateTime), CAST(N'2026-06-27T21:58:47.787' AS DateTime), CAST(N'2026-06-27T23:58:47.787' AS DateTime), N'CheckedIn', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (4, 1, 3, 1, CAST(N'2026-06-12T21:58:47.793' AS DateTime), CAST(N'2026-06-13T21:58:47.793' AS DateTime), CAST(N'2026-06-13T23:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (5, 2, 3, 2, CAST(N'2026-06-13T21:58:47.793' AS DateTime), CAST(N'2026-06-14T21:58:47.793' AS DateTime), CAST(N'2026-06-15T00:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (6, 3, 4, 4, CAST(N'2026-06-14T21:58:47.793' AS DateTime), CAST(N'2026-06-15T21:58:47.793' AS DateTime), CAST(N'2026-06-15T23:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (7, 4, 4, 5, CAST(N'2026-06-15T21:58:47.793' AS DateTime), CAST(N'2026-06-16T21:58:47.793' AS DateTime), CAST(N'2026-06-17T01:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (8, 5, 3, 6, CAST(N'2026-06-16T21:58:47.793' AS DateTime), CAST(N'2026-06-17T21:58:47.793' AS DateTime), CAST(N'2026-06-18T02:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (9, 1, 3, 7, CAST(N'2026-06-17T21:58:47.793' AS DateTime), CAST(N'2026-06-18T21:58:47.793' AS DateTime), CAST(N'2026-06-18T23:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (10, 2, 4, 8, CAST(N'2026-06-18T21:58:47.793' AS DateTime), CAST(N'2026-06-19T21:58:47.793' AS DateTime), CAST(N'2026-06-20T00:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (11, 3, 4, 9, CAST(N'2026-06-19T21:58:47.793' AS DateTime), CAST(N'2026-06-20T21:58:47.793' AS DateTime), CAST(N'2026-06-21T01:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (12, 4, 3, 10, CAST(N'2026-06-20T21:58:47.793' AS DateTime), CAST(N'2026-06-21T21:58:47.793' AS DateTime), CAST(N'2026-06-21T23:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (13, 5, 3, 1, CAST(N'2026-06-21T21:58:47.793' AS DateTime), CAST(N'2026-06-22T21:58:47.793' AS DateTime), CAST(N'2026-06-23T00:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (14, 1, 4, 2, CAST(N'2026-06-22T21:58:47.793' AS DateTime), CAST(N'2026-06-23T21:58:47.793' AS DateTime), CAST(N'2026-06-23T23:58:47.793' AS DateTime), N'Completed', NULL, NULL)
INSERT [dbo].[Booking] ([BookingID], [CustomerID], [CreatedByID], [RoomID], [BookingTime], [StartTime], [EndTime], [Status], [GuestCount], [Note]) VALUES (15, 2, 4, 5, CAST(N'2026-06-23T21:58:47.793' AS DateTime), CAST(N'2026-06-24T21:58:47.793' AS DateTime), CAST(N'2026-06-25T01:58:47.793' AS DateTime), N'Completed', NULL, NULL)
SET IDENTITY_INSERT [dbo].[Booking] OFF
GO
SET IDENTITY_INSERT [dbo].[Category] ON 

INSERT [dbo].[Category] ([CategoryID], [CategoryName]) VALUES (1, N'Đồ Uống')
INSERT [dbo].[Category] ([CategoryID], [CategoryName]) VALUES (2, N'Đồ Ăn')
INSERT [dbo].[Category] ([CategoryID], [CategoryName]) VALUES (3, N'Trái Cây')
INSERT [dbo].[Category] ([CategoryID], [CategoryName]) VALUES (4, N'Đồ Ăn')
INSERT [dbo].[Category] ([CategoryID], [CategoryName]) VALUES (5, N'Trái Cây')
INSERT [dbo].[Category] ([CategoryID], [CategoryName]) VALUES (6, N'Combo')
SET IDENTITY_INSERT [dbo].[Category] OFF
GO
SET IDENTITY_INSERT [dbo].[Customer] ON 

INSERT [dbo].[Customer] ([CustomerID], [TierID], [FullName], [Phone], [Email], [LoyaltyPoints], [CreatedAt]) VALUES (1, 5, N'Lê Minh Tuấn (VIP)', N'0911111111', N'tuanvip@gmail.com', 16500, CAST(N'2026-06-27T21:58:47.783' AS DateTime))
INSERT [dbo].[Customer] ([CustomerID], [TierID], [FullName], [Phone], [Email], [LoyaltyPoints], [CreatedAt]) VALUES (2, 4, N'Nguyễn Việt Hoàng', N'0922222222', N'hoangnv@gmail.com', 8200, CAST(N'2026-06-27T21:58:47.783' AS DateTime))
INSERT [dbo].[Customer] ([CustomerID], [TierID], [FullName], [Phone], [Email], [LoyaltyPoints], [CreatedAt]) VALUES (3, 3, N'Trần Tiến Dũng', N'0933333333', N'dungtt@gmail.com', 3500, CAST(N'2026-06-27T21:58:47.783' AS DateTime))
INSERT [dbo].[Customer] ([CustomerID], [TierID], [FullName], [Phone], [Email], [LoyaltyPoints], [CreatedAt]) VALUES (4, 2, N'Phạm Thu Thủy', N'0944444444', N'thuypham@gmail.com', 1200, CAST(N'2026-06-27T21:58:47.783' AS DateTime))
INSERT [dbo].[Customer] ([CustomerID], [TierID], [FullName], [Phone], [Email], [LoyaltyPoints], [CreatedAt]) VALUES (5, 1, N'Đinh Thanh Hà', N'0955555555', N'hadinh@gmail.com', 150, CAST(N'2026-06-27T21:58:47.783' AS DateTime))
INSERT [dbo].[Customer] ([CustomerID], [TierID], [FullName], [Phone], [Email], [LoyaltyPoints], [CreatedAt]) VALUES (6, 1, N'Khách Vãng Lai', N'0000000000', N'', 0, CAST(N'2026-06-27T21:58:47.783' AS DateTime))
SET IDENTITY_INSERT [dbo].[Customer] OFF
GO
SET IDENTITY_INSERT [dbo].[CustomerAutomationRule] ON 

INSERT [dbo].[CustomerAutomationRule] ([RuleID], [RuleName], [EventType], [ActionPayload], [IsActive]) VALUES (1, N'Tá»± Ä‘á»™ng lÃªn háº¡ng', N'OnPointsEarned', N'{"Threshold": 1000, "NewTier": 2}', 1)
INSERT [dbo].[CustomerAutomationRule] ([RuleID], [RuleName], [EventType], [ActionPayload], [IsActive]) VALUES (2, N'ChÃºc má»«ng sinh nháº­t', N'OnBirthday', N'{"TemplateID": 1, "Discount": 20}', 1)
SET IDENTITY_INSERT [dbo].[CustomerAutomationRule] OFF
GO
SET IDENTITY_INSERT [dbo].[CustomerCareLog] ON 

INSERT [dbo].[CustomerCareLog] ([LogID], [CustomerID], [AccountID], [InteractionType], [Notes], [LoggedDate]) VALUES (1, 1, 1, N'Gá»i Ä‘iá»‡n thoáº¡i', N'Há»i thÄƒm sá»± hÃ i lÃ²ng vá» dá»‹ch vá»¥ sinh nháº­t tá»‘i qua', CAST(N'2026-07-21T15:07:43.950' AS DateTime))
INSERT [dbo].[CustomerCareLog] ([LogID], [CustomerID], [AccountID], [InteractionType], [Notes], [LoggedDate]) VALUES (2, 2, 3, N'Nháº¯n tin', N'Gá»­i thÃ´ng bÃ¡o chÆ°Æ¡ng trÃ¬nh khuyáº¿n mÃ£i', CAST(N'2026-07-21T15:07:43.950' AS DateTime))
SET IDENTITY_INSERT [dbo].[CustomerCareLog] OFF
GO
SET IDENTITY_INSERT [dbo].[CustomerReview] ON 

INSERT [dbo].[CustomerReview] ([ReviewID], [InvoiceID], [CustomerID], [StaffID], [Rating], [Comment], [CreatedAt]) VALUES (1, 1, 1, 3, 5, N'PhÃ²ng Ä‘áº¹p, Ã¢m thanh hay, phá»¥c vá»¥ tá»‘t', CAST(N'2026-07-21T15:07:43.950' AS DateTime))
INSERT [dbo].[CustomerReview] ([ReviewID], [InvoiceID], [CustomerID], [StaffID], [Rating], [Comment], [CreatedAt]) VALUES (2, 2, 2, 4, 4, N'Má»“i ngon, nhÆ°ng gá»i bia hÆ¡i cháº­m', CAST(N'2026-07-21T15:07:43.950' AS DateTime))
SET IDENTITY_INSERT [dbo].[CustomerReview] OFF
GO
SET IDENTITY_INSERT [dbo].[EmployeeProfile] ON 

INSERT [dbo].[EmployeeProfile] ([ProfileID], [AccountID], [IdentityCardNumber], [DateOfBirth], [Address], [HireDate], [BaseHourlyRate], [EmploymentStatus]) VALUES (1, 1, N'001090123456', CAST(N'1990-05-15' AS Date), N'123 Đường A, Quận 1, TP.HCM', CAST(N'2022-01-10' AS Date), CAST(35000.00 AS Decimal(18, 2)), N'Active')
INSERT [dbo].[EmployeeProfile] ([ProfileID], [AccountID], [IdentityCardNumber], [DateOfBirth], [Address], [HireDate], [BaseHourlyRate], [EmploymentStatus]) VALUES (2, 3, N'079095654321', CAST(N'1995-10-20' AS Date), N'456 Đường B, Quận 3, TP.HCM', CAST(N'2023-03-01' AS Date), CAST(30000.00 AS Decimal(18, 2)), N'Active')
INSERT [dbo].[EmployeeProfile] ([ProfileID], [AccountID], [IdentityCardNumber], [DateOfBirth], [Address], [HireDate], [BaseHourlyRate], [EmploymentStatus]) VALUES (7, 9, N'052094556677', CAST(N'1997-01-30' AS Date), N'12 Cần Thơ, Ninh Kiều', CAST(N'2023-05-12' AS Date), CAST(35000.00 AS Decimal(18, 2)), N'Resigned')
SET IDENTITY_INSERT [dbo].[EmployeeProfile] OFF
GO
SET IDENTITY_INSERT [dbo].[EmployeeSchedule] ON 

INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (1, 1, 1, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (2, 3, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (6, 3, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (7, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (8, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (9, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (10, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (11, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (12, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (13, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (14, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (15, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (16, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (17, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (18, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (19, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (20, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (21, 1, 1, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (22, 4, 2, CAST(N'2026-07-20' AS Date), N'Off', 0)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (23, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (24, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (25, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (26, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (27, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (28, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (29, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (30, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (31, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (32, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (33, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (34, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (35, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (36, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (37, 1, 2, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (38, 3, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (39, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (40, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (41, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (42, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (43, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (44, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (45, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (46, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (47, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (48, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (49, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (50, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (51, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (52, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (53, 1, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (55, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (56, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (57, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (58, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (59, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (60, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (61, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (62, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (63, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (64, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (65, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (66, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (67, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (68, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (69, 1, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (70, 3, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (71, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (72, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (73, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (74, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (75, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (76, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (77, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (78, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (79, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (80, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (81, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (82, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (83, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (84, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (85, 1, 1, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (86, 4, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (87, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (88, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (89, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (90, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (91, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (92, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (93, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (94, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (95, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (96, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (97, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (98, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (99, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (100, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (101, 1, 2, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (104, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (105, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
GO
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (106, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (107, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (108, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (109, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (110, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (111, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (112, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (113, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (114, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (115, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (116, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (117, 1, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (118, 4, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (119, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (120, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (121, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (122, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (123, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (124, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (125, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (126, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (127, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (128, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (129, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (130, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (131, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (132, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (133, 1, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (134, 3, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (135, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (136, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (137, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (138, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (139, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (140, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (141, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (142, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (143, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (144, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (145, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (146, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (147, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (148, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (149, 1, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (150, 4, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (151, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (152, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (153, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (154, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (155, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (156, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (157, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (158, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (159, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (160, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (161, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (162, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (163, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (164, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (165, 1, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (166, 3, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (167, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (168, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (169, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (170, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (171, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (172, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (173, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (174, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (175, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (176, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (177, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (178, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (179, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (180, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (181, 1, 1, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (182, 4, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (183, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (184, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (185, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (186, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (187, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (188, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (189, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (190, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (191, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (192, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (193, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (194, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (195, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (196, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (197, 1, 2, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (198, 3, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (199, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (200, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (201, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (202, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (203, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (204, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (205, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
GO
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (206, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (207, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (208, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (209, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (210, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (211, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (212, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (213, 1, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (214, 4, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (215, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (216, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (217, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (218, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (219, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (220, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (221, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (222, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (223, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (224, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (225, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (226, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (227, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (228, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (229, 1, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (230, 3, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (231, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (232, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (233, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (234, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (235, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (236, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (237, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (238, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (239, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (240, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (241, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (242, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (243, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (244, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (245, 1, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (246, 4, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (247, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (248, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (249, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (250, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (251, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (252, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (253, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (254, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (255, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (256, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (257, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (258, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (259, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (260, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (261, 1, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (262, 3, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (263, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (264, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (265, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (266, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (267, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (268, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (269, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (270, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (271, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (272, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (273, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (274, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (275, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (276, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (277, 1, 1, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (278, 4, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (279, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (280, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (281, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (282, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (283, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (284, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (285, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (286, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (287, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (288, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (289, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (290, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (291, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (292, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (293, 1, 2, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (294, 3, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (295, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (296, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (297, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (298, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (299, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (300, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (301, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (302, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (303, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (304, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (305, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
GO
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (306, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (307, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (308, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (309, 1, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (314, 9, 3, CAST(N'2026-07-20' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (317, 4, 2, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (325, 9, 3, CAST(N'2026-07-22' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (326, 3, 1, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (329, 4, 2, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (332, 9, 3, CAST(N'2026-07-23' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (337, 9, 3, CAST(N'2026-07-24' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (338, 3, 1, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (341, 4, 2, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (344, 9, 3, CAST(N'2026-07-25' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (349, 9, 3, CAST(N'2026-07-26' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (350, 4, 1, CAST(N'2026-07-21' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (351, 3, 1, CAST(N'2026-07-27' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (352, 4, 2, CAST(N'2026-07-27' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (353, 9, 3, CAST(N'2026-07-27' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (354, 3, 1, CAST(N'2026-07-28' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (355, 4, 2, CAST(N'2026-07-28' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (356, 9, 3, CAST(N'2026-07-28' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (357, 3, 1, CAST(N'2026-07-29' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (358, 4, 2, CAST(N'2026-07-29' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (359, 9, 3, CAST(N'2026-07-29' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (360, 3, 1, CAST(N'2026-07-30' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (361, 4, 2, CAST(N'2026-07-30' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (362, 9, 3, CAST(N'2026-07-30' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (363, 3, 1, CAST(N'2026-07-31' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (364, 4, 2, CAST(N'2026-07-31' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (365, 9, 3, CAST(N'2026-07-31' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (366, 3, 1, CAST(N'2026-08-01' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (367, 4, 2, CAST(N'2026-08-01' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (368, 9, 3, CAST(N'2026-08-01' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (369, 3, 1, CAST(N'2026-08-02' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (370, 4, 2, CAST(N'2026-08-02' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (371, 9, 3, CAST(N'2026-08-02' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (372, 3, 1, CAST(N'2026-08-03' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (373, 11, 1, CAST(N'2026-08-03' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (374, 14, 1, CAST(N'2026-08-03' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (375, 4, 2, CAST(N'2026-08-03' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (376, 12, 2, CAST(N'2026-08-03' AS Date), N'Off', 0)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (377, 9, 3, CAST(N'2026-08-03' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (378, 13, 3, CAST(N'2026-08-03' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (379, 3, 1, CAST(N'2026-08-04' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (380, 11, 1, CAST(N'2026-08-04' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (381, 14, 1, CAST(N'2026-08-04' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (382, 4, 2, CAST(N'2026-08-04' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (383, 12, 2, CAST(N'2026-08-04' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (384, 9, 3, CAST(N'2026-08-04' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (385, 13, 3, CAST(N'2026-08-04' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (386, 3, 1, CAST(N'2026-08-05' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (387, 11, 1, CAST(N'2026-08-05' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (388, 14, 1, CAST(N'2026-08-05' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (389, 4, 2, CAST(N'2026-08-05' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (390, 12, 2, CAST(N'2026-08-05' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (391, 9, 3, CAST(N'2026-08-05' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (392, 13, 3, CAST(N'2026-08-05' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (393, 3, 1, CAST(N'2026-08-06' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (394, 11, 1, CAST(N'2026-08-06' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (395, 14, 1, CAST(N'2026-08-06' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (396, 4, 2, CAST(N'2026-08-06' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (397, 12, 2, CAST(N'2026-08-06' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (398, 9, 3, CAST(N'2026-08-06' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (399, 13, 3, CAST(N'2026-08-06' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (400, 3, 1, CAST(N'2026-08-07' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (401, 11, 1, CAST(N'2026-08-07' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (402, 14, 1, CAST(N'2026-08-07' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (403, 4, 2, CAST(N'2026-08-07' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (404, 12, 2, CAST(N'2026-08-07' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (405, 9, 3, CAST(N'2026-08-07' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (406, 13, 3, CAST(N'2026-08-07' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (407, 3, 1, CAST(N'2026-08-08' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (408, 11, 1, CAST(N'2026-08-08' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (409, 14, 1, CAST(N'2026-08-08' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (410, 4, 2, CAST(N'2026-08-08' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (411, 12, 2, CAST(N'2026-08-08' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (412, 9, 3, CAST(N'2026-08-08' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (413, 13, 3, CAST(N'2026-08-08' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (414, 3, 1, CAST(N'2026-08-09' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (415, 11, 1, CAST(N'2026-08-09' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (416, 14, 1, CAST(N'2026-08-09' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (417, 4, 2, CAST(N'2026-08-09' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (418, 12, 2, CAST(N'2026-08-09' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (419, 9, 3, CAST(N'2026-08-09' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (420, 13, 3, CAST(N'2026-08-09' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (421, 3, 1, CAST(N'2026-08-10' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (422, 4, 2, CAST(N'2026-08-10' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (423, 9, 3, CAST(N'2026-08-10' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (424, 11, 1, CAST(N'2026-08-10' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (425, 12, 2, CAST(N'2026-08-10' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (426, 13, 3, CAST(N'2026-08-10' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (427, 14, 1, CAST(N'2026-08-10' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (428, 3, 1, CAST(N'2026-08-11' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (429, 4, 2, CAST(N'2026-08-11' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (430, 9, 3, CAST(N'2026-08-11' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (431, 11, 1, CAST(N'2026-08-11' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (432, 12, 2, CAST(N'2026-08-11' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (433, 13, 3, CAST(N'2026-08-11' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (434, 14, 1, CAST(N'2026-08-11' AS Date), N'Scheduled', 1)
GO
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (435, 3, 1, CAST(N'2026-08-12' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (436, 4, 2, CAST(N'2026-08-12' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (437, 9, 3, CAST(N'2026-08-12' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (438, 11, 1, CAST(N'2026-08-12' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (439, 12, 2, CAST(N'2026-08-12' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (440, 13, 3, CAST(N'2026-08-12' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (441, 14, 1, CAST(N'2026-08-12' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (442, 3, 1, CAST(N'2026-08-13' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (443, 4, 2, CAST(N'2026-08-13' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (444, 9, 3, CAST(N'2026-08-13' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (445, 11, 1, CAST(N'2026-08-13' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (446, 12, 2, CAST(N'2026-08-13' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (447, 13, 3, CAST(N'2026-08-13' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (448, 14, 1, CAST(N'2026-08-13' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (449, 3, 1, CAST(N'2026-08-14' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (450, 4, 2, CAST(N'2026-08-14' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (451, 9, 3, CAST(N'2026-08-14' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (452, 11, 1, CAST(N'2026-08-14' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (453, 12, 2, CAST(N'2026-08-14' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (454, 13, 3, CAST(N'2026-08-14' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (455, 14, 1, CAST(N'2026-08-14' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (456, 3, 1, CAST(N'2026-08-15' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (457, 4, 2, CAST(N'2026-08-15' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (458, 9, 3, CAST(N'2026-08-15' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (459, 11, 1, CAST(N'2026-08-15' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (460, 12, 2, CAST(N'2026-08-15' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (461, 13, 3, CAST(N'2026-08-15' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (462, 14, 1, CAST(N'2026-08-15' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (463, 3, 1, CAST(N'2026-08-16' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (464, 4, 2, CAST(N'2026-08-16' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (465, 9, 3, CAST(N'2026-08-16' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (466, 11, 1, CAST(N'2026-08-16' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (467, 12, 2, CAST(N'2026-08-16' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (468, 13, 3, CAST(N'2026-08-16' AS Date), N'Scheduled', 1)
INSERT [dbo].[EmployeeSchedule] ([ScheduleID], [AccountID], [ShiftID], [WorkDate], [Status], [IsActive]) VALUES (469, 14, 1, CAST(N'2026-08-16' AS Date), N'Scheduled', 1)
SET IDENTITY_INSERT [dbo].[EmployeeSchedule] OFF
GO
SET IDENTITY_INSERT [dbo].[EmployeeTask] ON 

INSERT [dbo].[EmployeeTask] ([TaskID], [AssignedToID], [CreatedByID], [Title], [Description], [DueDate], [Status]) VALUES (1, 3, 1, N'Dá»n dáº¹p phÃ²ng VIP 1', N'Lau chÃ¹i bÃ n gháº¿, kiá»ƒm tra micro', CAST(N'2026-07-21T17:07:43.947' AS DateTime), N'Pending')
INSERT [dbo].[EmployeeTask] ([TaskID], [AssignedToID], [CreatedByID], [Title], [Description], [DueDate], [Status]) VALUES (2, 4, 1, N'Kiá»ƒm kÃª kho bia', N'Äáº¿m sá»‘ lÆ°á»£ng bia Tiger vÃ  Heineken', CAST(N'2026-07-22T15:07:43.947' AS DateTime), N'InProgress')
SET IDENTITY_INSERT [dbo].[EmployeeTask] OFF
GO
SET IDENTITY_INSERT [dbo].[Equipment] ON 

INSERT [dbo].[Equipment] ([EquipmentID], [RoomID], [EquipmentName], [SerialNumber], [PurchaseDate], [Status]) VALUES (1, 5, N'Tivi Samsung 65 Inch', N'SS-65-001', CAST(N'2023-01-15' AS Date), N'Good')
INSERT [dbo].[Equipment] ([EquipmentID], [RoomID], [EquipmentName], [SerialNumber], [PurchaseDate], [Status]) VALUES (2, 5, N'Micro Shure', N'SH-001', CAST(N'2023-01-15' AS Date), N'Good')
INSERT [dbo].[Equipment] ([EquipmentID], [RoomID], [EquipmentName], [SerialNumber], [PurchaseDate], [Status]) VALUES (3, 6, N'Micro Shure', N'SH-003', CAST(N'2023-01-15' AS Date), N'Broken')
INSERT [dbo].[Equipment] ([EquipmentID], [RoomID], [EquipmentName], [SerialNumber], [PurchaseDate], [Status]) VALUES (4, 8, N'Loa JBL', N'JBL-001', CAST(N'2023-05-20' AS Date), N'Good')
INSERT [dbo].[Equipment] ([EquipmentID], [RoomID], [EquipmentName], [SerialNumber], [PurchaseDate], [Status]) VALUES (5, 3, N'Điều hòa Panasonic', N'PN-AC-001', CAST(N'2022-10-10' AS Date), N'Repairing')
SET IDENTITY_INSERT [dbo].[Equipment] OFF
GO
SET IDENTITY_INSERT [dbo].[Expense] ON 

INSERT [dbo].[Expense] ([ExpenseID], [Category], [ExpenseDate], [Amount], [Note], [CreatedAt]) VALUES (1, N'dien', CAST(N'2023-10-15' AS Date), CAST(5400000.00 AS Decimal(18, 2)), N'Tiền điện tháng 9/2023', CAST(N'2026-06-27T21:58:47.790' AS DateTime))
INSERT [dbo].[Expense] ([ExpenseID], [Category], [ExpenseDate], [Amount], [Note], [CreatedAt]) VALUES (2, N'baotri', CAST(N'2023-10-14' AS Date), CAST(2100000.00 AS Decimal(18, 2)), N'Sửa mic phòng VIP 1 & 2', CAST(N'2026-06-27T21:58:47.790' AS DateTime))
INSERT [dbo].[Expense] ([ExpenseID], [Category], [ExpenseDate], [Amount], [Note], [CreatedAt]) VALUES (3, N'matbang', CAST(N'2023-10-01' AS Date), CAST(25000000.00 AS Decimal(18, 2)), N'Thuê mặt bằng tháng 10', CAST(N'2026-06-27T21:58:47.790' AS DateTime))
INSERT [dbo].[Expense] ([ExpenseID], [Category], [ExpenseDate], [Amount], [Note], [CreatedAt]) VALUES (4, N'nuoc', CAST(N'2023-09-28' AS Date), CAST(850000.00 AS Decimal(18, 2)), N'Tiền nước T9', CAST(N'2026-06-27T21:58:47.790' AS DateTime))
INSERT [dbo].[Expense] ([ExpenseID], [Category], [ExpenseDate], [Amount], [Note], [CreatedAt]) VALUES (5, N'khac', CAST(N'2026-07-01' AS Date), CAST(1000.00 AS Decimal(18, 2)), N'Tiền nợ', CAST(N'2026-07-12T22:34:27.037' AS DateTime))
SET IDENTITY_INSERT [dbo].[Expense] OFF
GO
SET IDENTITY_INSERT [dbo].[Invoice] ON 

INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (1, 1, 5, 3, 2, CAST(N'2026-06-25T21:58:47.787' AS DateTime), CAST(N'2026-06-26T01:58:47.787' AS DateTime), CAST(1200000.00 AS Decimal(18, 2)), CAST(2750000.00 AS Decimal(18, 2)), CAST(790000.00 AS Decimal(18, 2)), CAST(3160000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (2, 2, 8, 3, 1, CAST(N'2026-06-26T21:58:47.787' AS DateTime), CAST(N'2026-06-27T00:58:47.787' AS DateTime), CAST(1800000.00 AS Decimal(18, 2)), CAST(1500000.00 AS Decimal(18, 2)), CAST(500000.00 AS Decimal(18, 2)), CAST(2800000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (3, 3, 4, 4, 2, CAST(N'2026-06-27T21:58:47.787' AS DateTime), NULL, CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), N'Unpaid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (4, 4, 1, 3, 2, CAST(N'2026-06-13T21:58:47.793' AS DateTime), CAST(N'2026-06-13T23:58:47.793' AS DateTime), CAST(300000.00 AS Decimal(18, 2)), CAST(140000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(440000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (5, 5, 2, 3, 2, CAST(N'2026-06-14T21:58:47.793' AS DateTime), CAST(N'2026-06-15T00:58:47.793' AS DateTime), CAST(450000.00 AS Decimal(18, 2)), CAST(80000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(530000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (6, 6, 4, 4, 2, CAST(N'2026-06-15T21:58:47.793' AS DateTime), CAST(N'2026-06-15T23:58:47.793' AS DateTime), CAST(240000.00 AS Decimal(18, 2)), CAST(190000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(430000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (7, 7, 5, 4, 2, CAST(N'2026-06-16T21:58:47.793' AS DateTime), CAST(N'2026-06-17T01:58:47.793' AS DateTime), CAST(1200000.00 AS Decimal(18, 2)), CAST(490000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(1690000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (8, 8, 6, 3, 2, CAST(N'2026-06-17T21:58:47.793' AS DateTime), CAST(N'2026-06-18T02:58:47.793' AS DateTime), CAST(1500000.00 AS Decimal(18, 2)), CAST(700000.00 AS Decimal(18, 2)), CAST(150000.00 AS Decimal(18, 2)), CAST(2050000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (9, 9, 7, 3, 2, CAST(N'2026-06-18T21:58:47.793' AS DateTime), CAST(N'2026-06-18T23:58:47.793' AS DateTime), CAST(600000.00 AS Decimal(18, 2)), CAST(300000.00 AS Decimal(18, 2)), CAST(90000.00 AS Decimal(18, 2)), CAST(810000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (10, 10, 8, 4, 2, CAST(N'2026-06-19T21:58:47.793' AS DateTime), CAST(N'2026-06-20T00:58:47.793' AS DateTime), CAST(1800000.00 AS Decimal(18, 2)), CAST(1500000.00 AS Decimal(18, 2)), CAST(330000.00 AS Decimal(18, 2)), CAST(2970000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (11, 11, 9, 4, 2, CAST(N'2026-06-20T21:58:47.793' AS DateTime), CAST(N'2026-06-21T01:58:47.793' AS DateTime), CAST(2400000.00 AS Decimal(18, 2)), CAST(1500000.00 AS Decimal(18, 2)), CAST(390000.00 AS Decimal(18, 2)), CAST(3510000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (12, 12, 10, 3, 2, CAST(N'2026-06-21T21:58:47.793' AS DateTime), CAST(N'2026-06-21T23:58:47.793' AS DateTime), CAST(300000.00 AS Decimal(18, 2)), CAST(100000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(400000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (13, 13, 1, 3, 2, CAST(N'2026-06-22T21:58:47.793' AS DateTime), CAST(N'2026-06-23T00:58:47.793' AS DateTime), CAST(450000.00 AS Decimal(18, 2)), CAST(260000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(710000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (14, 14, 2, 4, 2, CAST(N'2026-06-23T21:58:47.793' AS DateTime), CAST(N'2026-06-23T23:58:47.793' AS DateTime), CAST(300000.00 AS Decimal(18, 2)), CAST(140000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(440000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (15, 15, 5, 4, 2, CAST(N'2026-06-24T21:58:47.793' AS DateTime), CAST(N'2026-06-25T01:58:47.793' AS DateTime), CAST(1200000.00 AS Decimal(18, 2)), CAST(600000.00 AS Decimal(18, 2)), CAST(180000.00 AS Decimal(18, 2)), CAST(1620000.00 AS Decimal(18, 2)), N'Paid')
INSERT [dbo].[Invoice] ([InvoiceID], [BookingID], [RoomID], [ReceptionistID], [PromotionID], [CheckInTime], [CheckOutTime], [RoomTotal], [ServiceTotal], [DiscountAmount], [GrandTotal], [Status]) VALUES (16, NULL, 6, 1, NULL, CAST(N'2026-06-28T06:58:21.677' AS DateTime), NULL, CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), N'Unpaid')
SET IDENTITY_INSERT [dbo].[Invoice] OFF
GO
SET IDENTITY_INSERT [dbo].[InvoiceDetail] ON 

INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (1, 1, 3, 1, CAST(1500000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (2, 1, 6, 2, CAST(350000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (3, 1, 5, 2, CAST(150000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (4, 2, 7, 1, CAST(1500000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (5, 2, 2, 24, CAST(30000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (6, 4, 1, 3, CAST(40000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (7, 4, 4, 1, CAST(20000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (8, 5, 2, 2, CAST(30000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (9, 5, 4, 1, CAST(20000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (10, 6, 5, 1, CAST(150000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (11, 6, 1, 1, CAST(40000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (12, 7, 6, 1, CAST(350000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (13, 7, 1, 3, CAST(40000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (14, 7, 4, 1, CAST(20000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (15, 8, 6, 2, CAST(350000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (16, 9, 5, 2, CAST(150000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (17, 10, 7, 1, CAST(1500000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (18, 11, 3, 1, CAST(1500000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (19, 12, 1, 2, CAST(40000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (20, 12, 4, 1, CAST(20000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (21, 13, 5, 1, CAST(150000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (22, 13, 2, 3, CAST(30000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (23, 13, 4, 1, CAST(20000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (24, 14, 1, 3, CAST(40000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (25, 14, 4, 1, CAST(20000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (26, 15, 6, 1, CAST(350000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (27, 15, 5, 1, CAST(150000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (28, 15, 1, 2, CAST(40000.00 AS Decimal(18, 2)))
INSERT [dbo].[InvoiceDetail] ([InvoiceDetailID], [InvoiceID], [ServiceID], [Quantity], [UnitPrice]) VALUES (29, 15, 4, 1, CAST(20000.00 AS Decimal(18, 2)))
SET IDENTITY_INSERT [dbo].[InvoiceDetail] OFF
GO
SET IDENTITY_INSERT [dbo].[LeaveRequest] ON 

INSERT [dbo].[LeaveRequest] ([LeaveRequestId], [AccountId], [ScheduleId], [Reason], [Status], [CreatedAt], [ApprovedById]) VALUES (1, 4, 22, N'Bố m thích', N'Approved', CAST(N'2026-07-21T15:54:07.337' AS DateTime), 2)
INSERT [dbo].[LeaveRequest] ([LeaveRequestId], [AccountId], [ScheduleId], [Reason], [Status], [CreatedAt], [ApprovedById]) VALUES (2, 12, 376, N'Bố m thích nghỉ đấy', N'Approved', CAST(N'2026-07-22T16:43:38.100' AS DateTime), 2)
SET IDENTITY_INSERT [dbo].[LeaveRequest] OFF
GO
SET IDENTITY_INSERT [dbo].[MaintenanceLog] ON 

INSERT [dbo].[MaintenanceLog] ([LogID], [EquipmentID], [ReportedByID], [IssueDescription], [RepairCost], [LogDate]) VALUES (1, 3, 3, N'Rớt móp đầu mic', CAST(150000.00 AS Decimal(18, 2)), CAST(N'2026-06-22T21:58:47.783' AS DateTime))
INSERT [dbo].[MaintenanceLog] ([LogID], [EquipmentID], [ReportedByID], [IssueDescription], [RepairCost], [LogDate]) VALUES (2, 5, 2, N'Máy kêu to', CAST(500000.00 AS Decimal(18, 2)), CAST(N'2026-06-26T21:58:47.783' AS DateTime))
SET IDENTITY_INSERT [dbo].[MaintenanceLog] OFF
GO
SET IDENTITY_INSERT [dbo].[MarketingCampaign] ON 

INSERT [dbo].[MarketingCampaign] ([CampaignID], [PromotionID], [CampaignName], [Channel], [TargetTierID], [MessageTemplate], [StartDate], [Status]) VALUES (1, NULL, N'ChÃºc má»«ng sinh nháº­t VIP', N'SMS', 3, N'ChÃºc má»«ng sinh nháº­t! Táº·ng báº¡n voucher giáº£m 20%', CAST(N'2026-07-21T15:07:43.950' AS DateTime), N'Active')
INSERT [dbo].[MarketingCampaign] ([CampaignID], [PromotionID], [CampaignName], [Channel], [TargetTierID], [MessageTemplate], [StartDate], [Status]) VALUES (2, NULL, N'Khuyáº¿n mÃ£i HÃ¨ sÃ´i Ä‘á»™ng', N'Email', 2, N'Giáº£m 10% tiá»n phÃ²ng cho khÃ¡ch hÃ ng Gold', CAST(N'2026-07-26T15:07:43.950' AS DateTime), N'Draft')
SET IDENTITY_INSERT [dbo].[MarketingCampaign] OFF
GO
SET IDENTITY_INSERT [dbo].[MembershipTier] ON 

INSERT [dbo].[MembershipTier] ([TierID], [TierName], [DiscountPercent], [MinPoints]) VALUES (1, N'Khách Mới', CAST(0.00 AS Decimal(5, 2)), 0)
INSERT [dbo].[MembershipTier] ([TierID], [TierName], [DiscountPercent], [MinPoints]) VALUES (2, N'Đồng', CAST(5.00 AS Decimal(5, 2)), 1000)
INSERT [dbo].[MembershipTier] ([TierID], [TierName], [DiscountPercent], [MinPoints]) VALUES (3, N'Bạc', CAST(10.00 AS Decimal(5, 2)), 3000)
INSERT [dbo].[MembershipTier] ([TierID], [TierName], [DiscountPercent], [MinPoints]) VALUES (4, N'Vàng', CAST(15.00 AS Decimal(5, 2)), 7000)
INSERT [dbo].[MembershipTier] ([TierID], [TierName], [DiscountPercent], [MinPoints]) VALUES (5, N'Kim Cương', CAST(20.00 AS Decimal(5, 2)), 15000)
SET IDENTITY_INSERT [dbo].[MembershipTier] OFF
GO
SET IDENTITY_INSERT [dbo].[NotificationLog] ON 

INSERT [dbo].[NotificationLog] ([NotificationID], [BookingID], [CustomerID], [Channel], [Recipient], [MessageContent], [SentStatus], [SentAt]) VALUES (1, 1, 1, N'SMS', N'0901234567', N'Cáº£m Æ¡n quÃ½ khÃ¡ch Ä‘Ã£ Ä‘áº·t phÃ²ng táº¡i Karaoke Management. MÃ£ Ä‘áº·t phÃ²ng: #1', N'Sent', CAST(N'2026-07-21T15:07:43.950' AS DateTime))
INSERT [dbo].[NotificationLog] ([NotificationID], [BookingID], [CustomerID], [Channel], [Recipient], [MessageContent], [SentStatus], [SentAt]) VALUES (2, 2, 2, N'Email', N'khachhang2@gmail.com', N'PhÃ²ng VIP 2 cá»§a quÃ½ khÃ¡ch Ä‘Ã£ sáºµn sÃ ng lÃºc 19:00', N'Sent', CAST(N'2026-07-21T15:07:43.950' AS DateTime))
SET IDENTITY_INSERT [dbo].[NotificationLog] OFF
GO
SET IDENTITY_INSERT [dbo].[PaymentMethod] ON 

INSERT [dbo].[PaymentMethod] ([MethodID], [MethodName]) VALUES (1, N'Tiền mặt')
INSERT [dbo].[PaymentMethod] ([MethodID], [MethodName]) VALUES (2, N'VNPay')
INSERT [dbo].[PaymentMethod] ([MethodID], [MethodName]) VALUES (3, N'Visa')
INSERT [dbo].[PaymentMethod] ([MethodID], [MethodName]) VALUES (4, N'Momo')
SET IDENTITY_INSERT [dbo].[PaymentMethod] OFF
GO
SET IDENTITY_INSERT [dbo].[PaymentTransaction] ON 

INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (1, 1, 3, CAST(3160000.00 AS Decimal(18, 2)), CAST(N'2026-06-26T01:58:47.790' AS DateTime), N'VISA-123')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (2, 2, 1, CAST(1000000.00 AS Decimal(18, 2)), CAST(N'2026-06-27T00:58:47.790' AS DateTime), NULL)
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (3, 2, 4, CAST(1800000.00 AS Decimal(18, 2)), CAST(N'2026-06-27T00:58:47.790' AS DateTime), N'MOMO-987')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (4, 4, 1, CAST(440000.00 AS Decimal(18, 2)), CAST(N'2026-06-13T23:58:47.793' AS DateTime), NULL)
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (5, 5, 2, CAST(530000.00 AS Decimal(18, 2)), CAST(N'2026-06-15T00:58:47.793' AS DateTime), N'VNPAY-456')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (6, 6, 4, CAST(430000.00 AS Decimal(18, 2)), CAST(N'2026-06-15T23:58:47.793' AS DateTime), N'MOMO-111')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (7, 7, 3, CAST(1690000.00 AS Decimal(18, 2)), CAST(N'2026-06-17T01:58:47.793' AS DateTime), N'VISA-444')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (8, 8, 1, CAST(2050000.00 AS Decimal(18, 2)), CAST(N'2026-06-18T02:58:47.793' AS DateTime), NULL)
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (9, 9, 2, CAST(810000.00 AS Decimal(18, 2)), CAST(N'2026-06-18T23:58:47.793' AS DateTime), N'VNPAY-777')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (10, 10, 4, CAST(2970000.00 AS Decimal(18, 2)), CAST(N'2026-06-20T00:58:47.793' AS DateTime), N'MOMO-222')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (11, 11, 3, CAST(3510000.00 AS Decimal(18, 2)), CAST(N'2026-06-21T01:58:47.793' AS DateTime), N'VISA-555')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (12, 12, 1, CAST(400000.00 AS Decimal(18, 2)), CAST(N'2026-06-21T23:58:47.793' AS DateTime), NULL)
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (13, 13, 2, CAST(710000.00 AS Decimal(18, 2)), CAST(N'2026-06-23T00:58:47.793' AS DateTime), N'VNPAY-888')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (14, 14, 4, CAST(440000.00 AS Decimal(18, 2)), CAST(N'2026-06-23T23:58:47.793' AS DateTime), N'MOMO-333')
INSERT [dbo].[PaymentTransaction] ([TransactionID], [InvoiceID], [MethodID], [Amount], [TransactionDate], [ReferenceCode]) VALUES (15, 15, 3, CAST(1620000.00 AS Decimal(18, 2)), CAST(N'2026-06-25T01:58:47.793' AS DateTime), N'VISA-666')
SET IDENTITY_INSERT [dbo].[PaymentTransaction] OFF
GO
SET IDENTITY_INSERT [dbo].[Payroll] ON 

INSERT [dbo].[Payroll] ([PayrollID], [AccountID], [PayPeriodMonth], [PayPeriodYear], [BaseSalary], [BonusAmount], [DeductionAmount], [NetSalary], [PaymentStatus], [PaymentDate], [Note]) VALUES (1, 1, 7, 2026, CAST(8000000.00 AS Decimal(18, 2)), CAST(500000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(8500000.00 AS Decimal(18, 2)), N'Paid', CAST(N'2026-07-21T15:07:43.947' AS DateTime), N'LÆ°Æ¡ng thÃ¡ng nÃ y')
INSERT [dbo].[Payroll] ([PayrollID], [AccountID], [PayPeriodMonth], [PayPeriodYear], [BaseSalary], [BonusAmount], [DeductionAmount], [NetSalary], [PaymentStatus], [PaymentDate], [Note]) VALUES (2, 3, 7, 2026, CAST(6000000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(200000.00 AS Decimal(18, 2)), CAST(5800000.00 AS Decimal(18, 2)), N'Unpaid', NULL, N'Pháº¡t Ä‘i muá»™n')
SET IDENTITY_INSERT [dbo].[Payroll] OFF
GO
SET IDENTITY_INSERT [dbo].[Promotion] ON 

INSERT [dbo].[Promotion] ([PromotionID], [PromoCode], [PromoName], [DiscountPercent], [MaxDiscountAmount], [StartDate], [EndDate]) VALUES (1, N'NEWYEAR', N'Giảm 20%', CAST(20.00 AS Decimal(5, 2)), CAST(500000.00 AS Decimal(18, 2)), CAST(N'2024-01-01T00:00:00.000' AS DateTime), CAST(N'2024-01-31T00:00:00.000' AS DateTime))
INSERT [dbo].[Promotion] ([PromotionID], [PromoCode], [PromoName], [DiscountPercent], [MaxDiscountAmount], [StartDate], [EndDate]) VALUES (2, N'NOPROMO', N'Không KM', CAST(0.00 AS Decimal(5, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(N'2000-01-01T00:00:00.000' AS DateTime), CAST(N'2099-12-31T00:00:00.000' AS DateTime))
SET IDENTITY_INSERT [dbo].[Promotion] OFF
GO
SET IDENTITY_INSERT [dbo].[PurchaseOrder] ON 

INSERT [dbo].[PurchaseOrder] ([PO_ID], [SupplierID], [CreatedByID], [OrderDate], [TotalAmount]) VALUES (1, 1, 2, CAST(N'2023-10-01T00:00:00.000' AS DateTime), CAST(25000000.00 AS Decimal(18, 2)))
INSERT [dbo].[PurchaseOrder] ([PO_ID], [SupplierID], [CreatedByID], [OrderDate], [TotalAmount]) VALUES (2, 2, 2, CAST(N'2023-10-05T00:00:00.000' AS DateTime), CAST(45000000.00 AS Decimal(18, 2)))
INSERT [dbo].[PurchaseOrder] ([PO_ID], [SupplierID], [CreatedByID], [OrderDate], [TotalAmount]) VALUES (3, 1, 2, CAST(N'2026-07-12T22:33:52.920' AS DateTime), CAST(7500000.00 AS Decimal(18, 2)))
INSERT [dbo].[PurchaseOrder] ([PO_ID], [SupplierID], [CreatedByID], [OrderDate], [TotalAmount]) VALUES (4, 1, 2, CAST(N'2026-07-12T22:35:10.617' AS DateTime), CAST(240.00 AS Decimal(18, 2)))
INSERT [dbo].[PurchaseOrder] ([PO_ID], [SupplierID], [CreatedByID], [OrderDate], [TotalAmount]) VALUES (5, 1, 2, CAST(N'2026-07-12T22:49:08.673' AS DateTime), CAST(15000000.00 AS Decimal(18, 2)))
SET IDENTITY_INSERT [dbo].[PurchaseOrder] OFF
GO
SET IDENTITY_INSERT [dbo].[PurchaseOrderDetail] ON 

INSERT [dbo].[PurchaseOrderDetail] ([PODetailID], [PO_ID], [ServiceID], [ImportPrice], [Quantity]) VALUES (1, 1, 1, CAST(25000.00 AS Decimal(18, 2)), 300)
INSERT [dbo].[PurchaseOrderDetail] ([PODetailID], [PO_ID], [ServiceID], [ImportPrice], [Quantity]) VALUES (2, 1, 2, CAST(18000.00 AS Decimal(18, 2)), 500)
INSERT [dbo].[PurchaseOrderDetail] ([PODetailID], [PO_ID], [ServiceID], [ImportPrice], [Quantity]) VALUES (3, 2, 3, CAST(1000000.00 AS Decimal(18, 2)), 10)
INSERT [dbo].[PurchaseOrderDetail] ([PODetailID], [PO_ID], [ServiceID], [ImportPrice], [Quantity]) VALUES (4, 3, 8, CAST(1500000.00 AS Decimal(18, 2)), 5)
INSERT [dbo].[PurchaseOrderDetail] ([PODetailID], [PO_ID], [ServiceID], [ImportPrice], [Quantity]) VALUES (5, 4, 9, CAST(12.00 AS Decimal(18, 2)), 20)
INSERT [dbo].[PurchaseOrderDetail] ([PODetailID], [PO_ID], [ServiceID], [ImportPrice], [Quantity]) VALUES (6, 5, 10, CAST(1000000.00 AS Decimal(18, 2)), 15)
SET IDENTITY_INSERT [dbo].[PurchaseOrderDetail] OFF
GO
SET IDENTITY_INSERT [dbo].[Role] ON 

INSERT [dbo].[Role] ([RoleID], [RoleName]) VALUES (1, N'Admin')
INSERT [dbo].[Role] ([RoleID], [RoleName]) VALUES (2, N'Manager')
INSERT [dbo].[Role] ([RoleID], [RoleName]) VALUES (3, N'Receptionist')
INSERT [dbo].[Role] ([RoleID], [RoleName]) VALUES (6, N'Customer')
INSERT [dbo].[Role] ([RoleID], [RoleName]) VALUES (7, N'Service Staff')
SET IDENTITY_INSERT [dbo].[Role] OFF
GO
SET IDENTITY_INSERT [dbo].[Room] ON 

INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (1, 1, N'Tầng 1 - 101', N'Available')
INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (2, 1, N'Tầng 1 - 102', N'Available')
INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (3, 1, N'Tầng 1 - 103', N'Maintenance')
INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (4, 4, N'Tầng 1 - 104 (Couple)', N'InUse')
INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (5, 2, N'Tầng 2 - 201 (VIP)', N'Available')
INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (6, 2, N'Tầng 2 - 202 (VIP)', N'InUse')
INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (7, 2, N'Tầng 2 - 203 (VIP)', N'Available')
INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (8, 3, N'Tầng 3 - 301 (Party)', N'Available')
INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (9, 3, N'Tầng 3 - 302 (Party)', N'InUse')
INSERT [dbo].[Room] ([RoomID], [RoomTypeID], [RoomName], [Status]) VALUES (10, 1, N'Tầng 4 - 401', N'Available')
SET IDENTITY_INSERT [dbo].[Room] OFF
GO
SET IDENTITY_INSERT [dbo].[RoomType] ON 

INSERT [dbo].[RoomType] ([RoomTypeID], [TypeName], [PricePerHour], [Description], [ImageURL], [Capacity]) VALUES (1, N'Phòng Thường', CAST(150000.00 AS Decimal(18, 2)), N'Sức chứa 5-8 người', N'/images/rooms/standard.jpg', 5)
INSERT [dbo].[RoomType] ([RoomTypeID], [TypeName], [PricePerHour], [Description], [ImageURL], [Capacity]) VALUES (2, N'Phòng VIP', CAST(300000.00 AS Decimal(18, 2)), N'Sức chứa 10-15 người', N'/images/rooms/vip.jpg', 15)
INSERT [dbo].[RoomType] ([RoomTypeID], [TypeName], [PricePerHour], [Description], [ImageURL], [Capacity]) VALUES (3, N'Phòng Party', CAST(600000.00 AS Decimal(18, 2)), N'Sức chứa 30 người', N'/images/rooms/party.jpg', 30)
INSERT [dbo].[RoomType] ([RoomTypeID], [TypeName], [PricePerHour], [Description], [ImageURL], [Capacity]) VALUES (4, N'Phòng Couple', CAST(120000.00 AS Decimal(18, 2)), N'Sức chứa 2-4 người', NULL, 10)
SET IDENTITY_INSERT [dbo].[RoomType] OFF
GO
SET IDENTITY_INSERT [dbo].[ServiceItem] ON 

INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (1, 1, N'Heineken', CAST(40000.00 AS Decimal(18, 2)), N'Lon', 500)
INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (2, 1, N'Tiger', CAST(30000.00 AS Decimal(18, 2)), N'Lon', 800)
INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (3, 2, N'Chivas 12', CAST(1500000.00 AS Decimal(18, 2)), N'Chai', 20)
INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (4, 3, N'Aquafina', CAST(20000.00 AS Decimal(18, 2)), N'Chai', 400)
INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (5, 4, N'Khô Bò', CAST(150000.00 AS Decimal(18, 2)), N'Đĩa', 50)
INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (6, 5, N'Trái Cây VIP', CAST(350000.00 AS Decimal(18, 2)), N'Đĩa', 20)
INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (7, 6, N'Combo Sinh Nhật', CAST(1500000.00 AS Decimal(18, 2)), N'Combo', 5)
INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (8, 4, N'Đào Tiên ', CAST(3000000.00 AS Decimal(18, 2)), N'EM', 5)
INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (9, 5, N'Gà 45kg', CAST(150000.00 AS Decimal(18, 2)), N'Con', 20)
INSERT [dbo].[ServiceItem] ([ServiceID], [CategoryID], [ServiceName], [SellingPrice], [Unit], [StockQuantity]) VALUES (10, 6, N'2 tay ôm 2 em ', CAST(50000000.00 AS Decimal(18, 2)), N'combo', 15)
SET IDENTITY_INSERT [dbo].[ServiceItem] OFF
GO
SET IDENTITY_INSERT [dbo].[ShiftSwapRequest] ON 

INSERT [dbo].[ShiftSwapRequest] ([SwapRequestId], [RequesterId], [RequesterScheduleId], [TargetId], [TargetScheduleId], [Status], [CreatedAt], [ApprovedById]) VALUES (1, 1, 7, 1, 7, N'Consented', CAST(N'2026-07-21T15:53:06.260' AS DateTime), NULL)
INSERT [dbo].[ShiftSwapRequest] ([SwapRequestId], [RequesterId], [RequesterScheduleId], [TargetId], [TargetScheduleId], [Status], [CreatedAt], [ApprovedById]) VALUES (2, 12, 383, 13, 385, N'Pending', CAST(N'2026-07-22T16:55:21.097' AS DateTime), NULL)
SET IDENTITY_INSERT [dbo].[ShiftSwapRequest] OFF
GO
SET IDENTITY_INSERT [dbo].[Supplier] ON 

INSERT [dbo].[Supplier] ([SupplierID], [SupplierName], [ContactName], [Phone], [Address]) VALUES (1, N'Bia Nước Ngọt Thành Phát', N'Anh Thành', N'0901111222', N'Q10')
INSERT [dbo].[Supplier] ([SupplierID], [SupplierName], [ContactName], [Phone], [Address]) VALUES (2, N'Rượu Ngoại Sài Gòn', N'Chị Hương', N'0903333444', N'Q1')
SET IDENTITY_INSERT [dbo].[Supplier] OFF
GO
SET IDENTITY_INSERT [dbo].[TrainingRecord] ON 

INSERT [dbo].[TrainingRecord] ([TrainingID], [AccountID], [CourseName], [CompletionDate], [Result]) VALUES (1, 1, N'Ká»¹ nÄƒng PCCC', CAST(N'2023-05-10' AS Date), N'Passed')
INSERT [dbo].[TrainingRecord] ([TrainingID], [AccountID], [CourseName], [CompletionDate], [Result]) VALUES (2, 3, N'Ká»¹ nÄƒng Giao tiáº¿p khÃ¡ch hÃ ng', CAST(N'2023-06-15' AS Date), N'Passed')
SET IDENTITY_INSERT [dbo].[TrainingRecord] OFF
GO
SET IDENTITY_INSERT [dbo].[WorkShift] ON 

INSERT [dbo].[WorkShift] ([ShiftID], [ShiftName], [StartTime], [EndTime]) VALUES (1, N'Ca Sáng', CAST(N'08:00:00' AS Time), CAST(N'16:00:00' AS Time))
INSERT [dbo].[WorkShift] ([ShiftID], [ShiftName], [StartTime], [EndTime]) VALUES (2, N'Ca Chiều', CAST(N'16:00:00' AS Time), CAST(N'00:00:00' AS Time))
INSERT [dbo].[WorkShift] ([ShiftID], [ShiftName], [StartTime], [EndTime]) VALUES (3, N'Ca Khuya', CAST(N'00:00:00' AS Time), CAST(N'08:00:00' AS Time))
SET IDENTITY_INSERT [dbo].[WorkShift] OFF
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__Account__536C85E4B8387AE6]    Script Date: 7/22/2026 5:24:55 PM ******/
ALTER TABLE [dbo].[Account] ADD UNIQUE NONCLUSTERED 
(
	[Username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ__Employee__349DA587BB3F6E1D]    Script Date: 7/22/2026 5:24:55 PM ******/
ALTER TABLE [dbo].[EmployeeProfile] ADD UNIQUE NONCLUSTERED 
(
	[AccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__Employee__59CD512133B1B4C7]    Script Date: 7/22/2026 5:24:55 PM ******/
ALTER TABLE [dbo].[EmployeeProfile] ADD UNIQUE NONCLUSTERED 
(
	[IdentityCardNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__Promotio__32DBED353576EB8C]    Script Date: 7/22/2026 5:24:55 PM ******/
ALTER TABLE [dbo].[Promotion] ADD UNIQUE NONCLUSTERED 
(
	[PromoCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Account] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Attendance] ADD  DEFAULT ('OnTime') FOR [Status]
GO
ALTER TABLE [dbo].[Booking] ADD  DEFAULT (getdate()) FOR [BookingTime]
GO
ALTER TABLE [dbo].[Booking] ADD  DEFAULT ('Pending') FOR [Status]
GO
ALTER TABLE [dbo].[Booking] ADD  DEFAULT ((1)) FOR [GuestCount]
GO
ALTER TABLE [dbo].[Customer] ADD  DEFAULT ((0)) FOR [LoyaltyPoints]
GO
ALTER TABLE [dbo].[Customer] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[CustomerAutomationRule] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[CustomerCareLog] ADD  DEFAULT (getdate()) FOR [LoggedDate]
GO
ALTER TABLE [dbo].[CustomerReview] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[EmployeeProfile] ADD  DEFAULT ((0)) FOR [BaseHourlyRate]
GO
ALTER TABLE [dbo].[EmployeeProfile] ADD  DEFAULT ('Active') FOR [EmploymentStatus]
GO
ALTER TABLE [dbo].[EmployeeSchedule] ADD  DEFAULT ('Scheduled') FOR [Status]
GO
ALTER TABLE [dbo].[EmployeeSchedule] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[EmployeeTask] ADD  DEFAULT ('Pending') FOR [Status]
GO
ALTER TABLE [dbo].[Equipment] ADD  DEFAULT ('Good') FOR [Status]
GO
ALTER TABLE [dbo].[Expense] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Invoice] ADD  DEFAULT ((0)) FOR [RoomTotal]
GO
ALTER TABLE [dbo].[Invoice] ADD  DEFAULT ((0)) FOR [ServiceTotal]
GO
ALTER TABLE [dbo].[Invoice] ADD  DEFAULT ((0)) FOR [DiscountAmount]
GO
ALTER TABLE [dbo].[Invoice] ADD  DEFAULT ((0)) FOR [GrandTotal]
GO
ALTER TABLE [dbo].[Invoice] ADD  DEFAULT ('Unpaid') FOR [Status]
GO
ALTER TABLE [dbo].[LeaveRequest] ADD  DEFAULT ('Pending') FOR [Status]
GO
ALTER TABLE [dbo].[LeaveRequest] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[MaintenanceLog] ADD  DEFAULT ((0)) FOR [RepairCost]
GO
ALTER TABLE [dbo].[MaintenanceLog] ADD  DEFAULT (getdate()) FOR [LogDate]
GO
ALTER TABLE [dbo].[MarketingCampaign] ADD  DEFAULT ('Draft') FOR [Status]
GO
ALTER TABLE [dbo].[MembershipTier] ADD  DEFAULT ((0)) FOR [DiscountPercent]
GO
ALTER TABLE [dbo].[MembershipTier] ADD  DEFAULT ((0)) FOR [MinPoints]
GO
ALTER TABLE [dbo].[NotificationLog] ADD  DEFAULT ('Pending') FOR [SentStatus]
GO
ALTER TABLE [dbo].[NotificationLog] ADD  DEFAULT (getdate()) FOR [SentAt]
GO
ALTER TABLE [dbo].[PaymentTransaction] ADD  DEFAULT (getdate()) FOR [TransactionDate]
GO
ALTER TABLE [dbo].[Payroll] ADD  DEFAULT ((0)) FOR [BonusAmount]
GO
ALTER TABLE [dbo].[Payroll] ADD  DEFAULT ((0)) FOR [DeductionAmount]
GO
ALTER TABLE [dbo].[Payroll] ADD  DEFAULT ('Unpaid') FOR [PaymentStatus]
GO
ALTER TABLE [dbo].[Promotion] ADD  DEFAULT ((0)) FOR [DiscountPercent]
GO
ALTER TABLE [dbo].[PurchaseOrder] ADD  DEFAULT (getdate()) FOR [OrderDate]
GO
ALTER TABLE [dbo].[PurchaseOrder] ADD  DEFAULT ((0)) FOR [TotalAmount]
GO
ALTER TABLE [dbo].[Room] ADD  DEFAULT ('Available') FOR [Status]
GO
ALTER TABLE [dbo].[RoomAssignment] ADD  DEFAULT (getdate()) FOR [AssignedAt]
GO
ALTER TABLE [dbo].[RoomType] ADD  DEFAULT ((10)) FOR [Capacity]
GO
ALTER TABLE [dbo].[ServiceItem] ADD  DEFAULT ((0)) FOR [StockQuantity]
GO
ALTER TABLE [dbo].[ShiftSwapRequest] ADD  DEFAULT ('Pending') FOR [Status]
GO
ALTER TABLE [dbo].[ShiftSwapRequest] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[TrainingRecord] ADD  DEFAULT ('Passed') FOR [Result]
GO
ALTER TABLE [dbo].[Account]  WITH CHECK ADD FOREIGN KEY([DefaultShiftID])
REFERENCES [dbo].[WorkShift] ([ShiftID])
GO
ALTER TABLE [dbo].[Account]  WITH CHECK ADD FOREIGN KEY([RoleID])
REFERENCES [dbo].[Role] ([RoleID])
GO
ALTER TABLE [dbo].[Attendance]  WITH CHECK ADD FOREIGN KEY([AccountID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[Attendance]  WITH CHECK ADD FOREIGN KEY([ScheduleID])
REFERENCES [dbo].[EmployeeSchedule] ([ScheduleID])
GO
ALTER TABLE [dbo].[Booking]  WITH CHECK ADD FOREIGN KEY([CreatedByID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[Booking]  WITH CHECK ADD FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customer] ([CustomerID])
GO
ALTER TABLE [dbo].[Booking]  WITH CHECK ADD FOREIGN KEY([RoomID])
REFERENCES [dbo].[Room] ([RoomID])
GO
ALTER TABLE [dbo].[Customer]  WITH CHECK ADD FOREIGN KEY([TierID])
REFERENCES [dbo].[MembershipTier] ([TierID])
GO
ALTER TABLE [dbo].[CustomerCareLog]  WITH CHECK ADD FOREIGN KEY([AccountID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[CustomerCareLog]  WITH CHECK ADD FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customer] ([CustomerID])
GO
ALTER TABLE [dbo].[CustomerReview]  WITH CHECK ADD FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customer] ([CustomerID])
GO
ALTER TABLE [dbo].[CustomerReview]  WITH CHECK ADD FOREIGN KEY([InvoiceID])
REFERENCES [dbo].[Invoice] ([InvoiceID])
GO
ALTER TABLE [dbo].[CustomerReview]  WITH CHECK ADD FOREIGN KEY([StaffID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[EmployeeProfile]  WITH CHECK ADD FOREIGN KEY([AccountID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[EmployeeSchedule]  WITH CHECK ADD FOREIGN KEY([AccountID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[EmployeeSchedule]  WITH CHECK ADD FOREIGN KEY([ShiftID])
REFERENCES [dbo].[WorkShift] ([ShiftID])
GO
ALTER TABLE [dbo].[EmployeeTask]  WITH CHECK ADD FOREIGN KEY([AssignedToID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[EmployeeTask]  WITH CHECK ADD FOREIGN KEY([CreatedByID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[Equipment]  WITH CHECK ADD FOREIGN KEY([RoomID])
REFERENCES [dbo].[Room] ([RoomID])
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD FOREIGN KEY([BookingID])
REFERENCES [dbo].[Booking] ([BookingID])
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD FOREIGN KEY([PromotionID])
REFERENCES [dbo].[Promotion] ([PromotionID])
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD FOREIGN KEY([ReceptionistID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[Invoice]  WITH CHECK ADD FOREIGN KEY([RoomID])
REFERENCES [dbo].[Room] ([RoomID])
GO
ALTER TABLE [dbo].[InvoiceDetail]  WITH CHECK ADD FOREIGN KEY([InvoiceID])
REFERENCES [dbo].[Invoice] ([InvoiceID])
GO
ALTER TABLE [dbo].[InvoiceDetail]  WITH CHECK ADD FOREIGN KEY([ServiceID])
REFERENCES [dbo].[ServiceItem] ([ServiceID])
GO
ALTER TABLE [dbo].[LeaveRequest]  WITH CHECK ADD FOREIGN KEY([AccountId])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[LeaveRequest]  WITH CHECK ADD FOREIGN KEY([ApprovedById])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[LeaveRequest]  WITH CHECK ADD FOREIGN KEY([ScheduleId])
REFERENCES [dbo].[EmployeeSchedule] ([ScheduleID])
GO
ALTER TABLE [dbo].[MaintenanceLog]  WITH CHECK ADD FOREIGN KEY([EquipmentID])
REFERENCES [dbo].[Equipment] ([EquipmentID])
GO
ALTER TABLE [dbo].[MaintenanceLog]  WITH CHECK ADD FOREIGN KEY([ReportedByID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[MarketingCampaign]  WITH CHECK ADD FOREIGN KEY([PromotionID])
REFERENCES [dbo].[Promotion] ([PromotionID])
GO
ALTER TABLE [dbo].[MarketingCampaign]  WITH CHECK ADD FOREIGN KEY([TargetTierID])
REFERENCES [dbo].[MembershipTier] ([TierID])
GO
ALTER TABLE [dbo].[NotificationLog]  WITH CHECK ADD FOREIGN KEY([BookingID])
REFERENCES [dbo].[Booking] ([BookingID])
GO
ALTER TABLE [dbo].[NotificationLog]  WITH CHECK ADD FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customer] ([CustomerID])
GO
ALTER TABLE [dbo].[PaymentTransaction]  WITH CHECK ADD FOREIGN KEY([InvoiceID])
REFERENCES [dbo].[Invoice] ([InvoiceID])
GO
ALTER TABLE [dbo].[PaymentTransaction]  WITH CHECK ADD FOREIGN KEY([MethodID])
REFERENCES [dbo].[PaymentMethod] ([MethodID])
GO
ALTER TABLE [dbo].[Payroll]  WITH CHECK ADD FOREIGN KEY([AccountID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[PurchaseOrder]  WITH CHECK ADD FOREIGN KEY([CreatedByID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[PurchaseOrder]  WITH CHECK ADD FOREIGN KEY([SupplierID])
REFERENCES [dbo].[Supplier] ([SupplierID])
GO
ALTER TABLE [dbo].[PurchaseOrderDetail]  WITH CHECK ADD FOREIGN KEY([PO_ID])
REFERENCES [dbo].[PurchaseOrder] ([PO_ID])
GO
ALTER TABLE [dbo].[PurchaseOrderDetail]  WITH CHECK ADD FOREIGN KEY([ServiceID])
REFERENCES [dbo].[ServiceItem] ([ServiceID])
GO
ALTER TABLE [dbo].[Room]  WITH CHECK ADD FOREIGN KEY([RoomTypeID])
REFERENCES [dbo].[RoomType] ([RoomTypeID])
GO
ALTER TABLE [dbo].[RoomAssignment]  WITH CHECK ADD FOREIGN KEY([RoomId])
REFERENCES [dbo].[Room] ([RoomID])
GO
ALTER TABLE [dbo].[RoomAssignment]  WITH CHECK ADD FOREIGN KEY([ScheduleId])
REFERENCES [dbo].[EmployeeSchedule] ([ScheduleID])
GO
ALTER TABLE [dbo].[ServiceItem]  WITH CHECK ADD FOREIGN KEY([CategoryID])
REFERENCES [dbo].[Category] ([CategoryID])
GO
ALTER TABLE [dbo].[ShiftSwapRequest]  WITH CHECK ADD FOREIGN KEY([ApprovedById])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[ShiftSwapRequest]  WITH CHECK ADD FOREIGN KEY([RequesterId])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[ShiftSwapRequest]  WITH CHECK ADD FOREIGN KEY([RequesterScheduleId])
REFERENCES [dbo].[EmployeeSchedule] ([ScheduleID])
GO
ALTER TABLE [dbo].[ShiftSwapRequest]  WITH CHECK ADD FOREIGN KEY([TargetId])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[ShiftSwapRequest]  WITH CHECK ADD FOREIGN KEY([TargetScheduleId])
REFERENCES [dbo].[EmployeeSchedule] ([ScheduleID])
GO
ALTER TABLE [dbo].[TrainingRecord]  WITH CHECK ADD FOREIGN KEY([AccountID])
REFERENCES [dbo].[Account] ([AccountID])
GO
ALTER TABLE [dbo].[CustomerReview]  WITH CHECK ADD CHECK  (([Rating]>=(1) AND [Rating]<=(5)))
GO
USE [master]
GO
ALTER DATABASE [KaraokeManagementDB] SET  READ_WRITE 
GO
