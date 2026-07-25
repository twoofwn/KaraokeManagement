using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;

namespace KaraokeManagement.Services.StaffServices
{
    public class StaffService
    {
        private readonly KaraokeManagementDbContext _context;

        public StaffService(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public async Task<Account?> GetAccountAsync(int accountId, string? name)
        {
            Account? account = null;
            if (accountId > 0)
            {
                account = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == accountId);
            }

            if (account == null && !string.IsNullOrEmpty(name))
            {
                account = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.FullName == name || a.Username == name);
            }

            return account;
        }

        public async Task<(StaffDashboardViewModel? ViewModel, List<ShiftSwapRequest> IncomingSwapRequests)> GetDashboardDataAsync(int accountId, string? name)
        {
            var account = await GetAccountAsync(accountId, name);
            if (account == null) return (null, new List<ShiftSwapRequest>());

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

            return (viewModel, incomingSwapRequests);
        }

        public async Task<StaffScheduleViewModel?> GetScheduleViewModelAsync(int accountId, string? name, string? startDate)
        {
            var account = await GetAccountAsync(accountId, name);
            if (account == null) return null;

            DateTime start = string.IsNullOrEmpty(startDate) ? DateTime.Today : DateTime.Parse(startDate);
            
            // Normalize to Monday of the week
            int diff = (7 + (start.DayOfWeek - DayOfWeek.Monday)) % 7;
            DateTime monday = start.AddDays(-1 * diff).Date;
            DateTime sunday = monday.AddDays(6).Date;

            DateOnly monDate = DateOnly.FromDateTime(monday);
            DateOnly sunDate = DateOnly.FromDateTime(sunday);

            var rawShifts = await _context.WorkShifts.ToListAsync();
            var shifts = rawShifts.OrderBy(s => s.ShiftId).ThenBy(s => s.StartTime).ToList();
            var rawSchedules = await _context.EmployeeSchedules
                .Include(s => s.Shift)
                .Where(s => s.AccountId == account.AccountId && s.WorkDate >= monDate && s.WorkDate <= sunDate && s.IsActive && s.Status != "Off")
                .ToListAsync();

            return new StaffScheduleViewModel
            {
                Account = account,
                StartOfWeek = monday,
                EndOfWeek = sunday,
                Shifts = shifts,
                Schedules = rawSchedules
            };
        }

        public async Task<List<object>> GetShiftCoworkersAsync(int scheduleId)
        {
            var sched = await _context.EmployeeSchedules.FindAsync(scheduleId);
            if (sched == null) return new List<object>();

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

            return coworkers.Cast<object>().ToList();
        }

        public async Task<(bool Valid, string? Error, List<object>? Targets)> GetEligibleSwapTargetsAsync(int scheduleId, int currentAccountId)
        {
            var mySched = await _context.EmployeeSchedules
                .Include(s => s.Account)
                .FirstOrDefaultAsync(s => s.ScheduleId == scheduleId);

            if (mySched == null || mySched.AccountId != currentAccountId)
                return (false, "Lịch làm việc không hợp lệ.", null);

            var now = DateTime.Now;

            // Target employees must share the EXACT SAME Role and have an active schedule on any date that HAS NOT STARTED YET
            var eligibleSchedules = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .Include(s => s.Shift)
                .Where(s => s.AccountId != currentAccountId 
                            && s.Account.RoleId == mySched.Account.RoleId
                            && s.IsActive
                            && s.Status != "Off"
                            && s.Account.IsActive == true)
                .ToListAsync();

            var targets = eligibleSchedules
                .Where(s => {
                    var startDateTime = ScheduleService.GetShiftStartDateTime(s.WorkDate, s.Shift.StartTime);
                    return startDateTime > now;
                })
                .OrderBy(s => s.WorkDate)
                .ThenBy(s => s.Shift.StartTime)
                .Select(s => new {
                    scheduleId = s.ScheduleId,
                    accountId = s.AccountId,
                    fullName = s.Account.FullName,
                    workDate = s.WorkDate.ToString("dd/MM/yyyy"),
                    shiftName = s.Shift.ShiftName,
                    startTime = s.Shift.StartTime.ToString(@"hh\:mm"),
                    endTime = s.Shift.EndTime.ToString(@"hh\:mm")
                })
                .ToList();

            return (true, null, targets.Cast<object>().ToList());
        }

