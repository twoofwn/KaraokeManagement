using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;
using System.Linq;
using System.Threading.Tasks;
using System;

namespace KaraokeManagement.Controllers
{
    public class HRMController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        public HRMController(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        // --- EMPLOYEES ---
        public async Task<IActionResult> Employees()
        {
            var accounts = await _context.Accounts
                .Include(a => a.Role)
                .Where(a => a.Role.RoleName != "Customer") // Only staff
                .ToListAsync();
            
            var profiles = await _context.EmployeeProfiles.ToListAsync();

            var viewModel = new EmployeeListViewModel
            {
                Roles = await _context.Roles.Where(r => r.RoleName != "Customer").ToListAsync(),
                Employees = accounts.Select(a => {
                    var p = profiles.FirstOrDefault(x => x.AccountId == a.AccountId);
                    return new EmployeeViewModel {
                        AccountId = a.AccountId,
                        Username = a.Username,
                        FullName = a.FullName,
                        Phone = a.Phone,
                        Email = a.Email,
                        RoleId = a.RoleId,
                        RoleName = a.Role?.RoleName,
                        IdentityCardNumber = p?.IdentityCardNumber ?? "",
                        DateOfBirth = p?.DateOfBirth,
                        Address = p?.Address,
                        HireDate = p?.HireDate ?? DateOnly.FromDateTime(DateTime.Now),
                        BaseHourlyRate = p?.BaseHourlyRate,
                        EmploymentStatus = p?.EmploymentStatus ?? "Active"
                    };
                }).ToList()
            };

            ViewData["ActiveNav"] = "hrm_employees";
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> SaveEmployee([FromBody] EmployeeViewModel model)
        {
            try
            {
                if (model.AccountId == 0) // New Employee
                {
                    if (await _context.Accounts.AnyAsync(a => a.Username == model.Username))
                        return BadRequest("Tên đăng nhập đã tồn tại.");
                        
                    var account = new Account {
                        Username = model.Username,
                        PasswordHash = "123456", // Default password for demo
                        FullName = model.FullName,
                        Phone = model.Phone,
                        Email = model.Email,
                        RoleId = model.RoleId,
                        CreatedAt = DateTime.Now
                    };
                    _context.Accounts.Add(account);
                    await _context.SaveChangesAsync();

                    var profile = new EmployeeProfile {
                        AccountId = account.AccountId,
                        IdentityCardNumber = model.IdentityCardNumber,
                        DateOfBirth = model.DateOfBirth,
                        Address = model.Address,
                        HireDate = model.HireDate,
                        BaseHourlyRate = model.BaseHourlyRate,
                        EmploymentStatus = model.EmploymentStatus
                    };
                    _context.EmployeeProfiles.Add(profile);
                    await _context.SaveChangesAsync();
                }
                else // Edit
                {
                    var account = await _context.Accounts.FindAsync(model.AccountId);
                    if (account == null) return NotFound("Không tìm thấy nhân viên.");
                    
                    account.FullName = model.FullName;
                    account.Phone = model.Phone;
                    account.Email = model.Email;
                    account.RoleId = model.RoleId;

                    var profile = await _context.EmployeeProfiles.FirstOrDefaultAsync(p => p.AccountId == model.AccountId);
                    if (profile != null)
                    {
                        profile.IdentityCardNumber = model.IdentityCardNumber;
                        profile.DateOfBirth = model.DateOfBirth;
                        profile.Address = model.Address;
                        profile.HireDate = model.HireDate;
                        profile.BaseHourlyRate = model.BaseHourlyRate;
                        profile.EmploymentStatus = model.EmploymentStatus;
                    }
                    else
                    {
                        _context.EmployeeProfiles.Add(new EmployeeProfile {
                            AccountId = model.AccountId,
                            IdentityCardNumber = model.IdentityCardNumber,
                            DateOfBirth = model.DateOfBirth,
                            Address = model.Address,
                            HireDate = model.HireDate,
                            BaseHourlyRate = model.BaseHourlyRate,
                            EmploymentStatus = model.EmploymentStatus
                        });
                    }
                    await _context.SaveChangesAsync();
                }
                return Ok();
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        public async Task<IActionResult> DeleteEmployee(int id)
        {
            var profile = await _context.EmployeeProfiles.FirstOrDefaultAsync(p => p.AccountId == id);
            if (profile != null) _context.EmployeeProfiles.Remove(profile);
            
            var account = await _context.Accounts.FindAsync(id);
            if (account != null) _context.Accounts.Remove(account);
            
            await _context.SaveChangesAsync();
            return Ok();
        }

        // --- SCHEDULES ---
        public async Task<IActionResult> Schedules(string? date)
        {
            DateOnly filterDate = string.IsNullOrEmpty(date) ? DateOnly.FromDateTime(DateTime.Now) : DateOnly.Parse(date);
            
            var viewModel = new ScheduleListViewModel
            {
                FilterDate = filterDate,
                Shifts = await _context.WorkShifts.ToListAsync(),
                StaffList = await _context.Accounts.Where(a => a.Role.RoleName != "Customer").ToListAsync(),
                Schedules = await _context.EmployeeSchedules
                    .Include(s => s.Account)
                    .Include(s => s.Shift)
                    .Where(s => s.WorkDate == filterDate)
                    .ToListAsync()
            };

            ViewData["ActiveNav"] = "hrm_schedules";
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> SaveSchedule(int accountId, int shiftId, string date)
        {
            DateOnly workDate = DateOnly.Parse(date);
            var exists = await _context.EmployeeSchedules.AnyAsync(s => s.AccountId == accountId && s.WorkDate == workDate && s.ShiftId == shiftId);
            if (exists) return BadRequest("Nhân viên đã được phân vào ca này trong ngày.");

            var schedule = new EmployeeSchedule {
                AccountId = accountId,
                ShiftId = shiftId,
                WorkDate = workDate,
                Status = "Scheduled"
            };
            _context.EmployeeSchedules.Add(schedule);
            await _context.SaveChangesAsync();
            return Ok();
        }

        [HttpPost]
        public async Task<IActionResult> DeleteSchedule(int id)
        {
            var s = await _context.EmployeeSchedules.FindAsync(id);
            if (s != null)
            {
                _context.EmployeeSchedules.Remove(s);
                await _context.SaveChangesAsync();
            }
            return Ok();
        }

        // --- ATTENDANCE ---
        public async Task<IActionResult> Attendance(string? start, string? end)
        {
            DateTime filterStart = string.IsNullOrEmpty(start) ? DateTime.Today : DateTime.Parse(start);
            DateTime filterEnd = string.IsNullOrEmpty(end) ? DateTime.Today.AddDays(1).AddTicks(-1) : DateTime.Parse(end).AddDays(1).AddTicks(-1);

            var viewModel = new AttendanceListViewModel
            {
                FilterStartDate = filterStart,
                FilterEndDate = filterEnd,
                StaffList = await _context.Accounts.Where(a => a.Role.RoleName != "Customer").ToListAsync(),
                Attendances = await _context.Attendances
                    .Include(a => a.Account)
                    .Include(a => a.Schedule).ThenInclude(s => s.Shift)
                    .Where(a => a.CheckInTime >= filterStart && a.CheckInTime <= filterEnd)
                    .OrderByDescending(a => a.CheckInTime)
                    .ToListAsync()
            };

            ViewData["ActiveNav"] = "hrm_attendance";
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddAttendance(int accountId, int? scheduleId, DateTime checkIn, DateTime? checkOut, string status, string note)
        {
            var att = new Attendance {
                AccountId = accountId,
                ScheduleId = scheduleId,
                CheckInTime = checkIn,
                CheckOutTime = checkOut,
                Status = status,
                Note = note
            };
            if (checkOut.HasValue)
            {
                att.TotalHours = (decimal)(checkOut.Value - checkIn).TotalHours;
            }
            _context.Attendances.Add(att);
            await _context.SaveChangesAsync();
            return Ok();
        }
    }
}
