# BÁO CÁO PHÂN TÍCH CẤU TRÚC VÀ THIẾT KẾ DỰ ÁN KARAOKE MANAGEMENT

## 1. TỔNG QUAN DỰ ÁN (PROJECT OVERVIEW)
- **Tên dự án:** Karaoke Management System (Hát Cho Nhau Nghe - Quản Lý Karaoke)
- **Nền tảng công nghệ (Tech Stack):**
  - **Framework:** ASP.NET Core 8.0 (MVC - Model View Controller)
  - **ORM:** Entity Framework Core 8.0.27 (SQL Server Provider)
  - **Bảo mật & Xác thực:** Cookie-Based Authentication, Password Hashing với `BCrypt.Net-Next` (v4.2.0)
  - **Cơ sở dữ liệu:** Microsoft SQL Server (`HatChoNhauNghe.sql` & EF Core Code First / DbContext)
  - **Frontend:** Razor Views, Bootstrap, HTML5, CSS3, JavaScript.

---

## 2. CẤU TRÚC THƯ MỤC DỰ ÁN (FOLDER STRUCTURE)

```
KaraokeManagement/
├── Controllers/                  # Tầng điều hướng & xử lý logic (Controllers)
│   ├── AdminController.cs        # Xử lý chức năng quản trị viên (Quản lý User, Phòng, Thiết bị, Kho...)
│   ├── AuthController.cs         # Xử lý Đăng nhập, Đăng xuất, Phân quyền truy cập
│   ├── HomeController.cs         # Controller điều hướng mặc định / trang chủ
│   ├── InvoiceHistoryController.cs# Xử lý tra cứu & quản lý lịch sử hóa đơn
│   ├── ManagerController.cs      # Xử lý cho Quản lý (Nhập kho, Chi phí, Báo cáo doanh thu/lợi nhuận)
│   └── ReceptionistController.cs # Xử lý cho Lễ tân / POS (Đặt phòng, Check-in, Order dịch vụ, Thanh toán)
│
├── Models/                       # Tầng thực thể (Entities & EF DbContext)
│   ├── KaraokeManagementDbContext.cs # DbContext chính của ứng dụng
│   ├── Account.cs                # Tài khoản người dùng & Phân quyền
│   ├── Booking.cs                # Đặt phòng karaoke
│   ├── Category.cs               # Danh mục mặt hàng / dịch vụ
│   ├── Customer.cs               # Thông tin khách hàng & Điểm tích lũy
│   ├── Equipment.cs              # Thiết bị trong phòng (Micro, Loa, Đèn...)
│   ├── Expense.cs                # Quản lý chi phí vận hành
│   ├── Invoice.cs                # Hóa đơn thanh toán
│   ├── InvoiceDetail.cs          # Chi tiết dịch vụ trong hóa đơn
│   ├── MaintenanceLog.cs         # Lịch sử bảo trì thiết bị
│   ├── MembershipTier.cs         # Hạng thành viên (Vàng, Bạc, Kim Cương...)
│   ├── PaymentMethod.cs          # Phương thức thanh toán (Tiền mặt, Chuyển khoản...)
│   ├── PaymentTransaction.cs    # Giao dịch thanh toán
│   ├── Promotion.cs              # Chương trình khuyến mãi
│   ├── PurchaseOrder.cs          # Đơn nhập hàng
│   ├── PurchaseOrderDetail.cs    # Chi tiết đơn nhập hàng
│   ├── Role.cs                   # Vai trò hệ thống (Admin, Manager, Receptionist)
│   ├── Room.cs                   # Thông tin phòng hát (Số phòng, Trạng thái, Giá...)
│   ├── RoomType.cs               # Loại phòng (Phòng Thường, VIP, Party...)
│   ├── ServiceItem.cs            # Mặt hàng dịch vụ (Bia, Nước ngọt, Đồ ăn...)
│   └── Supplier.cs               # Nhà cung cấp
│
├── ViewModel/                    # Tầng DTO / ViewModel phục vụ truyền nhận dữ liệu màn hình
│   ├── AdminDashboardViewModel.cs# Dữ liệu bảng điều khiển Admin
│   ├── CheckInViewModel.cs       # Dữ liệu thủ tục Check-in phòng
│   ├── CheckoutViewModel.cs      # Dữ liệu tính toán & thanh toán Checkout
│   ├── ExpensesViewModel.cs      # Dữ liệu danh sách & thống kê chi phí
│   ├── FinancialDashboardViewModel.cs # Dữ liệu tổng quan tài chính
│   ├── ImportHistoryViewModel.cs # Dữ liệu lịch sử nhập kho
│   ├── InventoryViewModel.cs     # Dữ liệu tồn kho
│   ├── InvoiceHistoryViewModel.cs# Dữ liệu tra cứu lịch sử hóa đơn
│   ├── RoomDetailPosViewModel.cs # Dữ liệu phục vụ bán hàng tại phòng (POS)
│   └── StockInRequestModel.cs    # Model yêu cầu nhập kho
│
├── Views/                        # Tầng Giao diện (Razor Views)
│   ├── Admin/                    # Giao diện quản trị (Dashboard, Quản lý Users, Rooms, Categories...)
│   ├── Auth/                     # Giao diện Đăng nhập, AccessDenied
│   ├── Home/                     # Giao diện trang chính / Error
│   ├── Manager/                  # Giao diện Quản lý (Doanh thu, Lợi nhuận, Chi phí, Đơn nhập kho...)
│   ├── Receptionist/             # Giao diện POS Lễ tân (Sơ đồ phòng, Check-in, Detail Order, Thanh toán)
│   └── Shared/                   # Layout dùng chung (_Layout, _AdminLayout, _ManagerLayout, _ReceptionistSidebar)
│
├── Helpers/                      # Các lớp tiện ích (Utilities / Helpers)
│   ├── PasswordHelper.cs         # Mã hóa & Kiểm tra mật khẩu bằng BCrypt
│   └── ValidationHelper.cs       # Xử lý kiểm tra dữ liệu đầu vào
│
├── wwwroot/                      # Thư mục tài nguyên tĩnh (CSS, JS, Images, Libs)
├── appsettings.json              # Cấu hình ứng dụng (Chuỗi kết nối SQL Server, App settings)
├── Program.cs                    # Điểm khởi chạy ứng dụng (Pipeline & Dependency Injection)
└── HatChoNhauNghe.sql            # Script khởi tạo CSDL SQL Server
```

