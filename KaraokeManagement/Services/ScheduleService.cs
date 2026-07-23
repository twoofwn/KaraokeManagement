using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;

namespace KaraokeManagement.Services
{
    public interface IScheduleService
    {
        Task<bool> GenerateWeeklySchedule(DateTime startDate);
        Task<(bool Success, string Message)> SubmitSwapRequest(int requesterId, int requesterScheduleId, int targetId, int targetScheduleId);
        Task<(bool Success, string Message)> ConsentSwapRequest(int swapRequestId, int targetId);
        Task<(bool Success, string Message)> RejectSwapRequestByTarget(int swapRequestId, int targetId);
        Task<(bool Success, string Message)> ApproveSwapRequest(int swapRequestId, int managerId);
        Task<(bool Success, string Message)> RejectSwapRequest(int swapRequestId, int managerId);
        Task<(bool Success, string Message)> SubmitLeaveRequest(int accountId, int scheduleId, string reason);
        Task<(bool Success, string Message)> ApproveLeaveRequest(int leaveRequestId, int managerId);
        Task<(bool Success, string Message)> RejectLeaveRequest(int leaveRequestId, int managerId);
        Task<WeeklyGridViewModel> GetWeeklyGridDataAsync(string? startDate);
        Task<object> GetShiftDetailsAsync(int? shiftId, string? date);
        Task<LeaveApprovalsViewModel> GetLeaveApprovalsDataAsync();
        Task<ScheduleListViewModel> GetSchedulesViewModelAsync(string? date);
        Task<(bool Success, string Message)> BatchUpdateSchedulesAsync(BatchSchedulePayload payload);
    }

    public class ScheduleService : IScheduleService
    {
        private readonly KaraokeManagementDbContext _context;

