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
using KaraokeManagement.Services.StaffServices;

namespace KaraokeManagement.Controllers
{
    [Authorize]
    public class StaffController : Controller
    {
        private readonly StaffService _staffService;
        private readonly IScheduleService _scheduleService;

        public StaffController(StaffService staffService, IScheduleService scheduleService)
        {
            _staffService = staffService;
            _scheduleService = scheduleService;
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