---

## 3. PHÂN TÍCH KIẾN TRÚC VÀ THIẾT KẾ DỰ ÁN (DESIGN & ARCHITECTURE)

### 3.1. Mô hình Kiến trúc MVC + ViewModel Pattern
Dự án tuân theo chuẩn kiến trúc **ASP.NET Core MVC (Model-View-Controller)** kết hợp với **ViewModel Pattern**:
1. **Model (Entities):** Các lớp đại diện cho bảng CSDL trong SQL Server, được ánh xạ thông qua `KaraokeManagementDbContext` (EF Core).
2. **ViewModel:** Tách biệt triệt để dữ liệu CSDL và dữ liệu hiển thị trên giao diện. Các ViewModel tổng hợp thông tin từ nhiều thực thể để phục vụ từng view cụ thể (ví dụ: `CheckoutViewModel` kết hợp thông tin phòng, hóa đơn, thời gian hát và chi tiết dịch vụ đồ ăn/nước uống).
3. **Controller:** Đóng vai trò làm trung tâm điều hướng, xử lý các request HTTP (GET, POST), gọi EF Core để thao tác dữ liệu và trả về View phù hợp.

### 3.2. Thiết kế Phân quyền theo Vai trò (Role-Based Access Control - RBAC)
Hệ thống phân chia rõ ràng các phân vùng chức năng tương ứng với các vai trò của người dùng:
- **Admin (Quản trị viên):** 
  - Quản lý tài khoản người dùng (`UserForm`, `Users.cshtml`).
  - Quản lý danh mục, phòng hát, loại phòng, thiết bị và nhà cung cấp.
  - Theo dõi Dashboard quản trị tổng quan.
- **Manager (Quản lý cửa hàng):**
  - Báo cáo doanh thu (`RevenueReport.cshtml`), báo cáo lợi nhuận (`ProfitReport.cshtml`).
  - Quản lý nhập kho (`StockIn.cshtml`), xem lịch sử nhập kho (`ImportHistory.cshtml`).
  - Quản lý các khoản chi phí vận hành (`Expenses.cshtml`).