        public ScheduleService(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        // 2. AUTO-SCHEDULING ALGORITHM
        public async Task<bool> GenerateWeeklySchedule(DateTime startDate)
        {
            // Normalize start date to Monday of the week if needed
            int diff = (7 + (startDate.DayOfWeek - DayOfWeek.Monday)) % 7;
            DateTime monday = startDate.AddDays(-1 * diff).Date;
            DateTime sunday = monday.AddDays(6).Date;

            // Check if the entire week is in the past
            if (sunday < DateTime.Today)
            {
                throw new InvalidOperationException("Không thể xếp lịch cho tuần đã qua trong quá khứ.");
            }

            var shifts = await _context.WorkShifts.ToListAsync();
            if (!shifts.Any()) return false;

            // Fetch all active staff accounts (not customer) who have a default shift
            var activeStaff = await _context.Accounts
                .Include(a => a.Role)
                .Where(a => a.Role.RoleName != "Customer" && a.DefaultShiftId != null && a.IsActive == true)
                .ToListAsync();

            if (!activeStaff.Any()) return false;

            bool addedAny = false;
            for (int dayIndex = 0; dayIndex < 7; dayIndex++)
            {
                DateOnly workDate = DateOnly.FromDateTime(monday.AddDays(dayIndex));

                // Skip past dates
                if (workDate < DateOnly.FromDateTime(DateTime.Today))
                {
                    continue;
                }

                foreach (var emp in activeStaff)
                {
                    int shiftId = emp.DefaultShiftId!.Value;

                    // Check if schedule already exists
                    bool exists = await _context.EmployeeSchedules.AnyAsync(s => 
                        s.AccountId == emp.AccountId && s.WorkDate == workDate && s.ShiftId == shiftId);

                    if (!exists)
                    {
                        _context.EmployeeSchedules.Add(new EmployeeSchedule
                        {
                            AccountId = emp.AccountId,
                            ShiftId = shiftId,
                            WorkDate = workDate,
                            Status = "Scheduled",
                            IsActive = true
                        });
                        addedAny = true;
                    }
                }
            }

            if (addedAny)
            {
                await _context.SaveChangesAsync();
            }
            return true;
        }

        // 3. SHIFT SWAP REQUEST LOGIC
        public async Task<(bool Success, string Message)> SubmitSwapRequest(int requesterId, int requesterScheduleId, int targetId, int targetScheduleId)
        {
            var reqSched = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .FirstOrDefaultAsync(s => s.ScheduleId == requesterScheduleId);
                
            var tarSched = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .FirstOrDefaultAsync(s => s.ScheduleId == targetScheduleId);

            if (reqSched == null || tarSched == null)
                return (false, "Lịch làm việc không tồn tại.");

            if (reqSched.WorkDate < DateOnly.FromDateTime(DateTime.Today))
                return (false, "Không thể chỉnh sửa hoặc đổi ca cho các ngày trong quá khứ.");

            if (reqSched.AccountId != requesterId || tarSched.AccountId != targetId)
                return (false, "Thông tin phân ca không trùng khớp với nhân viên.");

            // Validation: Both employees MUST have the EXACT SAME Role and be scheduled on the EXACT SAME Day
            if (reqSched.Account.RoleId != tarSched.Account.RoleId && reqSched.Account.Role.RoleName != tarSched.Account.Role.RoleName)
                return (false, "Cả 2 nhân viên phải có cùng Chức vụ (Role) mới có thể đổi ca.");

            if (reqSched.WorkDate != tarSched.WorkDate)
                return (false, "Cả 2 ca làm việc phải thuộc cùng 1 Ngày làm việc.");

            var swapReq = new ShiftSwapRequest
            {
                RequesterId = requesterId,
                RequesterScheduleId = requesterScheduleId,
                TargetId = targetId,
                TargetScheduleId = targetScheduleId,
                Status = "Pending",
                CreatedAt = DateTime.Now
            };

            _context.ShiftSwapRequests.Add(swapReq);
            await _context.SaveChangesAsync();

            return (true, "Đã gửi yêu cầu đổi ca thành công. Chờ đồng nghiệp xác nhận.");
        }

        public async Task<(bool Success, string Message)> ConsentSwapRequest(int swapRequestId, int targetId)
        {
            var req = await _context.ShiftSwapRequests
                .Include(r => r.RequesterSchedule)
                .Include(r => r.TargetSchedule)
                .FirstOrDefaultAsync(r => r.SwapRequestId == swapRequestId);

            if (req == null) return (false, "Yêu cầu đổi ca không tồn tại.");
            if (req.TargetId != targetId) return (false, "Bạn không có quyền xác nhận yêu cầu này.");
            if (req.Status != "Pending") return (false, "Trạng thái yêu cầu không hợp lệ.");

            if (req.RequesterSchedule == null || req.TargetSchedule == null)
                return (false, "Lịch làm việc liên quan không còn tồn tại.");

            // Direct P2P Swap
            int tempAccountId = req.RequesterSchedule.AccountId;
            req.RequesterSchedule.AccountId = req.TargetSchedule.AccountId;
            req.TargetSchedule.AccountId = tempAccountId;

            req.Status = "Completed"; // Mark as Completed automatically

            await _context.SaveChangesAsync();

            return (true, "Đổi ca thành công! Ca làm việc đã được tự động hoán đổi.");
        }

        public async Task<(bool Success, string Message)> RejectSwapRequestByTarget(int swapRequestId, int targetId)
        {
            var req = await _context.ShiftSwapRequests.FindAsync(swapRequestId);
            if (req == null) return (false, "Yêu cầu đổi ca không tồn tại.");
            if (req.TargetId != targetId) return (false, "Bạn không có quyền từ chối yêu cầu này.");
            if (req.Status != "Pending") return (false, "Trạng thái yêu cầu không hợp lệ.");

            req.Status = "Rejected";

            await _context.SaveChangesAsync();
            return (true, "Đã từ chối yêu cầu đổi ca.");
        }

        public async Task<(bool Success, string Message)> ApproveSwapRequest(int swapRequestId, int managerId)
        {
            var req = await _context.ShiftSwapRequests
                .Include(r => r.RequesterSchedule)
                .Include(r => r.TargetSchedule)
                .FirstOrDefaultAsync(r => r.SwapRequestId == swapRequestId);

            if (req == null) return (false, "Yêu cầu không tồn tại.");
            if (req.Status != "Consented") return (false, "Yêu cầu phải được đồng nghiệp chấp thuận (Consented) trước khi Manager phê duyệt.");

            // Swap records
            int tempAccountId = req.RequesterSchedule.AccountId;
            req.RequesterSchedule.AccountId = req.TargetSchedule.AccountId;
            req.TargetSchedule.AccountId = tempAccountId;

            req.Status = "Approved";
            req.ApprovedById = managerId;

            await _context.SaveChangesAsync();
            return (true, "Đã phê duyệt và hoán đổi ca làm việc thành công.");
        }

        public async Task<(bool Success, string Message)> RejectSwapRequest(int swapRequestId, int managerId)
        {
            var req = await _context.ShiftSwapRequests.FindAsync(swapRequestId);
            if (req == null) return (false, "Yêu cầu không tồn tại.");

            req.Status = "Rejected";
            req.ApprovedById = managerId;

            await _context.SaveChangesAsync();
            return (true, "Đã từ chối yêu cầu đổi ca.");
        }

        // 4. LEAVE REQUEST LOGIC
        public async Task<(bool Success, string Message)> SubmitLeaveRequest(int accountId, int scheduleId, string reason)
        {
            var sched = await _context.EmployeeSchedules.FindAsync(scheduleId);
            if (sched == null || sched.AccountId != accountId)
                return (false, "Lịch làm việc không hợp lệ.");

            var leaveReq = new LeaveRequest
            {
                AccountId = accountId,
                ScheduleId = scheduleId,
                Reason = reason,
                Status = "Pending",
                CreatedAt = DateTime.Now
            };

            _context.LeaveRequests.Add(leaveReq);
            await _context.SaveChangesAsync();

            return (true, "Đã gửi đơn xin nghỉ phép thành công. Chờ Quản lý duyệt.");
        }

        public async Task<(bool Success, string Message)> ApproveLeaveRequest(int leaveRequestId, int managerId)
        {
            var req = await _context.LeaveRequests
                .Include(r => r.Schedule)
                .FirstOrDefaultAsync(r => r.LeaveRequestId == leaveRequestId);

            if (req == null) return (false, "Đơn xin nghỉ không tồn tại.");

            if (req.Schedule == null)
            {
                // Attempt to explicitly load the reference
                await _context.Entry(req).Reference(r => r.Schedule).LoadAsync();

                if (req.Schedule == null)
                {
                    // Attempt direct manual lookup
                    var sched = await _context.EmployeeSchedules.FindAsync(req.ScheduleId);
                    if (sched != null)
                    {
                        req.Schedule = sched;
                    }
                    else
                    {
                        return (false, $"Không tìm thấy lịch làm việc liên quan (ScheduleId: {req.ScheduleId}).");
                    }
                }
            }

            if (req.Status != "Pending") return (false, "Đơn đã được xử lý trước đó.");

            req.Status = "Approved";
            req.ApprovedById = managerId;

            // Deactivate schedule record (Status = Off / Deactivated, IsActive = false)
            req.Schedule.Status = "Off";
            req.Schedule.IsActive = false;

            await _context.SaveChangesAsync();
            return (true, "Đã phê duyệt đơn xin nghỉ. Ca làm việc đã được chuyển sang trạng thái Off.");
        }

        public async Task<(bool Success, string Message)> RejectLeaveRequest(int leaveRequestId, int managerId)
        {
            var req = await _context.LeaveRequests.FindAsync(leaveRequestId);
            if (req == null) return (false, "Đơn xin nghỉ không tồn tại.");

            req.Status = "Rejected";
            req.ApprovedById = managerId;

            await _context.SaveChangesAsync();
            return (true, "Đã từ chối đơn xin nghỉ phép.");
        }

        public async Task<WeeklyGridViewModel> GetWeeklyGridDataAsync(string? startDate)
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

            return new WeeklyGridViewModel
            {
                StartOfWeek = monday,
                EndOfWeek = sunday,
                Shifts = shifts,
                RawSchedules = rawSchedules
            };
        }

