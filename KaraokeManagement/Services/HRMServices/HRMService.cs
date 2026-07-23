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
                    EmploymentStatus = p?.EmploymentStatus ?? "Active"
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
                if (account == null) return (false, "Không tìm thấy nhân viên.");

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

        public async Task<ScheduleListViewModel> GetSchedulesViewModelAsync(string? date)
        {
            DateTime selectedDate = string.IsNullOrEmpty(date) ? DateTime.Today : DateTime.Parse(date);
            int diff = (7 + (selectedDate.DayOfWeek - DayOfWeek.Monday)) % 7;
            DateTime monday = selectedDate.AddDays(-1 * diff).Date;
            DateTime sunday = monday.AddDays(6).Date;

            DateOnly startDate = DateOnly.FromDateTime(monday);
            DateOnly endDate = DateOnly.FromDateTime(sunday);

            var weekDays = Enumerable.Range(0, 7)
                .Select(i => startDate.AddDays(i))
                .ToList();

            var rawShifts = await _context.WorkShifts.ToListAsync();
            var shifts = rawShifts.OrderBy(s => {
                var name = s.ShiftName.ToLower();
                if (name.Contains("khuya") || name.Contains("tối") || name.Contains("đêm") || name.Contains("night"))
                    return 3;

                var startHour = s.StartTime.Hours;
                if (startHour >= 18 || startHour < 6)
                    return 3;
                if (startHour >= 12 && startHour < 18)
                    return 2;
                return 1;
            }).ThenBy(s => s.StartTime).ToList();

            var staffList = await _context.Accounts
                .Include(a => a.Role)
                .Where(a => a.Role != null && a.Role.RoleName != "Customer")
                .OrderBy(a => a.FullName)
                .ToListAsync();

            var schedules = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .Include(s => s.Shift)
                .Where(s => s.WorkDate >= startDate && s.WorkDate <= endDate)
                .ToListAsync();

            return new ScheduleListViewModel
            {
                FilterDate = DateOnly.FromDateTime(selectedDate),
                StartDate = startDate,
                EndDate = endDate,
                WeekDays = weekDays,
                Shifts = shifts,
                StaffList = staffList,
                Schedules = schedules
            };
        }

        public async Task<(bool Success, string Message)> BatchUpdateSchedulesAsync(BatchSchedulePayload payload)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var today = DateOnly.FromDateTime(DateTime.Today);

                // Validation check for AddedRecords
                if (payload.AddedRecords != null && payload.AddedRecords.Any(r => r.WorkDate < today))
                {
                    return (false, "Không thể chỉnh sửa hoặc đổi ca cho các ngày trong quá khứ.");
                }

                // Validation check for UpdatedRecords
                if (payload.UpdatedRecords != null && payload.UpdatedRecords.Any(r => r.WorkDate < today))
                {
                    return (false, "Không thể chỉnh sửa hoặc đổi ca cho các ngày trong quá khứ.");
                }

                // Validation check for DeletedRecordIds
                if (payload.DeletedRecordIds != null && payload.DeletedRecordIds.Any())
                {
                    bool hasPastDelete = await _context.EmployeeSchedules
                        .AnyAsync(s => payload.DeletedRecordIds.Contains(s.ScheduleId) && s.WorkDate < today);
                    if (hasPastDelete)
                    {
                        return (false, "Không thể chỉnh sửa hoặc đổi ca cho các ngày trong quá khứ.");
                    }
                }

                // 1. Execute all Insert operations for payload.AddedRecords
                if (payload.AddedRecords != null && payload.AddedRecords.Any())
                {
                    foreach (var item in payload.AddedRecords)
                    {
                        if (item.AccountId <= 0 || item.ShiftId <= 0) continue;

                        bool exists = await _context.EmployeeSchedules.AnyAsync(s =>
                            s.AccountId == item.AccountId &&
                            s.ShiftId == item.ShiftId &&
                            s.WorkDate == item.WorkDate);

                        if (!exists)
                        {
                            var newSchedule = new EmployeeSchedule
                            {
                                AccountId = item.AccountId,
                                ShiftId = item.ShiftId,
                                WorkDate = item.WorkDate,
                                Status = string.IsNullOrWhiteSpace(item.Status) ? "Scheduled" : item.Status,
                                IsActive = true
                            };
                            _context.EmployeeSchedules.Add(newSchedule);
                        }
                    }
                }

                // 2. Execute all Update operations for payload.UpdatedRecords
                if (payload.UpdatedRecords != null && payload.UpdatedRecords.Any())
                {
                    foreach (var item in payload.UpdatedRecords)
                    {
                        var schedule = await _context.EmployeeSchedules.FindAsync(item.ScheduleId);
                        if (schedule != null)
                        {
                            schedule.AccountId = item.AccountId;
                            schedule.ShiftId = item.ShiftId;
                            schedule.WorkDate = item.WorkDate;
                        }
                    }
                }

                // 3. Execute all Delete operations for payload.DeletedRecordIds
                if (payload.DeletedRecordIds != null && payload.DeletedRecordIds.Any())
                {
                    var toDelete = await _context.EmployeeSchedules
                        .Where(s => payload.DeletedRecordIds.Contains(s.ScheduleId))
                        .ToListAsync();

                    if (toDelete.Any())
                    {
                        _context.EmployeeSchedules.RemoveRange(toDelete);
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return (true, "Đã cập nhật tất cả thay đổi thành công!");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return (false, "Lỗi xử lý giao dịch: " + ex.Message);
            }
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
