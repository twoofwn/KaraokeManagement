using KaraokeManagement.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Helpers;
using KaraokeManagement.ViewModel;
using System.Security.Claims;

namespace KaraokeManagement.Controllers
{
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        public AdminController(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public IActionResult Index() => RedirectToAction("Dashboard");

        [HttpPost]
        public IActionResult VerifyAdminPassword(string password)
        {
            var currentAdminIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(currentAdminIdStr) || !int.TryParse(currentAdminIdStr, out int adminId))
            {
                return Json(new { success = false, message = "Phiên đăng nhập đã hết hạn." });
            }
            var adminAccount = _context.Accounts.Find(adminId);
            if (adminAccount == null)
            {
                return Json(new { success = false, message = "Tài khoản Admin không tồn tại." });
            }
            bool isValid = PasswordHelper.VerifyPassword(password, adminAccount.PasswordHash);
            if (isValid)
            {
                return Json(new { success = true });
            }
            return Json(new { success = false, message = "Mật khẩu xác nhận Admin không chính xác." });
        }

        // ========== DASHBOARD ==========
        public IActionResult Dashboard()
        {
            var now = DateTime.Now;
            var monthStart = new DateTime(now.Year, now.Month, 1);
            var prevMonthStart = monthStart.AddMonths(-1);

            // Hóa đơn tháng này & tháng trước (tính theo giờ check-in)
            var monthInvoices = _context.Invoices
                .Where(i => i.CheckInTime >= monthStart)
                .Select(i => new { i.CheckInTime, i.CheckOutTime, i.GrandTotal, i.Status })
                .ToList();
            var prevInvoices = _context.Invoices
                .Where(i => i.CheckInTime >= prevMonthStart && i.CheckInTime < monthStart)
                .Select(i => new { i.CheckInTime, i.CheckOutTime, i.GrandTotal, i.Status })
                .ToList();

            double hoursThisMonth = monthInvoices
                .Where(i => i.CheckOutTime != null)
                .Sum(i => (i.CheckOutTime!.Value - i.CheckInTime).TotalHours);
            double hoursPrevMonth = prevInvoices
                .Where(i => i.CheckOutTime != null)
                .Sum(i => (i.CheckOutTime!.Value - i.CheckInTime).TotalHours);

            decimal revenueThisMonth = monthInvoices.Where(i => i.Status == "Paid").Sum(i => i.GrandTotal ?? 0);
            decimal revenuePrevMonth = prevInvoices.Where(i => i.Status == "Paid").Sum(i => i.GrandTotal ?? 0);

            int newCustomersThisMonth = _context.Customers.Count(c => c.CreatedAt >= monthStart);
            int newCustomersPrevMonth = _context.Customers.Count(c => c.CreatedAt >= prevMonthStart && c.CreatedAt < monthStart);

            static double PercentChange(double current, double previous) =>
                previous == 0 ? 0 : Math.Round((current - previous) / previous * 100, 1);

            // Số giờ sử dụng theo ngày trong tháng
            var dailyUsage = monthInvoices
                .Where(i => i.CheckOutTime != null)
                .GroupBy(i => i.CheckInTime.Day)
                .Select(g => new DailyUsagePoint
                {
                    Day = g.Key,
                    Hours = Math.Round(g.Sum(i => (i.CheckOutTime!.Value - i.CheckInTime).TotalHours), 1)
                })
                .OrderBy(p => p.Day)
                .ToList();

            // Top phòng theo giờ sử dụng tháng này
            var topRooms = _context.Invoices
                .Where(i => i.CheckInTime >= monthStart && i.CheckOutTime != null)
                .Select(i => new { i.Room.RoomName, i.Room.RoomType.TypeName, i.CheckInTime, i.CheckOutTime, i.GrandTotal, i.Status })
                .ToList()
                .GroupBy(i => new { i.RoomName, i.TypeName })
                .Select(g => new RoomUsageStat
                {
                    RoomName = g.Key.RoomName,
                    TypeName = g.Key.TypeName,
                    Sessions = g.Count(),
                    Hours = Math.Round(g.Sum(i => (i.CheckOutTime!.Value - i.CheckInTime).TotalHours), 1),
                    Revenue = g.Where(i => i.Status == "Paid").Sum(i => i.GrandTotal ?? 0)
                })
                .OrderByDescending(r => r.Hours)
                .Take(5)
                .ToList();

            // Top dịch vụ bán chạy tháng này
            var topServices = _context.InvoiceDetails
                .Where(d => d.Invoice.CheckInTime >= monthStart)
                .Select(d => new { d.Service.ServiceName, CategoryName = d.Service.Category.CategoryName, d.Quantity, d.UnitPrice })
                .ToList()
                .GroupBy(d => new { d.ServiceName, d.CategoryName })
                .Select(g => new ServiceSalesStat
                {
                    ServiceName = g.Key.ServiceName,
                    CategoryName = g.Key.CategoryName,
                    Quantity = g.Sum(d => d.Quantity),
                    Amount = g.Sum(d => d.Quantity * d.UnitPrice)
                })
                .OrderByDescending(s => s.Quantity)
                .Take(5)
                .ToList();

            var model = new AdminDashboardViewModel
            {
                NewCustomersThisMonth = newCustomersThisMonth,
                PercentCustomerChange = PercentChange(newCustomersThisMonth, newCustomersPrevMonth),
                HoursThisMonth = Math.Round(hoursThisMonth, 1),
                PercentHoursChange = PercentChange(hoursThisMonth, hoursPrevMonth),
                RevenueThisMonth = revenueThisMonth,
                PercentRevenueChange = PercentChange((double)revenueThisMonth, (double)revenuePrevMonth),
                InvoicesThisMonth = monthInvoices.Count,
                PercentInvoiceChange = PercentChange(monthInvoices.Count, prevInvoices.Count),
                TotalItems = _context.ServiceItems.Count(),
                TotalCategories = _context.Categories.Count(),
                TotalUsers = _context.Accounts.Count(),
                TotalRooms = _context.Rooms.Count(),
                TotalCustomers = _context.Customers.Count(),
                DailyUsage = dailyUsage,
                TopRooms = topRooms,
                TopServices = topServices
            };
            return View(model);
        }