- **Receptionist (Lễ tân / Nhân viên POS):**
  - Xem sơ đồ trạng thái phòng hát theo thời gian thực (Trống, Đang hát, Đang dọn dẹp...).
  - Thực hiện thủ tục Check-in cho khách.
  - Gọi thêm đồ ăn / nước uống / dịch vụ cho từng phòng.
  - Tính tiền tự động dựa trên thời lượng sử dụng phòng + dịch vụ gọi thêm và thực hiện Checkout / in hóa đơn.

### 3.3. Cơ chế Xác thực và Bảo mật (Authentication & Security)
- **Cookie Authentication:** Cấu hình trong `Program.cs` thông qua `builder.Services.AddAuthentication("CookieAuth")`. Quản lý phiên làm việc của người dùng an toàn, có thời gian hết hạn (`ExpireTimeSpan = 7 ngày`).
- **Mã hóa Mật khẩu:** Sử dụng thư viện `BCrypt.Net-Next` trong `PasswordHelper.cs` để hash mật khẩu trước khi lưu vào CSDL và verify mật khẩu khi đăng nhập, chống nguy cơ lộ mật khẩu thô.
- **Phân quyền truy cập:** Hỗ trợ kiểm tra quyền và điều hướng người dùng chưa đăng nhập về `/Auth/Login` hoặc từ chối truy cập `/Auth/AccessDenied`.

### 3.4. Thiết kế Cơ sở dữ liệu & Entity Framework Core
- **Database Context:** `KaraokeManagementDbContext` quản lý 22 DbSets bao phủ toàn bộ nghiệp vụ kinh doanh Karaoke:
  - **Nhóm Quản lý Phòng & Đặt phòng:** `Room`, `RoomType`, `Booking`.
  - **Nhóm Bán hàng & Dịch vụ (POS):** `ServiceItem`, `Category`, `Invoice`, `InvoiceDetail`, `PaymentTransaction`, `PaymentMethod`.
  - **Nhóm Khách hàng & Thành viên:** `Customer`, `MembershipTier`, `CustomerFeedback`, `Promotion`.
  - **Nhóm Kho & Tài sản:** `Equipment`, `MaintenanceLog`, `Supplier`, `PurchaseOrder`, `PurchaseOrderDetail`.
  - **Nhóm Tài chính & Người dùng:** `Expense`, `Account`, `Role`.

---

## 4. ĐÁNH GIÁ VÀ HƯỚNG CẢI TIẾN (EVALUATION & RECOMMENDATIONS)

### 4.1. Điểm mạnh (Pros)
- **Cấu trúc thư mục rõ ràng:** Các file được tổ chức theo vai trò người dùng (Admin, Manager, Receptionist) giúp dễ dàng định vị và bảo trì.
- **Tách biệt ViewModel:** Việc áp dụng ViewModel giúp giao diện không phụ thuộc trực tiếp vào Entity Model, tránh tình trạng over-posting / security risks.
- **Đầy đủ tính năng nghiệp vụ:** Bao phủ trọn vẹn quy trình vận hành một quán Karaoke từ nhập kho, quản lý chi phí, đặt phòng, gọi đồ, thanh toán cho đến báo cáo tài chính.

### 4.2. Khuyến nghị nâng cấp (Future Improvements)
1. **Bổ sung Tầng Service / Repository (Service Layer):**
   - Hiện tại logic nghiệp vụ đang tập trung khá nhiều tại các Controller (`ManagerController`, `ReceptionistController`, `AdminController`). Nên tách logic sang các Service class (như `IRoomService`, `IInvoiceService`, `IInventoryService`) để tái sử dụng và hỗ trợ Unit Testing tốt hơn.
2. **Áp dụng Dependency Injection cho Helpers/Services:**
   - Đăng ký các Helper / Service vào DI Container trong `Program.cs` để quản lý lifetime hiệu quả hơn.
3. **SignalR cho Cập nhật Trạng thái Phòng thời gian thực:**
   - Tích hợp SignalR để khi lễ tân tạo/checkout phòng, trạng thái phòng tự động cập nhật ngay trên màn hình các máy tính khác mà không cần load lại trang.
