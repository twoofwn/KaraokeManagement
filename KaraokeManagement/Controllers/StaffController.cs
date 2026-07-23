using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using KaraokeManagement.Services;

namespace KaraokeManagement.Controllers
{
    [Authorize]
    public class StaffController : Controller
    {
        private readonly KaraokeManagementDbContext _context;
        private readonly IScheduleService _scheduleService;

        public StaffController(KaraokeManagementDbContext context, IScheduleService scheduleService)
        {
            _context = context;
            _scheduleService = scheduleService;
        }

        [HttpGet]
        public async Task<IActionResult> Dashboard()
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            Account? account = null;

            if (int.TryParse(idClaim, out int accountId))
            {
                account = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == accountId);
            }

            if (account == null)
            {
                string? name = User.Identity?.Name;
                account = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.FullName == name || a.Username == name);
            }

            if (account == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            var today = DateOnly.FromDateTime(DateTime.Today);

            var schedules = await _context.EmployeeSchedules
                .Include(s => s.Shift)
                .Where(s => s.AccountId == account.AccountId && s.WorkDate == today && s.IsActive && s.Status != "Off")
                .ToListAsync();

            var todaySchedulesList = new List<StaffScheduleItemViewModel>();

            foreach (var sched in schedules)
            {
                var workDate = sched.WorkDate;
                var rooms = await _context.Bookings
                    .Include(b => b.Room)
                    .ThenInclude(r => r.RoomType)
                    .Where(b => b.StaffId == sched.AccountId 
                             && b.StartTime.Year == workDate.Year 
                             && b.StartTime.Month == workDate.Month 
                             && b.StartTime.Day == workDate.Day)
                    .Select(b => b.Room)
                    .Distinct()
                    .ToListAsync();

                todaySchedulesList.Add(new StaffScheduleItemViewModel
                {
                    Schedule = sched,
                    AssignedRooms = rooms
                });
            }

            // Fetch incoming swap requests for this target employee
            var incomingSwapRequests = await _context.ShiftSwapRequests
                .Include(r => r.Requester)
                .Include(r => r.RequesterSchedule).ThenInclude(s => s.Shift)
                .Include(r => r.TargetSchedule).ThenInclude(s => s.Shift)
                .Where(r => r.TargetId == account.AccountId && r.Status == "Pending")
                .ToListAsync();

            var viewModel = new StaffDashboardViewModel
            {
                Account = account,
                TodaySchedules = todaySchedulesList
            };

            ViewBag.IncomingSwapRequests = incomingSwapRequests;

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> Schedule(string? startDate)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            Account? account = null;

            if (int.TryParse(idClaim, out int accountId))
            {
                account = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == accountId);
            }

            if (account == null)
            {
                string? name = User.Identity?.Name;
                account = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.FullName == name || a.Username == name);
            }

            if (account == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            DateTime start = string.IsNullOrEmpty(startDate) ? DateTime.Today : DateTime.Parse(startDate);
            
            // Normalize to Monday of the week
            int diff = (7 + (start.DayOfWeek - DayOfWeek.Monday)) % 7;
            DateTime monday = start.AddDays(-1 * diff).Date;
            DateTime sunday = monday.AddDays(6).Date;

            DateOnly monDate = DateOnly.FromDateTime(monday);
            DateOnly sunDate = DateOnly.FromDateTime(sunday);

            var shifts = await _context.WorkShifts.ToListAsync();
            var rawSchedules = await _context.EmployeeSchedules
                .Include(s => s.Shift)
                .Where(s => s.AccountId == account.AccountId && s.WorkDate >= monDate && s.WorkDate <= sunDate && s.IsActive && s.Status != "Off")
                .ToListAsync();

            ViewBag.StartOfWeek = monday;
            ViewBag.EndOfWeek = sunday;
            ViewBag.Shifts = shifts;
            ViewBag.Schedules = rawSchedules;
            ViewBag.Account = account;

            return View();
        }

        [HttpGet]
        public async Task<IActionResult> GetShiftCoworkers(int scheduleId)
        {
            var sched = await _context.EmployeeSchedules.FindAsync(scheduleId);
            if (sched == null) return NotFound("Ca làm việc không tồn tại.");

            var coworkers = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .Where(s => s.WorkDate == sched.WorkDate 
                            && s.ShiftId == sched.ShiftId 
                            && s.AccountId != sched.AccountId
                            && s.IsActive
                            && s.Status != "Off")
                .Select(s => new {
                    fullName = s.Account.FullName,
                    roleName = s.Account.Role.RoleName
                })
                .ToListAsync();

            return Json(coworkers);
        }

        [HttpGet]
        public async Task<IActionResult> GetEligibleSwapTargets(int scheduleId)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId)) return BadRequest("Không xác định được nhân viên.");

            var mySched = await _context.EmployeeSchedules
                .Include(s => s.Account)
                .FirstOrDefaultAsync(s => s.ScheduleId == scheduleId);

            if (mySched == null || mySched.AccountId != accountId)
                return BadRequest("Lịch làm việc không hợp lệ.");

            // Target employees must share the EXACT SAME Role and have an active schedule on the same day
            var targets = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .Include(s => s.Shift)
                .Where(s => s.WorkDate == mySched.WorkDate 
                            && s.AccountId != accountId 
                            && s.Account.RoleId == mySched.Account.RoleId
                            && s.IsActive
                            && s.Status != "Off")
                .Select(s => new {
                    scheduleId = s.ScheduleId,
                    accountId = s.AccountId,
                    fullName = s.Account.FullName,
                    shiftName = s.Shift.ShiftName,
                    startTime = s.Shift.StartTime.ToString(@"hh\:mm"),
                    endTime = s.Shift.EndTime.ToString(@"hh\:mm")
                })
                .ToListAsync();

            return Json(targets);
        }

        [HttpPost]
        public async Task<IActionResult> SubmitSwap(int requesterScheduleId, int targetScheduleId, int targetEmployeeId)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId)) return BadRequest("Không xác định được nhân viên.");

            var reqSched = await _context.EmployeeSchedules.FindAsync(requesterScheduleId);
            if (reqSched != null && reqSched.WorkDate < DateOnly.FromDateTime(DateTime.Today))
            {
                return BadRequest("Không thể chỉnh sửa hoặc đổi ca cho các ngày trong quá khứ.");
            }

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
            Account? account = null;

            if (int.TryParse(idClaim, out int accountId))
            {
                account = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == accountId);
            }

            if (account == null)
            {
                string? name = User.Identity?.Name;
                account = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.FullName == name || a.Username == name);
            }

            if (account == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            var today = DateOnly.FromDateTime(DateTime.Today);

            var activeLeaveReqScheduleIds = await _context.LeaveRequests
                .Where(r => r.AccountId == account.AccountId && r.Status != "Rejected")
                .Select(r => r.ScheduleId)
                .ToListAsync();

            var eligibleSchedules = await _context.EmployeeSchedules
                .Include(s => s.Shift)
                .Where(s => s.AccountId == account.AccountId 
                            && s.WorkDate >= today 
                            && s.IsActive 
                            && s.Status != "Off" 
                            && !activeLeaveReqScheduleIds.Contains(s.ScheduleId))
                .OrderBy(s => s.WorkDate)
                .ToListAsync();

            var requestHistory = await _context.LeaveRequests
                .Include(r => r.Schedule).ThenInclude(s => s.Shift)
                .Include(r => r.ApprovedBy)
                .Where(r => r.AccountId == account.AccountId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            ViewBag.EligibleSchedules = eligibleSchedules;
            ViewBag.RequestHistory = requestHistory;
            ViewBag.Account = account;

            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SubmitLeave(int scheduleId, string reason)
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

            var result = await _scheduleService.SubmitLeaveRequest(accountId, scheduleId, reason);
            if (result.Success)
            {
                return Ok(new { success = true, message = result.Message });
            }

            return BadRequest(result.Message);
        }
    }
}
