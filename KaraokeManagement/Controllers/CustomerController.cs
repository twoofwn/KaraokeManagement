
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using KaraokeManagement.Helpers;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Threading.Tasks;
using KaraokeManagement.Services.CustomerServices;

namespace KaraokeManagement.Controllers
{
    public class CustomerController : Controller
    {
        private readonly RoomService _roomService;
        private readonly BookingService _bookingService;
        private readonly ServiceItemService _serviceItemService;
        private readonly KaraokeManagement.Services.CustomerServices.CustomerService _customerService;
        private readonly FeedbackService _feedbackService;

        public CustomerController(
            RoomService roomService,
            BookingService bookingService,
            ServiceItemService serviceItemService,
            KaraokeManagement.Services.CustomerServices.CustomerService customerService,
            FeedbackService feedbackService)
        {
            _roomService = roomService;
            _bookingService = bookingService;
            _serviceItemService = serviceItemService;
            _customerService = customerService;
            _feedbackService = feedbackService;
        }

        private int? GetCurrentCustomerId()
        {
            var customerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!string.IsNullOrEmpty(customerIdStr) && int.TryParse(customerIdStr, out int customerId))
                return customerId;
            return null;
        }

        public IActionResult Index() => View();

        [HttpGet]
        public async Task<IActionResult> Rooms(string searchString, decimal? minPrice, decimal? maxPrice, string sortOrder)
        {
            ViewBag.SearchString = searchString;
            ViewBag.MinPrice = minPrice;
            ViewBag.MaxPrice = maxPrice;
            ViewBag.SortOrder = sortOrder;

            var roomTypes = await _roomService.GetFilteredRoomTypesAsync(searchString, minPrice, maxPrice, sortOrder);
            return View(roomTypes);
        }

        [HttpGet]
        public async Task<IActionResult> RoomDetail(int id)
        {
            var roomType = await _roomService.GetRoomTypeDetailAsync(id);
            if (roomType == null) return NotFound();

            ViewBag.ActivePolicies = await _roomService.GetActivePricingPoliciesAsync();
            return View(roomType);
        }

        [HttpGet]
        public async Task<IActionResult> CheckRoomAvailability(int roomId, string date, string time, int duration)
        {
            try
            {
                if (!DateTime.TryParse($"{date} {time}", out DateTime startDateTime))
                    return Json(new { available = false, message = "Thời gian không hợp lệ." });

                DateTime endDateTime = startDateTime.AddMinutes(duration);
                bool isAvailable = await _bookingService.CheckAvailabilityAsync(roomId, startDateTime, endDateTime);

                return Json(new { available = isAvailable });
            }
            catch (Exception)
            {
                return Json(new { available = false, message = "Lỗi hệ thống khi kiểm tra phòng." });
            }
        }

        [HttpGet]
        public async Task<IActionResult> Services(string searchString, int? categoryId, decimal? minPrice, decimal? maxPrice, string sortOrder)
        {
            ViewBag.SearchString = searchString;
            ViewBag.CategoryId = categoryId;
            ViewBag.MinPrice = minPrice;
            ViewBag.MaxPrice = maxPrice;
            ViewBag.SortOrder = sortOrder;

            ViewBag.Categories = await _serviceItemService.GetAllCategoriesAsync();
            var services = await _serviceItemService.GetFilteredServicesAsync(searchString, categoryId, minPrice, maxPrice, sortOrder);
            return View(services);
        }

        [HttpGet]
        public async Task<IActionResult> ServiceDetail(int id)
        {
            var service = await _serviceItemService.GetServiceDetailAsync(id);
            if (service == null) return NotFound();

            var customerId = GetCurrentCustomerId();
            ViewBag.ActiveBookings = customerId.HasValue ? await _serviceItemService.GetActiveBookingsForCustomerAsync(customerId.Value) : new List<Booking>();
            ViewBag.SuggestedServices = await _serviceItemService.GetSuggestedServicesAsync(service.CategoryId, id);

            return View(service);
        }

