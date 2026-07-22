using KaraokeManagement.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Threading.Tasks;
using KaraokeManagement.Helpers;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;

namespace KaraokeManagement.Controllers
{
    public class CustomerController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        // Tiêm DbContext vào Controller
        public CustomerController(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpGet]
        public IActionResult Rooms(string searchString, decimal? minPrice, decimal? maxPrice, string sortOrder)
        {
            // Lưu lại các giá trị lọc vào ViewBag để hiển thị lại lên form sau khi load
            ViewBag.SearchString = searchString;
            ViewBag.MinPrice = minPrice;
            ViewBag.MaxPrice = maxPrice;
            ViewBag.SortOrder = sortOrder;

            // Truy vấn lấy dữ liệu RoomType
            var roomTypes = _context.RoomTypes.AsQueryable();

            // 1. Lọc theo tên phòng
            if (!string.IsNullOrEmpty(searchString))
            {
                roomTypes = roomTypes.Where(r => r.TypeName.Contains(searchString));
            }

            // 2. Lọc theo giá thấp nhất
            if (minPrice.HasValue)
            {
                roomTypes = roomTypes.Where(r => r.PricePerHour >= minPrice.Value);
            }

            // 3. Lọc theo giá cao nhất
            if (maxPrice.HasValue)
            {
                roomTypes = roomTypes.Where(r => r.PricePerHour <= maxPrice.Value);
            }

            // 4. Sắp xếp
            switch (sortOrder)
            {
                case "price-asc":
                    roomTypes = roomTypes.OrderBy(r => r.PricePerHour);
                    break;
                case "price-desc":
                    roomTypes = roomTypes.OrderByDescending(r => r.PricePerHour);
                    break;
                default:
                    roomTypes = roomTypes.OrderBy(r => r.TypeName); // Mặc định sắp xếp theo tên
                    break;
            }

            // Trả về view danh sách RoomType
            return View(roomTypes.ToList());
        }

        [HttpGet]
        public IActionResult RoomDetail(int id)
        {
            var roomType = _context.RoomTypes
                .Include(rt => rt.Rooms)
                .Include(rt => rt.RoomPrices)
                .FirstOrDefault(rt => rt.RoomTypeId == id);

            if (roomType == null)
            {
                return NotFound();
            }

            // Lấy danh sách các chính sách phụ thu đang hoạt động
            ViewBag.ActivePolicies = _context.PricingPolicies
                .Where(p => p.IsActive)
                .ToList();

            return View(roomType);
        }

        [HttpGet]
        public IActionResult Services(string searchString, int? categoryId, decimal? minPrice, decimal? maxPrice, string sortOrder)
        {
            // Lưu lại state để hiển thị lại trên form
            ViewBag.SearchString = searchString;
            ViewBag.CategoryId = categoryId;
            ViewBag.MinPrice = minPrice;
            ViewBag.MaxPrice = maxPrice;
            ViewBag.SortOrder = sortOrder;

            // Truyền danh sách Category ra View để làm thẻ Select Dropdown
            ViewBag.Categories = _context.Categories.ToList();

            // Khởi tạo query lấy ServiceItem kèm theo Category
            var services = _context.ServiceItems.Include(s => s.Category).AsQueryable();

            // 1. Lọc theo từ khóa (Tên dịch vụ)
            if (!string.IsNullOrEmpty(searchString))
            {
                services = services.Where(s => s.ServiceName.Contains(searchString));
            }

            // 2. Lọc theo danh mục
            if (categoryId.HasValue)
            {
                services = services.Where(s => s.CategoryId == categoryId.Value);
            }

            // 3. Lọc theo giá Min/Max
            if (minPrice.HasValue)
            {
                services = services.Where(s => s.SellingPrice >= minPrice.Value);
            }
            if (maxPrice.HasValue)
            {
                services = services.Where(s => s.SellingPrice <= maxPrice.Value);
            }

            // 4. Sắp xếp
            switch (sortOrder)
            {
                case "price-asc":
                    services = services.OrderBy(s => s.SellingPrice);
                    break;
                case "price-desc":
                    services = services.OrderByDescending(s => s.SellingPrice);
                    break;
                case "name-asc":
                    services = services.OrderBy(s => s.ServiceName);
                    break;
                case "name-desc":
                    services = services.OrderByDescending(s => s.ServiceName);
                    break;
                default:
                    services = services.OrderBy(s => s.ServiceName);
                    break;
            }

            return View(services.ToList());
        }

        [HttpGet]
        public IActionResult ServiceDetail(int id)
        {
            // Lấy thông tin dịch vụ hiện tại, kèm theo Category
            var service = _context.ServiceItems
                .Include(s => s.Category)
                .FirstOrDefault(s => s.ServiceId == id);

            if (service == null)
            {
                return NotFound(); // Trả về 404 nếu không tìm thấy ID
            }

            // Lấy các dịch vụ gợi ý (cùng danh mục, nhưng khác dịch vụ hiện tại) - Lấy tối đa 5 cái
            var suggestedServices = _context.ServiceItems
                .Include(s => s.Category)
                .Where(s => s.CategoryId == service.CategoryId && s.ServiceId != id)
                .Take(5)
                .ToList();

            // Truyền danh sách gợi ý qua ViewBag
            ViewBag.SuggestedServices = suggestedServices;

            // Trả Model ServiceItem ra View
            return View(service);
        }

