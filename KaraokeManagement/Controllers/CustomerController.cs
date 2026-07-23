using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

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
        public IActionResult CheckRoomAvailability(int roomId, string date, string time, int duration)
        {
            try
            {
                // Gộp ngày và giờ gửi từ View lại
                if (!DateTime.TryParse($"{date} {time}", out DateTime startDateTime))
                {
                    return Json(new { available = false, message = "Thời gian không hợp lệ." });
                }

                // Tính thời gian kết thúc dự kiến (cộng thêm số phút hát)
                DateTime endDateTime = startDateTime.AddMinutes(duration);

                // Logic check trùng: 
                // Lịch bị trùng khi: Giờ bắt đầu của người cũ < Giờ kết thúc của người mới
                // VÀ Giờ kết thúc của người cũ > Giờ bắt đầu của người mới
                bool isConflict = _context.Bookings.Any(b =>
                    b.RoomId == roomId &&
                    b.Status != "Cancelled" && b.Status != "Đã hủy" && // Bỏ qua các phòng đã bị hủy (Sửa theo text Status trong DB của bạn)
                    b.StartTime < endDateTime &&
                    (b.EndTime == null || b.EndTime > startDateTime)
                );

                return Json(new { available = !isConflict });
            }
            catch (System.Exception)
            {
                return Json(new { available = false, message = "Lỗi hệ thống khi kiểm tra phòng." });
            }
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

            //Lấy các booking hiện tại đang hát
            var activeBookings = new List<Booking>();
            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (!string.IsNullOrEmpty(customerIdStr) && int.TryParse(customerIdStr, out int customerId))
            {
                var now = DateTime.Now;
                activeBookings = _context.Bookings
                    .Include(b => b.Room)
                    .Where(b => b.CustomerId == customerId
                             && b.Status == "CheckedIn"
                             && b.StartTime <= now
                             && (b.EndTime == null || b.EndTime >= now))
                    .ToList();
            }
            ViewBag.ActiveBookings = activeBookings;

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

        [Authorize(Roles = "Customer")]
        [HttpPost]
        public async Task<IActionResult> OrderService([FromBody] OrderServiceViewModel request)
        {
            try
            {
                // 1. Lấy thông tin khách hàng đang đăng nhập
                var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
                {
                    return Json(new { success = false, message = "Vui lòng đăng nhập để sử dụng tính năng này." });
                }

                // 2. Tìm Booking hiện tại của khách hàng ở phòng đó (Đang CheckedIn)
                var now = DateTime.Now;
                var activeBooking = await _context.Bookings
                    .FirstOrDefaultAsync(b => b.CustomerId == customerId
                                           && b.RoomId == request.RoomId
                                           && b.Status == "CheckedIn"
                                           && b.StartTime <= now
                                           && (b.EndTime == null || b.EndTime >= now));

                if (activeBooking == null)
                {
                    return Json(new { success = false, message = "Không tìm thấy phiên hát đang hoạt động của bạn tại phòng này." });
                }

                // 3. Lấy thông tin Dịch vụ (Món ăn/Đồ uống) để lấy Đơn giá
                var serviceItem = await _context.ServiceItems.FindAsync(request.ServiceId);
                if (serviceItem == null)
                {
                    return Json(new { success = false, message = "Dịch vụ không tồn tại." });
                }

                // Kiểm tra tồn kho (nếu có)
                if (serviceItem.StockQuantity.HasValue && serviceItem.StockQuantity.Value < request.Quantity)
                {
                    return Json(new { success = false, message = $"Rất tiếc, kho chỉ còn {serviceItem.StockQuantity.Value} phần." });
                }

                // 4. Tìm Hóa Đơn (Invoice) của Booking này
                var currentInvoice = await _context.Invoices
                    .FirstOrDefaultAsync(i => i.BookingId == activeBooking.BookingId);

                // Nếu chưa có Invoice -> Tạo mới
                if (currentInvoice == null)
                {
                    currentInvoice = new Invoice
                    {
                        BookingId = activeBooking.BookingId,
                        RoomId = activeBooking.RoomId,
                        ReceptionistId = 4,
                        CheckInTime = activeBooking.StartTime,
                        Status = "Unpaid",
                        RoomTotal = 0,
                        ServiceTotal = 0,
                        GrandTotal = 0,
                        DiscountAmount = 0
                    };
                    _context.Invoices.Add(currentInvoice);
                    await _context.SaveChangesAsync(); // Lưu để có ID của Invoice
                }

                // 5. Tạo Chi tiết Hóa đơn (Order Detail)
                decimal unitPrice = serviceItem.SellingPrice;
                decimal totalPrice = unitPrice * request.Quantity;

                var invoiceDetail = new InvoiceDetail
                {
                    InvoiceId = currentInvoice.InvoiceId,
                    ServiceId = request.ServiceId,
                    Quantity = request.Quantity,
                    UnitPrice = unitPrice,
                    IsService = true,
                    IsFulFilled = false,
                    Note = request.Notes
                };
                _context.InvoiceDetails.Add(invoiceDetail);

                // Trừ tồn kho (nếu cần thiết)
                if (serviceItem.StockQuantity.HasValue)
                {
                    serviceItem.StockQuantity -= request.Quantity;
                }

                // 6. Cập nhật tổng tiền Service vào Invoice
                currentInvoice.ServiceTotal = (currentInvoice.ServiceTotal ?? 0) + totalPrice;
                currentInvoice.GrandTotal = (currentInvoice.RoomTotal ?? 0) + currentInvoice.ServiceTotal - (currentInvoice.DiscountAmount ?? 0);

                await _context.SaveChangesAsync();

                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        [Authorize(Roles = "Customer")]
        [HttpGet]
        public IActionResult BookingConfirmation(int roomId, string roomName, string typeName, string bookingDate, string startTime, int duration, int guestCount = 2)
        {
            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
            {
                return RedirectToAction("CustomerLogin", "Auth");
            }

            var customer = _context.Customers.FirstOrDefault(c => c.CustomerId == customerId);
            if (customer == null) return RedirectToAction("CustomerLogin", "Auth");

            // QUAN TRỌNG: Truyền qua ViewBag để View render vào script JS
            ViewBag.RoomId = roomId;
            ViewBag.GuestCount = guestCount;

            // --- (Phần thuật toán tính giá tiền giữ nguyên như cũ của bạn) ---
            DateTime startDateTime;
            if (!DateTime.TryParse($"{bookingDate} {startTime}", out startDateTime)) startDateTime = DateTime.Now;
            DateTime endDateTime = startDateTime.AddMinutes(duration);

            ViewBag.StartDateTimeISO = startDateTime.ToString("yyyy-MM-ddTHH:mm:ss");
            ViewBag.EndDateTimeISO = endDateTime.ToString("yyyy-MM-ddTHH:mm:ss");

            var roomTypeObj = _context.RoomTypes.Include(rt => rt.RoomPrices).FirstOrDefault(rt => rt.TypeName == typeName);
            decimal basePrice = 0;
            decimal fallbackPrice = roomTypeObj?.PricePerHour ?? 0;

            if (roomTypeObj != null && roomTypeObj.RoomPrices.Any())
            {
                DateTime currentCalcTime = startDateTime;
                while (currentCalcTime < endDateTime)
                {
                    var timeOfDay = currentCalcTime.TimeOfDay;
                    var activePrice = roomTypeObj.RoomPrices.FirstOrDefault(p => p.StartTime <= timeOfDay && p.EndTime > timeOfDay);
                    decimal currentRate = activePrice?.PricePerHour ?? fallbackPrice;
                    DateTime nextBlockEnd = activePrice != null ? currentCalcTime.Date.Add(activePrice.EndTime) : currentCalcTime.Date.AddDays(1);
                    if (nextBlockEnd > endDateTime) nextBlockEnd = endDateTime;
                    var minutesInBlock = (decimal)(nextBlockEnd - currentCalcTime).TotalMinutes;
                    basePrice += (minutesInBlock / 60m) * currentRate;
                    currentCalcTime = nextBlockEnd;
                }
            }
            else { basePrice = (duration / 60m) * fallbackPrice; }

            decimal surchargeAmount = 0;
            string surchargeNote = "";
            if (startDateTime.DayOfWeek == DayOfWeek.Saturday || startDateTime.DayOfWeek == DayOfWeek.Sunday)
            {
                var weekendPolicy = _context.PricingPolicies.FirstOrDefault(p => p.IsActive && p.PolicyType == "Weekend");
                if (weekendPolicy != null)
                {
                    surchargeAmount = basePrice * (weekendPolicy.Value / 100m);
                    surchargeNote = $"{weekendPolicy.PolicyName} ({weekendPolicy.Value.ToString("0.##")}%)";
                }
            }

            var model = new BookingConfirmationViewModel
            {
                CustomerName = customer.FullName,
                Phone = customer.Phone,
                Email = customer.Email,
                RoomName = roomName,
                TypeName = typeName,
                BookingDate = bookingDate,
                StartTime = startTime,
                Duration = duration,
                BasePrice = basePrice,
                SurchargeAmount = surchargeAmount,
                SurchargeNote = surchargeNote,
                EstimatedTotalPrice = basePrice + surchargeAmount
            };

            return View(model);
        }

        [Authorize(Roles = "Customer")]
        [HttpPost]
        public async Task<IActionResult> ConfirmAndSaveBooking([FromBody] Booking booking)
        {
            try
            {
                // Lấy CustomerId từ phiên đăng nhập
                var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(customerIdStr) || !int.TryParse(customerIdStr, out int customerId))
                {
                    return Json(new { success = false, message = "Phiên đăng nhập đã hết hạn." });
                }

                // Gán các thuộc tính còn thiếu
                booking.CustomerId = customerId;
                booking.BookingTime = DateTime.Now;
                booking.Status = "Confirmed"; // Trạng thái ban đầu
                if (booking.GuestCount <= 0) booking.GuestCount = 2;

                // Lấy tạm 1 Admin gắn vào CreatedById do Database yêu cầu NOT NULL
                var adminAccount = await _context.Accounts.FirstOrDefaultAsync();
                booking.CreatedById = adminAccount != null ? adminAccount.AccountId : 1;

                // Validate lại lần cuối xem phòng có bị ai giành mất không
                bool isConflict = await _context.Bookings.AnyAsync(b =>
                    b.RoomId == booking.RoomId &&
                    b.Status != "Cancelled" && b.Status != "Đã hủy" &&
                    b.StartTime < booking.EndTime &&
                    (b.EndTime == null || b.EndTime > booking.StartTime)
                );

                if (isConflict)
                {
                    return Json(new { success = false, message = "Rất tiếc! Phòng này vừa được khách khác đặt. Vui lòng chọn giờ hoặc phòng khác!" });
                }

                _context.Bookings.Add(booking);
                await _context.SaveChangesAsync();

                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Lỗi hệ thống: " + ex.Message });
            }
        }
    }
}