        [Authorize(Roles = "Customer")]
        [HttpPost]
        public async Task<IActionResult> OrderService([FromBody] OrderServiceViewModel request)
        {
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return Json(new { success = false, message = "Vui lòng đăng nhập để sử dụng tính năng này." });

            try
            {
                var result = await _serviceItemService.OrderServiceAsync(customerId.Value, request.RoomId, request.ServiceId, request.Quantity, request.Notes);
                return Json(new { success = result.Success, message = result.Message });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        [Authorize(Roles = "Customer")]
        [HttpGet]
        public async Task<IActionResult> BookingConfirmation(int roomId, string roomName, string typeName, string bookingDate, string startTime, int duration, int guestCount = 2)
        {
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return RedirectToAction("CustomerLogin", "Auth");

            var customer = await _customerService.GetCustomerProfileAsync(customerId.Value);
            if (customer == null) return RedirectToAction("CustomerLogin", "Auth");

            ViewBag.RoomId = roomId;
            ViewBag.GuestCount = guestCount;
            if (!DateTime.TryParse($"{bookingDate} {startTime}", out DateTime startDateTime)) startDateTime = DateTime.Now;

            ViewBag.StartDateTimeISO = startDateTime.ToString("yyyy-MM-ddTHH:mm:ss");
            ViewBag.EndDateTimeISO = startDateTime.AddMinutes(duration).ToString("yyyy-MM-ddTHH:mm:ss");

            var model = await _bookingService.CalculateBookingConfirmationAsync(customer, roomName, typeName, startDateTime, duration);
            return View(model);
        }

        [Authorize(Roles = "Customer")]
        [HttpPost]
        public async Task<IActionResult> ConfirmAndSaveBooking([FromBody] Booking booking)
        {
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return Json(new { success = false, message = "Phiên đăng nhập đã hết hạn." });

            try
            {
                var result = await _bookingService.ConfirmAndSaveBookingAsync(booking, customerId.Value);
                return Json(new { success = result.Success, message = result.Message });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        [HttpGet]
        [Authorize(Roles = "Customer")]
        public async Task<IActionResult> Profile()
        {
            ViewData["ActiveNav"] = "profile";
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return RedirectToAction("CustomerLogin", "Auth");

            var customer = await _customerService.GetCustomerProfileAsync(customerId.Value);
            if (customer == null) return RedirectToAction("CustomerLogin", "Auth");

            return View(customer);
        }

        [HttpPost]
        [Authorize(Roles = "Customer")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateProfile(string fullName, string phone)
        {
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return RedirectToAction("CustomerLogin", "Auth");

            if (string.IsNullOrWhiteSpace(fullName) || string.IsNullOrWhiteSpace(phone))
            {
                TempData["ProfileError"] = "Họ tên và Số điện thoại không được để trống.";
                return RedirectToAction("Profile");
            }

            var result = await _customerService.UpdateProfileAsync(customerId.Value, fullName, phone);
            if (!result.Success)
            {
                TempData["ProfileError"] = result.Message;
                return RedirectToAction("Profile");
            }

            var customer = await _customerService.GetCustomerProfileAsync(customerId.Value);
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, customer.CustomerId.ToString()),
                new Claim(ClaimTypes.Name, customer.FullName),
                new Claim(ClaimTypes.Role, "Customer")
            };
            if (!string.IsNullOrEmpty(customer.Email)) claims.Add(new Claim(ClaimTypes.Email, customer.Email));

            await HttpContext.SignInAsync("CookieAuth", new ClaimsPrincipal(new ClaimsIdentity(claims, "CookieAuth")));
            TempData["ProfileSuccess"] = result.Message;

            return RedirectToAction("Profile");
        }

        [HttpPost]
        [Authorize(Roles = "Customer")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ChangePassword(string oldPassword, string newPassword, string confirmPassword)
        {
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return RedirectToAction("CustomerLogin", "Auth");

            if (string.IsNullOrEmpty(oldPassword) || string.IsNullOrEmpty(newPassword) || string.IsNullOrEmpty(confirmPassword))
            {
                TempData["PasswordError"] = "Vui lòng nhập đầy đủ thông tin mật khẩu.";
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

            var result = await _customerService.ChangePasswordAsync(customerId.Value, oldPassword, newPassword);
            if (!result.Success) TempData["PasswordError"] = result.Message;
            else TempData["PasswordSuccess"] = result.Message;

            return RedirectToAction("Profile");
        }

        [HttpGet]
        [Authorize(Roles = "Customer")]
        public async Task<IActionResult> Bookings()
        {
            ViewData["ActiveNav"] = "bookings";
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return RedirectToAction("CustomerLogin", "Auth");

            var bookings = await _bookingService.GetCustomerBookingsAsync(customerId.Value);
            return View(bookings);
        }

        [HttpGet]
        [Authorize(Roles = "Customer")]
        public async Task<IActionResult> BookingDetail(int id)
        {
            ViewData["ActiveNav"] = "bookings";
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return RedirectToAction("CustomerLogin", "Auth");

            var booking = await _bookingService.GetBookingDetailAsync(id, customerId.Value);
            if (booking == null) return NotFound();

            var invoice = booking.Invoices.FirstOrDefault();
            ViewBag.Invoice = invoice;
            ViewBag.ExistingReview = invoice != null ? await _feedbackService.GetReviewByBookingIdAsync(booking.BookingId) : null;
            ViewBag.Reports = await _feedbackService.GetReportsByBookingIdAsync(booking.BookingId, customerId.Value);
            ViewBag.CancellationReasons = await _bookingService.GetCancellationReasonsAsync();

            return View(booking);
        }

        [HttpPost]
        [Authorize(Roles = "Customer")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CancelBooking(
            int bookingId,
            int cancellationReasonId,
            string? cancellationReasonDetail)
        {
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return RedirectToAction("CustomerLogin", "Auth");

            var result = await _bookingService.CancelBookingAsync(
                bookingId,
                customerId.Value,
                cancellationReasonId,
                cancellationReasonDetail);

            if (result.Success)
                TempData["CancellationSuccess"] = result.Message;
            else
                TempData["CancellationError"] = result.Message;

            return RedirectToAction("BookingDetail", new { id = bookingId });
        }

        [HttpPost]
        [Authorize(Roles = "Customer")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SendBookingReport(int bookingId, string message)
        {
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return RedirectToAction("CustomerLogin", "Auth");

            var result = await _feedbackService.SendBookingReportAsync(customerId.Value, bookingId, message);
            if (!result.Success) TempData["ReportError"] = result.Message;
            else TempData["ReportSuccess"] = result.Message;

            return RedirectToAction("BookingDetail", new { id = bookingId });
        }

        [HttpPost]
        [Authorize(Roles = "Customer")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SubmitReview(int bookingId, int invoiceId, int rating, string? comment)
        {
            var customerId = GetCurrentCustomerId();
            if (!customerId.HasValue) return RedirectToAction("CustomerLogin", "Auth");

            var result = await _feedbackService.SubmitReviewAsync(customerId.Value, bookingId, invoiceId, rating, comment);
            if (!result.Success) TempData["ReviewError"] = result.Message;
            else TempData["ReviewSuccess"] = result.Message;

            return RedirectToAction("BookingDetail", new { id = bookingId });
        }
    }
}