        [HttpGet]
        public IActionResult BookingConfirmation(string roomName, string typeName, string bookingDate, string startTime, int duration)
        {
            // Truyền dữ liệu sang View thông qua ViewBag
            ViewBag.RoomName = roomName;
            ViewBag.TypeName = typeName;
            ViewBag.BookingDate = bookingDate;
            ViewBag.StartTime = startTime;
            ViewBag.Duration = duration;

            return View();
        }

        [HttpGet]
        [Authorize(Roles = "Customer")]
        public async Task<IActionResult> Profile()
        {
            ViewData["ActiveNav"] = "profile";
            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            var customer = await _context.Customers
                .Include(c => c.Tier)
                .FirstOrDefaultAsync(c => c.CustomerId == customerId);

            if (customer == null)
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            return View(customer);
        }

        [HttpPost]
        [Authorize(Roles = "Customer")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateProfile(string fullName, string phone)
        {
            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            var customer = await _context.Customers.FindAsync(customerId);
            if (customer == null)
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            if (string.IsNullOrWhiteSpace(fullName) || string.IsNullOrWhiteSpace(phone))
            {
                TempData["ProfileError"] = "Họ tên và Số điện thoại không được để trống.";
                return RedirectToAction("Profile");
            }

            // Check duplicate phone
            var isPhoneDup = await _context.Customers.AnyAsync(c => c.Phone == phone && c.CustomerId != customerId);
            if (isPhoneDup)
            {
                TempData["ProfileError"] = "Số điện thoại này đã được sử dụng bởi tài khoản khác.";
                return RedirectToAction("Profile");
            }

            customer.FullName = fullName.Trim();
            customer.Phone = phone.Trim();

            _context.Customers.Update(customer);
            await _context.SaveChangesAsync();

            // Refresh cookie claims with updated FullName
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, customer.CustomerId.ToString()),
                new Claim(ClaimTypes.Name, customer.FullName),
                new Claim(ClaimTypes.Role, "Customer")
            };
            if (!string.IsNullOrEmpty(customer.Email))
            {
                claims.Add(new Claim(ClaimTypes.Email, customer.Email));
            }

            var claimsIdentity = new ClaimsIdentity(claims, "CookieAuth");
            await HttpContext.SignInAsync("CookieAuth", new ClaimsPrincipal(claimsIdentity));

