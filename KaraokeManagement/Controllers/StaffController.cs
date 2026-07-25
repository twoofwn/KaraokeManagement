using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using KaraokeManagement.Services;
using KaraokeManagement.Services.ReceptionistServices;
using KaraokeManagement.Services.StaffServices;

namespace KaraokeManagement.Controllers
{
    [Authorize]
    public class StaffController : Controller
    {
        private readonly StaffService _staffService;
        private readonly IScheduleService _scheduleService;
        private readonly RoomBookingService _roomBookingService;

        public StaffController(
            StaffService staffService,
            IScheduleService scheduleService,
            RoomBookingService roomBookingService)
        {
            _staffService = staffService;
            _scheduleService = scheduleService;
            _roomBookingService = roomBookingService;
        }

        [HttpGet]
        public async Task<IActionResult> Dashboard()
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            int.TryParse(idClaim, out int accountId);
            string? name = User.Identity?.Name;

            var (viewModel, incomingSwapRequests) = await _staffService.GetDashboardDataAsync(accountId, name);
            if (viewModel == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            ViewBag.IncomingSwapRequests = incomingSwapRequests;

            return View(viewModel);
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

            // Direct check for past date is kept in controller/service
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

            // Treat 0 or null as Full Day (null ShiftId)
            int? targetShiftId = (shiftId == 0) ? null : shiftId;

            var result = await _scheduleService.SubmitLeaveRequest(accountId, requestedDate, targetShiftId, reason);
            if (result.Success)
            {
                return Ok(new { success = true, message = result.Message });
            }

            return BadRequest(result.Message);
        }

        [HttpGet]
        public async Task<IActionResult> AssignedRooms()
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId))
            {
                return RedirectToAction("Login", "Auth");
            }

            var model = await _staffService.GetAssignedRoomsAsync(accountId);
            return View(model);
        }

        [HttpGet]
        public async Task<IActionResult> AssignedDetail(int bookingId)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId))
            {
                return RedirectToAction("Login", "Auth");
            }

            var model = await _staffService.GetAssignedDetailAsync(bookingId, accountId);
            if (model == null)
            {
                return NotFound("Không tìm thấy thông tin phòng hoặc bạn không có quyền truy cập.");
            }

            return View(model);
        }

        [HttpPost]
        [Authorize(Roles = "Service Staff")]
        public async Task<IActionResult> ChangeRoom([FromBody] ChangeRoomRequest request)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId) || accountId <= 0)
            {
                return Json(new { success = false, message = "Không xác định được nhân viên thực hiện." });
            }

            var result = await _roomBookingService.ChangeRoomAsync(
                request,
                accountId,
                assignedStaffId: accountId);

            return Json(new { success = result.success, message = result.message });
        }

        [HttpPost]
        public async Task<IActionResult> FulfillService(int invoiceDetailId, int bookingId)
        {
            var success = await _staffService.FulfillServiceItemAsync(invoiceDetailId);

            if (success)
            {
                TempData["SuccessMessage"] = "Đã xác nhận giao đồ thành công!";
            }
            else
            {
                TempData["ErrorMessage"] = "Có lỗi xảy ra, không tìm thấy món hoặc món đã được giao.";
            }

            return RedirectToAction("AssignedDetail", new { bookingId = bookingId });
        }

        [HttpPost]
        public async Task<IActionResult> CancelServiceItem(int invoiceDetailId, int bookingId)
        {
            var success = await _staffService.CancelServiceItemAsync(invoiceDetailId);

            if (success)
            {
                TempData["SuccessMessage"] = "Đã hủy món và hoàn trả kho thành công!";
            }
            else
            {
                TempData["ErrorMessage"] = "Không thể hủy món này (có thể món đã được giao hoặc không tồn tại).";
            }

            return RedirectToAction("AssignedDetail", new { bookingId = bookingId });
        }
    }
}
