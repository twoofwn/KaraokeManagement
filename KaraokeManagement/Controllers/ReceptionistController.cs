using KaraokeManagement.Services.ReceptionistServices;
using KaraokeManagement.ViewModel;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace KaraokeManagement.Controllers
{
    [Authorize(Roles = "Receptionist")]
    public class ReceptionistController : Controller
    {
        // Khai báo tiêm trực tiếp các Class Service
        private readonly DashboardService _dashboardService;
        private readonly OrderService _orderService;
        private readonly RoomBookingService _bookingService;
        private readonly PaymentService _paymentService;
        private readonly CustomerService _customerService;
        private readonly InvoiceService _invoiceService;

        public ReceptionistController(
            DashboardService dashboardService,
            OrderService orderService,
            RoomBookingService bookingService,
            PaymentService paymentService,
            CustomerService customerService,
            InvoiceService invoiceService)
        {
            _dashboardService = dashboardService;
            _orderService = orderService;
            _bookingService = bookingService;
            _paymentService = paymentService;
            _customerService = customerService;
            _invoiceService = invoiceService;
        }

        [HttpGet]
        public async Task<IActionResult> Index(string searchString, string roomType, string status)
        {
            var vm = await _dashboardService.GetDashboardAsync(searchString, roomType, status);
            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> Detail(int roomId)
        {
            var vm = await _orderService.GetRoomDetailAsync(roomId, User.Identity?.Name);
            if (vm == null) return RedirectToAction("Index");
            return View(vm);
        }

        [HttpPost]
        public async Task<IActionResult> AddServiceItem([FromBody] AddServiceRequest request)
        {
            var result = await _orderService.AddServiceItemAsync(request);
            return Json(new { success = result.success, message = result.message });
        }

        [HttpPost]
        public async Task<IActionResult> UpdateServiceItem([FromBody] UpdateServiceRequest request)
        {
            var result = await _orderService.UpdateServiceItemAsync(request);
            return Json(new { success = result.success, message = result.message });
        }

        [HttpPost]
        public async Task<IActionResult> RemoveServiceItem([FromBody] RemoveServiceRequest request)
        {
            var result = await _orderService.RemoveServiceItemAsync(request);
            return Json(new { success = result.success, message = result.message });
        }

        [HttpPost]
        public async Task<IActionResult> ChangeRoom([FromBody] ChangeRoomRequest request)
        {
            var staffIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("AccountId")?.Value;
            int staffId = int.TryParse(staffIdClaim, out int id) ? id : 1;

            var result = await _bookingService.ChangeRoomAsync(request, staffId);
            return Json(new { success = result.success, message = result.message });
        }

        [HttpPost]
        public async Task<IActionResult> ProcessPayment([FromBody] PaymentRequest request)
        {
            var result = await _paymentService.ProcessPaymentFastAsync(request);
            return Json(new { success = result.success, message = result.message });
        }

        [HttpGet]
        public async Task<IActionResult> CheckIn(int? roomId)
        {
            var vm = await _bookingService.GetCheckInViewModelAsync(roomId, User.Identity?.Name ?? "Nhân viên");
            return View(vm);
        }

        [HttpPost]
        public async Task<IActionResult> CheckIn(CheckInViewModel model)
        {
            var success = await _bookingService.ProcessCheckInAsync(model, User.Identity?.Name);
            if (!success)
            {
                ModelState.AddModelError("", "Phòng được chọn không tồn tại.");
                var freshModel = await _bookingService.GetCheckInViewModelAsync(model.RoomId, User.Identity?.Name ?? "Nhân viên");
                return View(freshModel);
            }
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Checkout(int invoiceId)
        {
            var vm = await _paymentService.GetCheckoutViewModelAsync(invoiceId);
            if (vm == null) return NotFound("Không tìm thấy hóa đơn cần thanh toán.");
            return View(vm);
        }

        [HttpPost]
        public async Task<IActionResult> Checkout(CheckoutViewModel model)
        {
            var success = await _paymentService.ProcessCheckoutAsync(model);
            if (!success) return NotFound("Không tìm thấy hóa đơn cần thanh toán.");
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> GetCustomerByPhone(string phone)
        {
            return Json(await _customerService.GetCustomerByPhoneAsync(phone));
        }

        [HttpPost]
        public async Task<IActionResult> CreateCustomer([FromBody] CreateCustomerRequest request)
        {
            var result = await _customerService.CreateCustomerAsync(request);
            if (!result.success) return Json(new { success = false, message = result.message });
            return Json(new { success = true, data = result.data });
        }

        [HttpGet]
        public async Task<IActionResult> InvoiceHistory(string searchString, string customerFilter, DateTime? fromDate, DateTime? toDate, string status = "All", int page = 1)
        {
            var vm = await _invoiceService.GetInvoiceHistoryAsync(searchString, customerFilter, fromDate, toDate, status, page);
            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> GetInvoiceDetail(int invoiceId)
        {
            var vm = await _invoiceService.GetInvoiceDetailAsync(invoiceId);
            if (vm == null) return NotFound("Không tìm thấy thông tin hóa đơn.");
            return PartialView("_InvoiceDetailModal", vm);
        }
    }
}