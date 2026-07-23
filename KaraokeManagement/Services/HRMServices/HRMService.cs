using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;

namespace KaraokeManagement.Services.HRMServices
{
    public class HRMService
    {
        private readonly KaraokeManagementDbContext _context;

        public HRMService(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public async Task<EmployeeListViewModel> GetEmployeeListAsync()
        {
            var accounts = await _context.Accounts
                .Include(a => a.Role)
                .Where(a => a.Role.RoleName != "Customer") // Only staff
                .ToListAsync();

            var profiles = await _context.EmployeeProfiles.ToListAsync();
            var roles = await _context.Roles.Where(r => r.RoleName != "Customer").ToListAsync();

            var employeeList = accounts.Select(a => {
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
                    EmploymentStatus = a.IsActive ? "Active" : "Resigned"
                };
            }).ToList();

            return new EmployeeListViewModel
            {
                Roles = roles,
                Employees = employeeList
            };
        }

        public async Task<(bool Success, string Message)> SaveEmployeeAsync(EmployeeViewModel model)
        {
            if (model.AccountId == 0) // New Employee
            {
                if (await _context.Accounts.AnyAsync(a => a.Username == model.Username))
                    return (false, "Tên đăng nhập đã tồn tại.");

                var account = new Account {
                    Username = model.Username,
                    PasswordHash = "123456", // Default password for demo
                    FullName = model.FullName,
                    Phone = model.Phone,
                    Email = model.Email,
                    RoleId = model.RoleId,
                    CreatedAt = DateTime.Now,
                    IsActive = (model.EmploymentStatus == "Active" || model.EmploymentStatus == "OnLeave")
                };
                _context.Accounts.Add(account);
                await _context.SaveChangesAsync();

                var profile = new EmployeeProfile {
                    AccountId = account.AccountId,
                    IdentityCardNumber = model.IdentityCardNumber,
                    DateOfBirth = model.DateOfBirth,
                    Address = model.Address,
                    HireDate = model.HireDate,
                    BaseHourlyRate = model.BaseHourlyRate
                };
                _context.EmployeeProfiles.Add(profile);
                await _context.SaveChangesAsync();
            }
            else // Edit
            {
                var account = await _context.Accounts.FindAsync(model.AccountId);
                if (account == null) return (false, "Không tìm thấy nhân viên.");

                account.FullName = model.FullName;
                account.Phone = model.Phone;
                account.Email = model.Email;
                account.RoleId = model.RoleId;
                account.IsActive = (model.EmploymentStatus == "Active" || model.EmploymentStatus == "OnLeave");

                var profile = await _context.EmployeeProfiles.FirstOrDefaultAsync(p => p.AccountId == model.AccountId);
                if (profile != null)
                {
                    profile.IdentityCardNumber = model.IdentityCardNumber;
                    profile.DateOfBirth = model.DateOfBirth;
                    profile.Address = model.Address;
                    profile.HireDate = model.HireDate;
                    profile.BaseHourlyRate = model.BaseHourlyRate;
                }
                else
                {
                    _context.EmployeeProfiles.Add(new EmployeeProfile {
                        AccountId = model.AccountId,
                        IdentityCardNumber = model.IdentityCardNumber,
                        DateOfBirth = model.DateOfBirth,
                        Address = model.Address,
                        HireDate = model.HireDate,
                        BaseHourlyRate = model.BaseHourlyRate
                    });
                }
                await _context.SaveChangesAsync();
            }

            return (true, "Đã lưu nhân viên thành công.");
        }

        public async Task<(bool Success, string Message)> DeleteEmployeeAsync(int id)
        {
            var profile = await _context.EmployeeProfiles.FirstOrDefaultAsync(p => p.AccountId == id);
            if (profile != null) _context.EmployeeProfiles.Remove(profile);

            var account = await _context.Accounts.FindAsync(id);
            if (account != null) _context.Accounts.Remove(account);

            await _context.SaveChangesAsync();
            return (true, "Đã xóa nhân viên thành công.");
        }

        public async Task<AttendanceListViewModel> GetAttendanceViewModelAsync(string? start, string? end)
        {
            DateTime filterStart = string.IsNullOrEmpty(start) ? DateTime.Today : DateTime.Parse(start);
            DateTime filterEnd = string.IsNullOrEmpty(end) ? DateTime.Today.AddDays(1).AddTicks(-1) : DateTime.Parse(end).AddDays(1).AddTicks(-1);

            var staffList = await _context.Accounts.Where(a => a.Role.RoleName != "Customer").ToListAsync();
            var attendances = await _context.Attendances
                .Include(a => a.Account)
                .Include(a => a.Schedule).ThenInclude(s => s.Shift)
                .Where(a => a.CheckInTime >= filterStart && a.CheckInTime <= filterEnd)
                .OrderByDescending(a => a.CheckInTime)
                .ToListAsync();

            return new AttendanceListViewModel
            {
                FilterStartDate = filterStart,
                FilterEndDate = filterEnd,
                StaffList = staffList,
                Attendances = attendances
            };
        }

        public async Task<(bool Success, string Message)> AddAttendanceAsync(int accountId, int? scheduleId, DateTime checkIn, DateTime? checkOut, string status, string note)
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
            return (true, "Đã ghi nhận công thành công.");
        }
    }
}
