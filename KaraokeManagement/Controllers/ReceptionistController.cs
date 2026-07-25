using KaraokeManagement.Services;
using KaraokeManagement.Services.StaffServices;
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
        private readonly DashboardService _dashboardService;
        private readonly OrderService _orderService;
        private readonly RoomBookingService _bookingService;
        private readonly PaymentService _paymentService;
        private readonly CustomerService _customerService;
        private readonly InvoiceService _invoiceService;
        private readonly ReceptionistBookingService _recepBookingService;
        private readonly StaffService _staffService;
        private readonly IScheduleService _scheduleService;

        public ReceptionistController(
            DashboardService dashboardService,
            OrderService orderService,
            RoomBookingService bookingService,
            PaymentService paymentService,
            CustomerService customerService,
            InvoiceService invoiceService,
            ReceptionistBookingService recepBookingService,
            StaffService staffService,
            IScheduleService scheduleService)
        {
            _dashboardService = dashboardService;
            _orderService = orderService;
            _bookingService = bookingService;
            _paymentService = paymentService;
            _customerService = customerService;
            _invoiceService = invoiceService;
            _recepBookingService = recepBookingService;
            _staffService = staffService;
            _scheduleService = scheduleService;
        }

        // Dashboard
        [HttpGet]
        public async Task<IActionResult> Index(string searchString, string roomType, string status)
        {
            var vm = await _dashboardService.GetDashboardAsync(searchString, roomType, status);
            return View(vm);
        }

        // Tim khach hang qua sdt
        [HttpGet]
        public async Task<IActionResult> GetCustomerByPhone(string phone)
        {
            return Json(await _customerService.GetCustomerByPhoneAsync(phone));
        }

        // Tao khach hang moi
        [HttpPost]
        public async Task<IActionResult> CreateCustomer([FromBody] CreateCustomerRequest request)
        {
            var result = await _customerService.CreateCustomerAsync(request);
            if (!result.success) return Json(new { success = false, message = result.message });
            return Json(new { success = true, data = result.data });
        }


        // Check-in
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

        // List pending booking
        [HttpGet]
        public async Task<IActionResult> ListBooking(
        string searchString,
        string customerFilter,
        string dateRange = "all",
        string status = "Pending",
        int page = 1)
        {
            var viewModel = await _recepBookingService.GetListBookingAsync(searchString, customerFilter, dateRange, status, page);
            return View(viewModel);
        }

        // Update room status
        [HttpPost]
        public async Task<IActionResult> UpdateBookingStatus([FromBody] UpdateBookingStatusRequest request)
        {
            var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("AccountId");
            if (!int.TryParse(accountIdClaim, out int accountId) || accountId <= 0)
            {
                return Json(new { success = false, message = "Phiên làm việc hết hạn hoặc không xác định được tài khoản thao tác." });
            }

            var result = await _recepBookingService.UpdateBookingStatusAsync(request, accountId);
            return Json(new { success = result.success, message = result.message });
        }


        // Lay confirmed booking list
        [HttpGet]
        public async Task<IActionResult> BookingConfirm(string search = "")
        {
            var pendingBookings = await _recepBookingService.GetBookingConfirmListAsync(search);
            return View(pendingBookings);
        }

        // Lay confirmed booking detail
        [HttpGet]
        public async Task<IActionResult> BookingConfirmDetail(int id)
        {
            var viewModel = await _recepBookingService.GetBookingConfirmDetailAsync(id);
            if (viewModel == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy thông tin đơn đặt phòng này!";
                return RedirectToAction("BookingConfirm");
            }

            return View(viewModel);
        }

        // Chuyen trang thai tu confirmed sang checkedIn
        [HttpPost]
        public async Task<IActionResult> ConfirmCheckIn(CheckInDetailViewModel model)
        {
            var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("AccountId");
            if (!int.TryParse(accountIdClaim, out int accountId) || accountId <= 0)
            {
                return Json(new { success = false, message = "Phiên làm việc hết hạn hoặc không xác định được tài khoản thao tác." });
            }

            bool success = await _recepBookingService.ConfirmCheckInAsync(model, accountId);
            if (!success) return NotFound();

            TempData["SuccessMessage"] = "Check-in thành công!";
            return RedirectToAction("Index");
        }

        // Huy booking
        [HttpPost]
        public async Task<IActionResult> CancelBooking(int bookingId)
        {
            await _recepBookingService.CancelBookingAsync(bookingId);
            TempData["SuccessMessage"] = "Đã hủy đơn đặt phòng thành công.";
            return RedirectToAction("BookingConfirm");
        }


        // Chi tiet phong
        [HttpGet]
        public async Task<IActionResult> Detail(int roomId)
        {
            var vm = await _orderService.GetRoomDetailAsync(roomId, User.Identity?.Name);
            if (vm == null) return RedirectToAction("Index");
            return View(vm);
        }

        // CRUD service item
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

        // Change room
        [HttpPost]
        public async Task<IActionResult> ChangeRoom([FromBody] ChangeRoomRequest request)
        {
            var staffIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("AccountId")?.Value;
            int staffId = int.TryParse(staffIdClaim, out int id) ? id : 1;

            var result = await _bookingService.ChangeRoomAsync(request, staffId);
            return Json(new { success = result.success, message = result.message });
        }

        [HttpGet]
        public async Task<IActionResult> GetInvoiceRoomState(int invoiceId)
        {
            var state = await _bookingService.GetInvoiceRoomStateAsync(invoiceId);
            return Json(new
            {
                success = state.found,
                roomId = state.roomId,
                status = state.status
            });
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

        // Check-out
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

        // Lich su hoa don
        [HttpGet]
        public async Task<IActionResult> InvoiceHistory(string searchString, string customerFilter, DateTime? fromDate, DateTime? toDate, string status = "All", int page = 1)
        {
            var vm = await _invoiceService.GetInvoiceHistoryAsync(searchString, customerFilter, fromDate, toDate, status, page);
            return View(vm);
        }

        // Chi tiet lich su hoa don
        [HttpGet]
        public async Task<IActionResult> GetInvoiceDetail(int invoiceId)
        {
            var vm = await _invoiceService.GetInvoiceDetailAsync(invoiceId);
            if (vm == null) return NotFound("Không tìm thấy thông tin hóa đơn.");
            return PartialView("_InvoiceDetailModal", vm);
        }

        [HttpGet]
        public async Task<IActionResult> Schedule(string? startDate)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            int.TryParse(idClaim, out int accountId);
            string? name = User.Identity?.Name;

            var viewModel = await _staffService.GetScheduleViewModelAsync(accountId, name, startDate);
            if (viewModel == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            ViewBag.StartOfWeek = viewModel.StartOfWeek;
            ViewBag.EndOfWeek = viewModel.EndOfWeek;
            ViewBag.Shifts = viewModel.Shifts;
            ViewBag.Schedules = viewModel.Schedules;
            ViewBag.Account = viewModel.Account;

            return View();
        }

        [HttpGet]
        public async Task<IActionResult> GetShiftCoworkers(int scheduleId)
        {
            var coworkers = await _staffService.GetShiftCoworkersAsync(scheduleId);
            return Json(coworkers);
        }

        [HttpGet]
        public async Task<IActionResult> GetEligibleSwapTargets(int scheduleId)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId)) return BadRequest("Không xác định được nhân viên.");

            var (valid, error, targets) = await _staffService.GetEligibleSwapTargetsAsync(scheduleId, accountId);
            if (!valid) return BadRequest(error);

            return Json(targets);
        }

        [HttpPost]
        public async Task<IActionResult> SubmitSwap(int requesterScheduleId, int targetScheduleId, int targetEmployeeId)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId)) return BadRequest("Không xác định được nhân viên.");

            var account = await _staffService.GetAccountAsync(accountId, null);
            if (account == null) return BadRequest("Không xác định được nhân viên.");

            var res = await _scheduleService.SubmitSwapRequest(accountId, requesterScheduleId, targetEmployeeId, targetScheduleId);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        [HttpPost]
        public async Task<IActionResult> AcceptSwap(int swapRequestId)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId)) return BadRequest("Không xác định được nhân viên.");

            var res = await _scheduleService.ConsentSwapRequest(swapRequestId, accountId);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        [HttpPost]
        public async Task<IActionResult> RejectSwap(int swapRequestId)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId)) return BadRequest("Không xác định được nhân viên.");

            var res = await _scheduleService.RejectSwapRequestByTarget(swapRequestId, accountId);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        [HttpGet]
        public async Task<IActionResult> LeaveRequest()
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            int.TryParse(idClaim, out int accountId);
            string? name = User.Identity?.Name;

            var viewModel = await _staffService.GetLeaveRequestViewModelAsync(accountId, name);
            if (viewModel == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            ViewBag.EligibleSchedules = viewModel.EligibleSchedules;
            ViewBag.RequestHistory = viewModel.RequestHistory;
            ViewBag.Account = viewModel.Account;
            ViewBag.WorkShifts = viewModel.WorkShifts;

            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SubmitLeave(string requestedDateStr, int? shiftId, string reason)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId))
            {
                return BadRequest("Không xác định được danh tính nhân viên.");
            }

            if (string.IsNullOrWhiteSpace(reason))
            {
                return BadRequest("Vui lòng cung cấp lý do xin nghỉ.");
            }

            if (!DateOnly.TryParse(requestedDateStr, out var requestedDate))
            {
                return BadRequest("Ngày chọn không hợp lệ.");
            }

            int? targetShiftId = (shiftId == 0) ? null : shiftId;

            var result = await _scheduleService.SubmitLeaveRequest(accountId, requestedDate, targetShiftId, reason);
            if (result.Success)
            {
                return Ok(new { success = true, message = result.Message });
            }

            return BadRequest(result.Message);
        }
    }
}