        public async Task<StaffLeaveRequestViewModel?> GetLeaveRequestViewModelAsync(int accountId, string? name)
        {
            var account = await GetAccountAsync(accountId, name);
            if (account == null) return null;

            var today = DateOnly.FromDateTime(DateTime.Today);
            var rawShifts = await _context.WorkShifts.ToListAsync();
            var shifts = rawShifts.OrderBy(s => s.ShiftId).ThenBy(s => s.StartTime).ToList();

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
                .Include(r => r.Shift)
                .Include(r => r.ApprovedBy)
                .Where(r => r.AccountId == account.AccountId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return new StaffLeaveRequestViewModel
            {
                Account = account,
                EligibleSchedules = eligibleSchedules,
                RequestHistory = requestHistory,
                WorkShifts = shifts
            };
        }

        public async Task<List<AssignedRoomViewModel>> GetAssignedRoomsAsync(int accountId)
        {
            var assignedRooms = await _context.Bookings
                .Where(b => b.StaffId == accountId && b.Status == "CheckedIn")
                .Select(b => new AssignedRoomViewModel
                {
                    BookingId = b.BookingId,
                    RoomId = b.RoomId,
                    RoomName = b.Room.RoomName,
                    RoomTypeName = b.Room.RoomType.TypeName,
                    CheckInTime = b.Invoices.OrderByDescending(i => i.CheckInTime).Select(i => i.CheckInTime).FirstOrDefault(),
                    UnfulfilledCount = b.Invoices.SelectMany(i => i.InvoiceDetails).Count(d => d.IsFulFilled == false)
                })
                .ToListAsync();

            return assignedRooms;
        }

        public async Task<AssignedDetailViewModel?> GetAssignedDetailAsync(int bookingId, int accountId)
        {
            var booking = await _context.Bookings.Include(b => b.Room).ThenInclude(r => r.RoomType).Include(b => b.Invoices).ThenInclude(i => i.InvoiceDetails).ThenInclude(id => id.Service).FirstOrDefaultAsync(b => b.BookingId == bookingId && b.StaffId == accountId && b.Status == "CheckedIn");

            if (booking == null) return null;

            var activeInvoice = booking.Invoices
                .OrderByDescending(i => i.CheckInTime)
                .FirstOrDefault();
            if (activeInvoice == null) return null;

            var canChangeRoom = activeInvoice.Status == "Unpaid";
            var availableRooms = canChangeRoom
                ? await _context.Rooms
                    .Include(r => r.RoomType)
                    .Where(r => r.Status == "Available" && r.RoomId != booking.RoomId)
                    .Select(r => new PosRoomItem
                    {
                        RoomId = r.RoomId,
                        RoomName = r.RoomName,
                        RoomTypeName = r.RoomType.TypeName,
                        PricePerHour = r.RoomType.PricePerHour
                    })
                    .ToListAsync()
                : new List<PosRoomItem>();

            var viewModel = new AssignedDetailViewModel
            {
                BookingId = booking.BookingId,
                RoomId = booking.RoomId,
                InvoiceId = activeInvoice.InvoiceId,
                CanChangeRoom = canChangeRoom,
                RoomName = booking.Room.RoomName,
                RoomTypeName = booking.Room.RoomType.TypeName,
                CheckInTime = activeInvoice.CheckInTime,
                Note = booking.Note,
                AvailableRooms = availableRooms,
                Services = activeInvoice.InvoiceDetails.Select(d => new ServiceItemDetail
                {
                    InvoiceDetailId = d.InvoiceDetailId,
                    ServiceName = d.Service.ServiceName,
                    Quantity = d.Quantity,
                    IsFulFilled = d.IsFulFilled,
                    Note = d.Note
                }).ToList()
            };

            return viewModel;
        }

        public async Task<bool> FulfillServiceItemAsync(int invoiceDetailId)
        {
            var detail = await _context.InvoiceDetails.FindAsync(invoiceDetailId);
            if (detail == null || detail.IsFulFilled)return false;
            detail.IsFulFilled = true;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> CancelServiceItemAsync(int invoiceDetailId)
        {
            var detail = await _context.InvoiceDetails.Include(d => d.Service).FirstOrDefaultAsync(d => d.InvoiceDetailId == invoiceDetailId);
            if (detail == null || detail.IsFulFilled) return false;
            if (detail.Service != null) detail.Service.StockQuantity -= detail.Quantity;
            _context.InvoiceDetails.Remove(detail);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