            TempData["ProfileSuccess"] = "Cập nhật thông tin cá nhân thành công!";
            return RedirectToAction("Profile");
        }

        [HttpPost]
        [Authorize(Roles = "Customer")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ChangePassword(string oldPassword, string newPassword, string confirmPassword)
        {
            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            var customer = await _context.Customers.FindAsync(customerId);
            if (customer == null)
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            if (string.IsNullOrEmpty(oldPassword) || string.IsNullOrEmpty(newPassword) || string.IsNullOrEmpty(confirmPassword))
            {
                TempData["PasswordError"] = "Vui lòng nhập đầy đủ thông tin mật khẩu.";
                return RedirectToAction("Profile");
            }

            if (!PasswordHelper.VerifyPassword(oldPassword, customer.PasswordHash))
            {
                TempData["PasswordError"] = "Mật khẩu cũ không chính xác.";
                return RedirectToAction("Profile");
            }

            if (newPassword != confirmPassword)
            {
                TempData["PasswordError"] = "Mật khẩu mới và xác nhận mật khẩu không khớp.";
                return RedirectToAction("Profile");
            }

            if (newPassword.Length < 6)
            {
                TempData["PasswordError"] = "Mật khẩu mới phải có ít nhất 6 ký tự.";
                return RedirectToAction("Profile");
            }

            customer.PasswordHash = PasswordHelper.HashPassword(newPassword);
            _context.Customers.Update(customer);
            await _context.SaveChangesAsync();

            TempData["PasswordSuccess"] = "Đổi mật khẩu thành công!";
            return RedirectToAction("Profile");
        }

        // ===== BOOKING HISTORY =====

        [HttpGet]
        [Authorize(Roles = "Customer")]
        public async Task<IActionResult> Bookings()
        {
            ViewData["ActiveNav"] = "bookings";

            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            var bookings = await _context.Bookings
                .Where(b => b.CustomerId == customerId)
                .Include(b => b.Room)
                    .ThenInclude(r => r.RoomType)
                .Include(b => b.Invoices)
                .OrderByDescending(b => b.StartTime)
                .ToListAsync();

            return View(bookings);
        }

        [HttpGet]
        [Authorize(Roles = "Customer")]
        public async Task<IActionResult> BookingDetail(int id)
        {
            ViewData["ActiveNav"] = "bookings";

            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            var booking = await _context.Bookings
                .Include(b => b.Room)
                    .ThenInclude(r => r.RoomType)
                .Include(b => b.Invoices)
                    .ThenInclude(i => i.InvoiceDetails)
                        .ThenInclude(d => d.Service)
                .Include(b => b.Invoices)
                    .ThenInclude(i => i.PaymentTransactions)
                .FirstOrDefaultAsync(b => b.BookingId == id);

            if (booking == null || booking.CustomerId != customerId)
            {
                return NotFound();
            }

            // Load existing review if any (for Completed bookings)
            CustomerReview? existingReview = null;
            Invoice? invoice = booking.Invoices.FirstOrDefault();
            if (invoice != null)
            {
                existingReview = await _context.CustomerReviews
                    .FirstOrDefaultAsync(r => r.InvoiceId == invoice.InvoiceId && r.CustomerId == customerId);
            }

            // Load reports sent by this customer for this booking
            var reports = await _context.NotificationLogs
                .Where(n => n.BookingId == booking.BookingId && n.CustomerId == customerId)
                .OrderByDescending(n => n.SentAt)
                .ToListAsync();

            ViewBag.ExistingReview = existingReview;
            ViewBag.Invoice = invoice;
            ViewBag.Reports = reports;

            return View(booking);
        }

        [HttpPost]
        [Authorize(Roles = "Customer")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SendBookingReport(int bookingId, string message)
        {
            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            var booking = await _context.Bookings.FirstOrDefaultAsync(b => b.BookingId == bookingId);

            // IDOR protection + status check
            if (booking == null || booking.CustomerId != customerId)
            {
                return Forbid();
            }

            if (booking.Status != "CheckedIn")
            {
                TempData["ReportError"] = "Chỉ có thể gửi báo cáo khi phòng đang được sử dụng.";
                return RedirectToAction("BookingDetail", new { id = bookingId });
            }

            if (string.IsNullOrWhiteSpace(message))
            {
                TempData["ReportError"] = "Vui lòng nhập nội dung báo cáo.";
                return RedirectToAction("BookingDetail", new { id = bookingId });
            }

            var notification = new NotificationLog
            {
                BookingId = bookingId,
                CustomerId = customerId,
                Channel = "Web",
                Recipient = "Receptionist",
                MessageContent = message.Trim(),
                SentStatus = "Sent",
                SentAt = DateTime.Now
            };

            _context.NotificationLogs.Add(notification);
            await _context.SaveChangesAsync();

            TempData["ReportSuccess"] = "Báo cáo sự cố đã được gửi thành công! Nhân viên sẽ xử lý sớm nhất.";
            return RedirectToAction("BookingDetail", new { id = bookingId });
        }

        [HttpPost]
        [Authorize(Roles = "Customer")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SubmitReview(int bookingId, int invoiceId, int rating, string? comment)
        {
            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            // Verify booking belongs to customer
            var booking = await _context.Bookings
                .Include(b => b.Invoices)
                .FirstOrDefaultAsync(b => b.BookingId == bookingId);

            if (booking == null || booking.CustomerId != customerId)
            {
                return Forbid();
            }

            if (booking.Status != "Completed")
            {
                TempData["ReviewError"] = "Chỉ có thể đánh giá sau khi hoàn thành phòng hát.";
                return RedirectToAction("BookingDetail", new { id = bookingId });
            }

            // Verify invoice belongs to this booking
            var invoice = booking.Invoices.FirstOrDefault(i => i.InvoiceId == invoiceId);
            if (invoice == null)
            {
                TempData["ReviewError"] = "Không tìm thấy hóa đơn liên kết.";
                return RedirectToAction("BookingDetail", new { id = bookingId });
            }

            // Check duplicate review
            var existingReview = await _context.CustomerReviews
                .AnyAsync(r => r.InvoiceId == invoiceId && r.CustomerId == customerId);

            if (existingReview)
            {
                TempData["ReviewError"] = "Bạn đã đánh giá cho lượt hát này rồi.";
                return RedirectToAction("BookingDetail", new { id = bookingId });
            }

            if (rating < 1 || rating > 5)
            {
                TempData["ReviewError"] = "Vui lòng chọn số sao từ 1 đến 5.";
                return RedirectToAction("BookingDetail", new { id = bookingId });
            }

            var review = new CustomerReview
            {
                InvoiceId = invoiceId,
                CustomerId = customerId,
                Rating = rating,
                Comment = comment?.Trim(),
                CreatedAt = DateTime.Now
            };

            _context.CustomerReviews.Add(review);
            await _context.SaveChangesAsync();

            TempData["ReviewSuccess"] = "Cảm ơn bạn đã đánh giá! Ý kiến của bạn giúp chúng tôi phục vụ tốt hơn.";
            return RedirectToAction("BookingDetail", new { id = bookingId });
        }
    }
}