        // ========== INVENTORY (ServiceItems) ==========
        public IActionResult Inventory(string? search, int page = 1)
        {
            var query = _context.ServiceItems.Include(s => s.Category).AsQueryable();
            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(s => s.ServiceName.Contains(search) || s.Category.CategoryName.Contains(search));
            var items = PageList(query.OrderBy(s => s.ServiceId), page, "Inventory", search);
            return View("Inventory", items);
        }

        [HttpGet]
        public IActionResult InventoryCreate()
        {
            LoadCategories();
            return View("InventoryForm", new ServiceItem());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult InventoryCreate(ServiceItem model)
        {
            ModelState.Remove("Category");
            if (!ModelState.IsValid) { LoadCategories(); return View("InventoryForm", model); }
            _context.ServiceItems.Add(model);
            _context.SaveChanges();
            return RedirectToAction("Inventory");
        }

        [HttpGet]
        public IActionResult InventoryEdit(int id)
        {
            var item = _context.ServiceItems.Find(id);
            if (item == null) return NotFound();
            LoadCategories(item.CategoryId);
            ViewBag.IsEdit = true;
            return View("InventoryForm", item);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult InventoryEdit(int id, ServiceItem model)
        {
            ModelState.Remove("Category");
            if (!ModelState.IsValid) { LoadCategories(model.CategoryId); ViewBag.IsEdit = true; return View("InventoryForm", model); }
            var existing = _context.ServiceItems.Find(id);
            if (existing == null) return NotFound();
            existing.ServiceName = model.ServiceName;
            existing.CategoryId = model.CategoryId;
            existing.SellingPrice = model.SellingPrice;
            existing.Unit = model.Unit;
            existing.StockQuantity = model.StockQuantity;
            _context.SaveChanges();
            return RedirectToAction("Inventory");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult InventoryDelete(int id)
        {
            var item = _context.ServiceItems
                .Include(s => s.InvoiceDetails)
                .Include(s => s.PurchaseOrderDetails)
                .FirstOrDefault(s => s.ServiceId == id);
            if (item != null)
            {
                if (item.InvoiceDetails.Any() || item.PurchaseOrderDetails.Any())
                {
                    TempData["Error"] = $"Không thể xóa \"{item.ServiceName}\" vì đã phát sinh hóa đơn hoặc phiếu nhập kho chứa sản phẩm này.";
                    return RedirectToAction("Inventory");
                }
                _context.ServiceItems.Remove(item);
                _context.SaveChanges();
            }
            return RedirectToAction("Inventory");
        }

        // ========== CATEGORIES ==========
        public IActionResult Categories()
        {
            var categories = _context.Categories.ToList();
            return View("Categories", categories);
        }

        [HttpGet]
        public IActionResult CategoryCreate()
        {
            return View("CategoryForm", new Category());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult CategoryCreate(Category model)
        {
            if (!ModelState.IsValid) return View("CategoryForm", model);
            _context.Categories.Add(model);
            _context.SaveChanges();
            return RedirectToAction("Categories");
        }

        [HttpGet]
        public IActionResult CategoryEdit(int id)
        {
            var category = _context.Categories.Find(id);
            if (category == null) return NotFound();
            ViewBag.IsEdit = true;
            return View("CategoryForm", category);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult CategoryEdit(int id, Category model)
        {
            if (!ModelState.IsValid) { ViewBag.IsEdit = true; return View("CategoryForm", model); }
            var existing = _context.Categories.Find(id);
            if (existing == null) return NotFound();
            existing.CategoryName = model.CategoryName;
            _context.SaveChanges();
            return RedirectToAction("Categories");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult CategoryDelete(int id)
        {
            var category = _context.Categories
                .Include(c => c.ServiceItems)
                .FirstOrDefault(c => c.CategoryId == id);
            if (category != null)
            {
                if (category.ServiceItems.Any())
                {
                    TempData["Error"] = $"Không thể xóa danh mục \"{category.CategoryName}\" vì đang có {category.ServiceItems.Count} sản phẩm thuộc danh mục này.";
                    return RedirectToAction("Categories");
                }
                _context.Categories.Remove(category);
                _context.SaveChanges();
            }
            return RedirectToAction("Categories");
        }

        // ========== ROOM TYPES ==========
        public IActionResult RoomTypes()
        {
            var roomTypes = _context.RoomTypes.Include(rt => rt.Rooms).ToList();
            // Load images grouped by RoomTypeId for thumbnail display
            var allImages = _context.RoomImages.ToList();
            var imageMap = roomTypes.ToDictionary(
                rt => rt.RoomTypeId,
                rt => allImages.Where(i => i.RoomTypeId == rt.RoomTypeId).ToList()
            );
            ViewBag.ImageMap = imageMap;
            return View("RoomTypes", roomTypes);
        }

        [HttpGet]
        public IActionResult RoomTypeCreate()
        {
            return View("RoomTypeForm", new RoomType());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult RoomTypeCreate(RoomType model)
        {
            if (!ModelState.IsValid) return View("RoomTypeForm", model);
            _context.RoomTypes.Add(model);
            _context.SaveChanges();
            return RedirectToAction("RoomTypes");
        }

        [HttpGet]
        public IActionResult RoomTypeEdit(int id)
        {
            var roomType = _context.RoomTypes.Find(id);
            if (roomType == null) return NotFound();
            ViewBag.IsEdit = true;
            return View("RoomTypeForm", roomType);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult RoomTypeEdit(int id, RoomType model)
        {
            if (!ModelState.IsValid) { ViewBag.IsEdit = true; return View("RoomTypeForm", model); }
            var existing = _context.RoomTypes.Find(id);
            if (existing == null) return NotFound();
            existing.TypeName = model.TypeName;
            existing.PricePerHour = model.PricePerHour;
            existing.Description = model.Description;
            _context.SaveChanges();
            return RedirectToAction("RoomTypes");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult RoomTypeDelete(int id)
        {
            var roomType = _context.RoomTypes.Include(rt => rt.Rooms).FirstOrDefault(rt => rt.RoomTypeId == id);
            if (roomType != null)
            {
                if (roomType.Rooms.Any())
                {
                    TempData["Error"] = $"Không thể xóa loại phòng \"{roomType.TypeName}\" vì đang có {roomType.Rooms.Count} phòng thuộc loại này.";
                    return RedirectToAction("RoomTypes");
                }
                _context.RoomTypes.Remove(roomType);
                _context.SaveChanges();
            }
            return RedirectToAction("RoomTypes");
        }

        // ========== ROOMS ==========
        public IActionResult Rooms(string? search, int page = 1)
        {
            var query = _context.Rooms.Include(r => r.RoomType).AsQueryable();
            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(r => r.RoomName.Contains(search) || r.RoomType.TypeName.Contains(search));
            var rooms = PageList(query.OrderBy(r => r.RoomId), page, "Rooms", search);
            return View("Rooms", rooms);
        }

        [HttpGet]
        public IActionResult RoomCreate()
        {
            LoadRoomTypes();
            return View("RoomForm", new Room { Status = "Available" });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult RoomCreate(Room model)
        {
            ModelState.Remove("RoomType");
            if (!ModelState.IsValid) { LoadRoomTypes(model.RoomTypeId); return View("RoomForm", model); }
            _context.Rooms.Add(model);
            _context.SaveChanges();
            return RedirectToAction("Rooms");
        }

        [HttpGet]
        public IActionResult RoomEdit(int id)
        {
            var room = _context.Rooms.Find(id);
            if (room == null) return NotFound();
            LoadRoomTypes(room.RoomTypeId);
            ViewBag.IsEdit = true;
            return View("RoomForm", room);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult RoomEdit(int id, Room model)
        {
            ModelState.Remove("RoomType");
            if (!ModelState.IsValid) { LoadRoomTypes(model.RoomTypeId); ViewBag.IsEdit = true; return View("RoomForm", model); }
            var existing = _context.Rooms.Find(id);
            if (existing == null) return NotFound();
            existing.RoomName = model.RoomName;
            existing.RoomTypeId = model.RoomTypeId;
            existing.Status = model.Status;
            _context.SaveChanges();
            return RedirectToAction("Rooms");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult RoomDelete(int id)
        {
            var room = _context.Rooms
                .Include(r => r.Invoices)
                .Include(r => r.Bookings)
                .Include(r => r.Equipment)
                .FirstOrDefault(r => r.RoomId == id);
            if (room != null)
            {
                if (room.Invoices.Any() || room.Bookings.Any() || room.Equipment.Any())
                {
                    TempData["Error"] = $"Không thể xóa phòng \"{room.RoomName}\" vì đã có hóa đơn, booking hoặc thiết bị gắn với phòng này.";
                    return RedirectToAction("Rooms");
                }
                if (room.Status == "InUse")
                {
                    TempData["Error"] = $"Phòng \"{room.RoomName}\" đang được sử dụng, không thể xóa.";
                    return RedirectToAction("Rooms");
                }
                _context.Rooms.Remove(room);
                _context.SaveChanges();
            }
            return RedirectToAction("Rooms");
        }

        // ========== SUPPLIERS ==========
        public IActionResult Suppliers(string? search, int page = 1)
        {
            var query = _context.Suppliers.Include(s => s.PurchaseOrders).AsQueryable();
            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(s => s.SupplierName.Contains(search)
                    || (s.ContactName != null && s.ContactName.Contains(search))
                    || (s.Phone != null && s.Phone.Contains(search)));
            var suppliers = PageList(query.OrderBy(s => s.SupplierId), page, "Suppliers", search);
            return View("Suppliers", suppliers);
        }

        [HttpGet]
        public IActionResult SupplierCreate()
        {
            return View("SupplierForm", new Supplier());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult SupplierCreate(Supplier model)
        {
            if (!ModelState.IsValid) return View("SupplierForm", model);
            _context.Suppliers.Add(model);
            _context.SaveChanges();
            return RedirectToAction("Suppliers");
        }

        [HttpGet]
        public IActionResult SupplierEdit(int id)
        {
            var supplier = _context.Suppliers.Find(id);
            if (supplier == null) return NotFound();
            ViewBag.IsEdit = true;
            return View("SupplierForm", supplier);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult SupplierEdit(int id, Supplier model)
        {
            if (!ModelState.IsValid) { ViewBag.IsEdit = true; return View("SupplierForm", model); }
            var existing = _context.Suppliers.Find(id);
            if (existing == null) return NotFound();
            existing.SupplierName = model.SupplierName;
            existing.ContactName = model.ContactName;
            existing.Phone = model.Phone;
            existing.Address = model.Address;
            _context.SaveChanges();
            return RedirectToAction("Suppliers");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult SupplierDelete(int id)
        {
            var supplier = _context.Suppliers
                .Include(s => s.PurchaseOrders)
                .FirstOrDefault(s => s.SupplierId == id);
            if (supplier != null)
            {
                if (supplier.PurchaseOrders.Any())
                {
                    TempData["Error"] = $"Không thể xóa nhà cung cấp \"{supplier.SupplierName}\" vì đã có {supplier.PurchaseOrders.Count} phiếu nhập kho.";
                    return RedirectToAction("Suppliers");
                }
                _context.Suppliers.Remove(supplier);
                _context.SaveChanges();
            }
            return RedirectToAction("Suppliers");
        }

        // ========== USERS (Accounts) ==========
        public IActionResult Users(string? search, int page = 1)
        {
            var query = _context.Accounts.Include(a => a.Role).AsQueryable();
            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(a => a.Username.Contains(search)
                    || a.FullName.Contains(search)
                    || (a.Email != null && a.Email.Contains(search))
                    || a.Role.RoleName.Contains(search));
            var users = PageList(query.OrderBy(a => a.AccountId), page, "Users", search);
            return View("Users", users);
        }

        [HttpGet]
        public IActionResult UserCreate()
        {
            LoadRoles();
            return View("UserForm", new Account());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult UserCreate(Account model, string Password)
        {
            ModelState.Remove("Role");
            ModelState.Remove("PasswordHash");
            if (string.IsNullOrWhiteSpace(Password))
                ModelState.AddModelError("Password", "Password is required.");
            if (_context.Accounts.Any(a => a.Username == model.Username))
                ModelState.AddModelError("Username", "Username này đã tồn tại.");
            if (!ModelState.IsValid) { LoadRoles(); return View("UserForm", model); }
            model.PasswordHash = PasswordHelper.HashPassword(Password);
            model.CreatedAt = DateTime.Now;
            _context.Accounts.Add(model);
            _context.SaveChanges();
            return RedirectToAction("Users");
        }

        [HttpGet]
        public IActionResult UserEdit(int id)
        {
            var account = _context.Accounts.Find(id);
            if (account == null) return NotFound();
            LoadRoles(account.RoleId);
            ViewBag.IsEdit = true;
            return View("UserForm", account);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult UserEdit(int id, Account model, string? Password)
        {
            ModelState.Remove("Role");
            ModelState.Remove("PasswordHash");
            if (_context.Accounts.Any(a => a.Username == model.Username && a.AccountId != id))
                ModelState.AddModelError("Username", "Username này đã tồn tại.");
            if (!ModelState.IsValid) { LoadRoles(model.RoleId); ViewBag.IsEdit = true; return View("UserForm", model); }
            var existing = _context.Accounts.Find(id);
            if (existing == null) return NotFound();
            existing.FullName = model.FullName;
            existing.Username = model.Username;
            existing.Email = model.Email;
            existing.Phone = model.Phone;
            existing.RoleId = model.RoleId;
            if (!string.IsNullOrWhiteSpace(Password))
                existing.PasswordHash = PasswordHelper.HashPassword(Password);
            _context.SaveChanges();
            return RedirectToAction("Users");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult UserDelete(int id)
        {
            var account = _context.Accounts
                .Include(a => a.Invoices)
                .Include(a => a.Bookings)
                .Include(a => a.PurchaseOrders)
                .Include(a => a.MaintenanceLogs)
                .FirstOrDefault(a => a.AccountId == id);
            if (account != null)
            {
                if (account.Username == User.Identity?.Name)
                {
                    TempData["Error"] = "Bạn không thể xóa tài khoản đang đăng nhập.";
                    return RedirectToAction("Users");
                }
                if (account.Invoices.Any() || account.Bookings.Any() || account.PurchaseOrders.Any() || account.MaintenanceLogs.Any())
                {
                    TempData["Error"] = $"Không thể xóa tài khoản \"{account.Username}\" vì đã có hóa đơn, booking hoặc phiếu nhập gắn với tài khoản này.";
                    return RedirectToAction("Users");
                }
                _context.Accounts.Remove(account);
                _context.SaveChanges();
            }
            return RedirectToAction("Users");
        }

        // ========== HELPERS ==========
        private List<T> PageList<T>(IQueryable<T> query, int page, string pagerAction, string? search)
        {
            const int pageSize = 10;
            int totalCount = query.Count();
            int totalPages = Math.Max(1, (int)Math.Ceiling(totalCount / (double)pageSize));
            page = Math.Clamp(page, 1, totalPages);
            ViewBag.Page = page;
            ViewBag.TotalPages = totalPages;
            ViewBag.TotalCount = totalCount;
            ViewBag.PagerAction = pagerAction;
            ViewBag.Search = search;
            return query.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        }

        private void LoadCategories(int? selectedId = null)
        {
            ViewBag.Categories = new SelectList(_context.Categories.ToList(), "CategoryId", "CategoryName", selectedId);
        }

        private void LoadRoomTypes(int? selectedId = null)
        {
            ViewBag.RoomTypes = new SelectList(_context.RoomTypes.ToList(), "RoomTypeId", "TypeName", selectedId);
        }

        private void LoadRoles(int? selectedId = null)
        {
            ViewBag.Roles = new SelectList(_context.Roles.ToList(), "RoleId", "RoleName", selectedId);
        }

        private void LoadRooms(int? selectedId = null)
        {
            ViewBag.Rooms = new SelectList(_context.Rooms.ToList(), "RoomId", "RoomName", selectedId);
        }

        // ========== ROOM IMAGES (per RoomType) ==========
        // Redirect legacy URL /Admin/RoomImageCreate
        [HttpGet]
        public IActionResult RoomImageCreate() => RedirectToAction("RoomTypes");

        [HttpGet]
        public IActionResult RoomImageUpload(int roomTypeId)
        {
            var roomType = _context.RoomTypes.Find(roomTypeId);
            if (roomType == null) return NotFound();
            ViewBag.RoomType = roomType;
            ViewBag.Images = _context.RoomImages
                .Where(i => i.RoomTypeId == roomTypeId)
                .OrderBy(i => i.RoomImageId)
                .ToList();
            return View();
        }

        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> RoomImageUpload(int roomTypeId, List<IFormFile> files)
        {
            if (files == null || files.Count == 0)
            {
                TempData["Error"] = "Vui lòng chọn ít nhất một ảnh.";
                return RedirectToAction("RoomImageUpload", new { roomTypeId });
            }

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
            var uploadDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "rooms");
            Directory.CreateDirectory(uploadDir);

            int uploaded = 0;
            foreach (var file in files)
            {
                if (file.Length == 0) continue;
                var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
                if (!allowedExtensions.Contains(ext)) continue;

                var fileName = $"{Guid.NewGuid()}{ext}";
                var filePath = Path.Combine(uploadDir, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                    await file.CopyToAsync(stream);

                _context.RoomImages.Add(new RoomImage
                {
                    RoomTypeId = roomTypeId,
                    ImageUrl = $"/uploads/rooms/{fileName}"
                });
                uploaded++;
            }

            if (uploaded > 0)
            {
                await _context.SaveChangesAsync();
                TempData["Success"] = $"Đã tải lên {uploaded} ảnh thành công!";
            }
            else
            {
                TempData["Error"] = "Không có ảnh hợp lệ (chỉ chấp nhận .jpg, .jpeg, .png, .webp, .gif).";
            }

            return RedirectToAction("RoomImageUpload", new { roomTypeId });
        }

        [HttpPost, ValidateAntiForgeryToken]
        public IActionResult RoomImageDelete(int id)
        {
            var img = _context.RoomImages.Find(id);
            if (img == null) return NotFound();

            int roomTypeId = img.RoomTypeId;

            if (img.ImageUrl.StartsWith("/uploads/"))
            {
                var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", img.ImageUrl.TrimStart('/'));
                if (System.IO.File.Exists(filePath))
                    System.IO.File.Delete(filePath);
            }

            _context.RoomImages.Remove(img);
            _context.SaveChanges();
            TempData["Success"] = "Xóa ảnh thành công!";
            return RedirectToAction("RoomImageUpload", new { roomTypeId });
        }

    }
}