        public async Task<object> GetShiftDetailsAsync(int? shiftId, string? date)
        {
            int sId = shiftId ?? 1;
            DateOnly workDate = string.IsNullOrEmpty(date) ? new DateOnly(2026, 7, 21) : DateOnly.Parse(date);

            var shift = await _context.WorkShifts.FindAsync(sId);
            if (shift == null)
            {
                return new { success = false, message = "Ca làm việc không tồn tại." };
            }

            var schedules = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .Include(s => s.Shift)
                .Where(s => s.ShiftId == sId && s.WorkDate == workDate)
                .ToListAsync();

            var accountIds = schedules.Select(s => s.AccountId).ToList();
            var profiles = await _context.EmployeeProfiles
                .Where(p => accountIds.Contains(p.AccountId))
                .ToListAsync();

            var staffList = schedules.Select(s => {
                var prof = profiles.FirstOrDefault(p => p.AccountId == s.AccountId);
                return new {
                    name = s.Account.FullName,
                    email = s.Account.Email ?? $"{s.Account.Username}@gmail.com",
                    citizenId = prof?.IdentityCardNumber ?? "N/A",
                    phone = s.Account.Phone ?? "N/A",
                    role = s.Account.Role.RoleName,
                    status = s.Status ?? "Scheduled"
                };
            }).ToList();

            return new
            {
                success = true,
                shiftName = shift.ShiftName,
                startTime = shift.StartTime.ToString(@"hh\:mm"),
                endTime = shift.EndTime.ToString(@"hh\:mm"),
                date = workDate.ToString("dd/MM/yyyy"),
                staff = staffList
            };
        }

        public async Task<LeaveApprovalsViewModel> GetLeaveApprovalsDataAsync()
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

            return new LeaveApprovalsViewModel
            {
                PendingRequests = pending,
                HistoryRequests = history
            };
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
                .Where(a => a.Role != null && a.Role.RoleName != "Customer" && a.IsActive == true)
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
    }
}
