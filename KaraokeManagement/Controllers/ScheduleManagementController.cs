using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;
using KaraokeManagement.Services;
using System.Linq;
using System.Threading.Tasks;
using System;
using System.Security.Claims;

namespace KaraokeManagement.Controllers
{
    public class ScheduleManagementController : Controller
    {
        private readonly KaraokeManagementDbContext _context;
        private readonly IScheduleService _scheduleService;

        public ScheduleManagementController(KaraokeManagementDbContext context, IScheduleService scheduleService)
        {
            _context = context;
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
            DateTime start = string.IsNullOrEmpty(startDate) ? new DateTime(2026, 7, 20) : DateTime.Parse(startDate);
            int diff = (7 + (start.DayOfWeek - DayOfWeek.Monday)) % 7;
            DateTime monday = start.AddDays(-1 * diff).Date;
            DateTime sunday = monday.AddDays(6).Date;

            DateOnly monDate = DateOnly.FromDateTime(monday);
            DateOnly sunDate = DateOnly.FromDateTime(sunday);

            var shifts = await _context.WorkShifts.ToListAsync();
            var rawSchedules = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .Include(s => s.Shift)
                .Where(s => s.WorkDate >= monDate && s.WorkDate <= sunDate)
                .ToListAsync();

            ViewData["ActiveNav"] = "weekly_grid";
            ViewData["StartOfWeek"] = monday;
            ViewData["EndOfWeek"] = sunday;
            ViewData["Shifts"] = shifts;
            ViewData["RawSchedules"] = rawSchedules;

            return View();
        }

        public async Task<IActionResult> ShiftDetails(int? shiftId, string? date)
        {
            int sId = shiftId ?? 1;
            DateOnly workDate = string.IsNullOrEmpty(date) ? new DateOnly(2026, 7, 21) : DateOnly.Parse(date);

            var shift = await _context.WorkShifts.FindAsync(sId);
            var schedules = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .Include(s => s.Shift)
                .Where(s => s.ShiftId == sId && s.WorkDate == workDate)
                .ToListAsync();

            var accountIds = schedules.Select(s => s.AccountId).ToList();
            var profiles = await _context.EmployeeProfiles
                .Where(p => accountIds.Contains(p.AccountId))
                .ToListAsync();

            ViewData["ActiveNav"] = "weekly_grid";
            ViewData["Shift"] = shift;
            ViewData["WorkDate"] = workDate;
            ViewData["Schedules"] = schedules;
            ViewData["Profiles"] = profiles;

            return View();
        }

        [HttpGet]
        public async Task<IActionResult> LeaveApprovals()
        {
            var pending = await _context.LeaveRequests
                .Include(r => r.Account).ThenInclude(a => a.Role)
                .Include(r => r.Schedule).ThenInclude(s => s.Shift)
                .Where(r => r.Status == "Pending")
                .ToListAsync();

            var history = await _context.LeaveRequests
                .Include(r => r.Account).ThenInclude(a => a.Role)
                .Include(r => r.Schedule).ThenInclude(s => s.Shift)
                .Include(r => r.ApprovedBy)
                .Where(r => r.Status != "Pending")
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            ViewBag.PendingRequests = pending;
            ViewBag.HistoryRequests = history;
            ViewData["ActiveNav"] = "leave_approvals";

            return View();
        }
    }
}


