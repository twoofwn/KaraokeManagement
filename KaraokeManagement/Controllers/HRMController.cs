using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;
using System.Linq;
using System.Threading.Tasks;
using System;

using Microsoft.AspNetCore.Mvc;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using KaraokeManagement.Services.HRMServices;
using System;
using System.Threading.Tasks;

namespace KaraokeManagement.Controllers
{
    public class HRMController : Controller
    {
        private readonly HRMService _hrmService;

        public HRMController(HRMService hrmService)
        {
            _hrmService = hrmService;
        }

        // --- EMPLOYEES ---
        public async Task<IActionResult> Employees()
        {
            var viewModel = await _hrmService.GetEmployeeListAsync();
            ViewData["ActiveNav"] = "hrm_employees";
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> SaveEmployee([FromBody] EmployeeViewModel model)
        {
            try
            {
                var result = await _hrmService.SaveEmployeeAsync(model);
                if (result.Success) return Ok();
                return BadRequest(result.Message);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        public async Task<IActionResult> DeleteEmployee(int id)
        {
            var result = await _hrmService.DeleteEmployeeAsync(id);
            if (result.Success) return Ok();
            return BadRequest(result.Message);
        }



        // --- ATTENDANCE ---
        public async Task<IActionResult> Attendance(string? start, string? end)
        {
            var viewModel = await _hrmService.GetAttendanceViewModelAsync(start, end);
            ViewData["ActiveNav"] = "hrm_attendance";
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddAttendance(int accountId, int? scheduleId, DateTime checkIn, DateTime? checkOut, string status, string note)
        {
            var result = await _hrmService.AddAttendanceAsync(accountId, scheduleId, checkIn, checkOut, status, note);
            if (result.Success) return Ok();
            return BadRequest(result.Message);
        }

        [HttpGet]
        public async Task<IActionResult> GetEmployeeDetails(int accountId)
        {
            var details = await _hrmService.GetEmployeeDetailsAsync(accountId);
            if (details == null) return NotFound("Không tìm thấy nhân viên.");
            return Json(details);
        }

        [HttpGet]
        public async Task<IActionResult> GetEmployeeReport(int accountId)
        {
            var report = await _hrmService.GetEmployeeReportAsync(accountId);
            return Json(report);
        }
    }
}
