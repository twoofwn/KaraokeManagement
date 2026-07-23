using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;
using KaraokeManagement.Services;
using KaraokeManagement.ViewModel;
using System.Linq;
using System.Threading.Tasks;
using System;
using System.Security.Claims;

namespace KaraokeManagement.Controllers
{
    public class ScheduleManagementController : Controller
    {
        private readonly IScheduleService _scheduleService;

        public ScheduleManagementController(IScheduleService scheduleService)
        {
            _scheduleService = scheduleService;
        }

        // 5. UI / KANBAN BOARD RENDERING
        public IActionResult Index()
        {
            return RedirectToAction("WeeklyGrid");
        }

        // AUTO SCHEDULING ACTION
        [HttpPost]
        public async Task<IActionResult> GenerateSchedule(DateTime startDate)
        {
            try
            {
                bool result = await _scheduleService.GenerateWeeklySchedule(startDate);
                if (result) return Ok(new { success = true, message = "Đã tự động xếp lịch thành công cho tuần này!" });
                return BadRequest("Không thể xếp lịch. Vui lòng kiểm tra danh sách ca làm việc và nhân sự.");
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        // SWAP ACTIONS
        [HttpPost]
        public async Task<IActionResult> SubmitSwapRequest(int requesterId, int requesterScheduleId, int targetId, int targetScheduleId)
        {
            var res = await _scheduleService.SubmitSwapRequest(requesterId, requesterScheduleId, targetId, targetScheduleId);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        [HttpPost]
        public async Task<IActionResult> ConsentSwapRequest(int swapRequestId, int targetId)
        {
            var res = await _scheduleService.ConsentSwapRequest(swapRequestId, targetId);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        [HttpPost]
        public async Task<IActionResult> ApproveSwapRequest(int swapRequestId, int managerId)
        {
            var res = await _scheduleService.ApproveSwapRequest(swapRequestId, managerId);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        [HttpPost]
        public async Task<IActionResult> RejectSwapRequest(int swapRequestId, int managerId)
        {
            var res = await _scheduleService.RejectSwapRequest(swapRequestId, managerId);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        // LEAVE ACTIONS
        [HttpPost]
        public async Task<IActionResult> SubmitLeaveRequest(int accountId, int scheduleId, string reason)
        {
            var res = await _scheduleService.SubmitLeaveRequest(accountId, scheduleId, reason);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        [HttpPost]
        public async Task<IActionResult> ApproveLeaveRequest(int leaveRequestId, int managerId)
        {
            var res = await _scheduleService.ApproveLeaveRequest(leaveRequestId, managerId);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        [HttpPost]
        public async Task<IActionResult> RejectLeaveRequest(int leaveRequestId, int managerId)
        {
            var res = await _scheduleService.RejectLeaveRequest(leaveRequestId, managerId);
            if (res.Success) return Ok(new { success = true, message = res.Message });
            return BadRequest(res.Message);
        }

        public async Task<IActionResult> WeeklyGrid(string? startDate)
        {
            var data = await _scheduleService.GetWeeklyGridDataAsync(startDate);

            ViewData["ActiveNav"] = "weekly_grid";
            ViewData["StartOfWeek"] = data.StartOfWeek;
            ViewData["EndOfWeek"] = data.EndOfWeek;
            ViewData["Shifts"] = data.Shifts;
            ViewData["RawSchedules"] = data.RawSchedules;

            return View();
        }

        [HttpGet]
        public async Task<IActionResult> ShiftDetails(int? shiftId, string? date)
        {
            var result = await _scheduleService.GetShiftDetailsAsync(shiftId, date);
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> LeaveApprovals()
        {
            var data = await _scheduleService.GetLeaveApprovalsDataAsync();

            ViewBag.PendingRequests = data.PendingRequests;
            ViewBag.HistoryRequests = data.HistoryRequests;
            ViewData["ActiveNav"] = "leave_approvals";

            return View();
        }

        public async Task<IActionResult> Schedules(string? date)
        {
            var viewModel = await _scheduleService.GetSchedulesViewModelAsync(date);
            ViewData["ActiveNav"] = "hrm_schedules";
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> BatchUpdateSchedules([FromBody] BatchSchedulePayload payload)
        {
            if (payload == null)
            {
                return BadRequest("Dữ liệu gửi lên không hợp lệ.");
            }

            var result = await _scheduleService.BatchUpdateSchedulesAsync(payload);
            if (result.Success) return Ok(new { success = true, message = result.Message });
            return BadRequest(result.Message);
        }
    }
}


