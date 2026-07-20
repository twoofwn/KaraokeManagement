# PROJECT CONTEXT — KaraokeManagement

> Paste file này vào đầu cuộc trò chuyện mới để Claude hiểu ngay toàn bộ dự án.
> Cập nhật file này mỗi khi có thay đổi lớn.

---

## Stack & Môi trường

| | |
|---|---|
| Framework | ASP.NET Core 8 MVC |
| ORM | Entity Framework Core (scaffold-first) |
| DB | SQL Server 2022 — `localhost`, Windows Auth (`Trusted_Connection=SSPI`) |
| DB name | `KaraokeManagementDB` |
| Port dev | `http://localhost:5000` |
| Chạy app | `dotnet run --project KaraokeManagement/KaraokeManagement.csproj --urls http://localhost:5000` |

---

## Cấu trúc thư mục quan trọng

```
KaraokeManagement/
├── Controllers/
│   ├── AuthController.cs        # Login/Logout cookie-based
│   ├── AdminController.cs       # CRUD Inventory (UI demo)
│   ├── CategoriesController.cs  # CRUD Categories (UI demo)
│   └── UsersController.cs       # CRUD Users/Accounts (UI demo)
├── Models/
│   ├── KaraokeManagementDbContext.cs  # EF DbContext
│   ├── Account.cs               # ⚠️ Có TierId + LoyaltyPoints (xem lưu ý)
│   ├── CustomerFeedback.cs      # ⚠️ Ngoài tài liệu
│   └── [15 model khác...]
├── Views/
│   ├── Admin/
│   │   ├── _AdminLayout.cshtml  # Layout sidebar chung cho toàn admin
│   │   ├── Index.cshtml         # Dashboard
│   │   └── Form.cshtml          # Create/Edit inventory item
│   ├── Categories/
│   │   ├── Index.cshtml
│   │   └── Form.cshtml
│   ├── Users/
│   │   ├── Index.cshtml
│   │   └── Form.cshtml
│   └── Auth/Login.cshtml
└── wwwroot/css/
    ├── admin.css                # Toàn bộ style admin panel
    └── Login.css
```

---

## Routes hiện có

| URL | Controller | Ghi chú |
|-----|-----------|---------|
| `/Auth/Login` | AuthController | Trang login |
| `/Auth/Logout` | AuthController | |
| `/Admin` | AdminController#Index | Dashboard |
| `/Admin/Create` | AdminController#Create | Form tạo inventory item |
| `/Admin/Edit/{id}` | AdminController#Edit | Form sửa |
| `/Categories` | CategoriesController#Index | |
| `/Categories/Create` | CategoriesController#Create | |
| `/Categories/Edit/{id}` | CategoriesController#Edit | |
| `/Users` | UsersController#Index | |
| `/Users/Create` | UsersController#Create | |
| `/Users/Edit/{id}` | UsersController#Edit | |

---

## Design System

**Palette:**
- `#F8F4EC` — nền trang (cream)
- `#FF8FB7` — hover tints, upload zone
- `#E83C91` — primary: active nav, nút Save, icons
- `#43334C` — text chính, sidebar brand, nút "Add New Entry"

**Layout admin:**
- Sidebar trái 240px (trắng), nền `#F8F4EC`
- Header sticky với search + tabs + avatar
- Active nav item: border-left `#E83C91` + text `#E83C91`
- Font: Inter

**Admin layout được dùng bằng:**
```cshtml
@{ Layout = "~/Views/Admin/_AdminLayout.cshtml"; }
ViewData["ActiveNav"] = "categories"; // dashboard|inventory|categories|users|settings
```

---

## Database — 19 bảng (theo tài liệu đặc tả)

### Phân hệ & bảng

| Phân hệ | Bảng |
|---------|------|
| System & Staff | Role, Account |
| CRM | MembershipTier, Customer |
| Rooms & Assets | RoomType, Room, Equipment, MaintenanceLog |
| Inventory | Category, ServiceItem, Supplier, PurchaseOrder, PurchaseOrderDetail |
| Core Business | Promotion, Booking, Invoice, InvoiceDetail |
| Payments | PaymentMethod, PaymentTransaction |

### Tài khoản mẫu (password = hash thô, VerifyPassword check plaintext)

| Username | Role | Password |
|----------|------|---------|
| admin_tong | Admin | hash1 |
| quanly_hung | Manager | hash2 |
| letan_lan | Receptionist | hash3 |
| letan_mai | Receptionist | hash4 |

---

## ⚠️ Vấn đề chưa giải quyết (kỹ thuật nợ)

### 1. Mismatch giữa Model và DB script hiện tại

DB script (đã chạy) tạo bảng `Customer` **riêng** và `Booking.CreatedByID`. Nhưng code C# được scaffold từ schema cũ hơn:

| Vấn đề | DB thực tế | Model C# hiện tại |
|--------|-----------|------------------|
| Bảng Customer | Có bảng `Customer` riêng | **Không có** `Customer.cs` / `DbSet<Customer>` |
| Account | Không có `TierID`/`LoyaltyPoints` | Có `TierId` + `LoyaltyPoints` (merge cũ) |
| Booking.CreatedByID | Có cột này | Model **thiếu** `CreatedById` |
| CustomerFeedback | **Không có** trong DB | Có `CustomerFeedback.cs` trong code |

**Cần làm:** Re-scaffold lại Models hoặc sửa thủ công cho khớp DB.

### 2. Controllers còn là UI demo

Toàn bộ CRUD (Admin, Categories, Users) chưa kết nối DB — chỉ là static HTML. Cần inject `KaraokeManagementDbContext` và implement thật.

### 3. Authentication chưa hoàn chỉnh

- `Program.cs` chưa đăng ký middleware `AddAuthentication("CookieAuth")`
- `AuthController` có try/catch fallback nên vẫn chạy được
- Chưa có `[Authorize]` ở bất kỳ controller nào

---

## Việc cần làm tiếp theo (gợi ý ưu tiên)

1. **Re-scaffold Models** từ DB hiện tại: `dotnet ef dbcontext scaffold "..." Microsoft.EntityFrameworkCore.SqlServer --force`
2. **Đăng ký Auth middleware** trong `Program.cs`
3. **Implement CRUD thật** cho từng controller (inject DbContext)
4. **Các trang còn thiếu:** Rooms, Bookings, Invoices, Suppliers, Reports

---

## Lưu ý phát triển

- Razor không cho C# inline trong attribute của `<option>` → dùng JS để set `.value` sau khi render
- File upload: chưa có logic lưu file thật, chỉ preview JS phía client
- CSS admin tập trung tại `wwwroot/css/admin.css` (~900 dòng), không dùng Bootstrap utility classes nhiều
