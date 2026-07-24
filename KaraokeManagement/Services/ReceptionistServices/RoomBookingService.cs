using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;
namespace KaraokeManagement.Services.ReceptionistServices;

public class RoomBookingService
{
    private readonly KaraokeManagementDbContext _context;
    public RoomBookingService(KaraokeManagementDbContext context) => _context = context;

    public async Task<CheckInViewModel> GetCheckInViewModelAsync(int? roomId, string currentEmployeeName)
    {
        var availableRooms = await _context.Rooms.Include(r => r.RoomType)
            .Where(r => r.Status == "Available" || r.RoomId == roomId)
            .Select(r => new AvailableRoomItem { RoomId = r.RoomId, RoomName = r.RoomName, TypeName = r.RoomType.TypeName, PricePerHour = r.RoomType.PricePerHour })
            .ToListAsync();

        var today = DateOnly.FromDateTime(DateTime.Today);
        var nowTime = DateTime.Now.TimeOfDay;
        var activeShift = await _context.WorkShifts
            .FirstOrDefaultAsync(s => (s.StartTime <= nowTime && s.EndTime >= nowTime) || (s.StartTime > s.EndTime && (nowTime >= s.StartTime || nowTime <= s.EndTime)));

        var availableStaff = await _context.EmployeeSchedules.Include(s => s.Account).ThenInclude(a => a.Role)
            .Where(s => s.WorkDate == today && s.ShiftId == activeShift.ShiftId && s.IsActive && s.Status != "Off" && (s.Account.Role.RoleName.Contains("Service Staff") || s.Account.Role.RoleName.Contains("Phục vụ")) && s.Account.IsActive == true)
            .Select(s => s.Account).ToListAsync();

        if (!availableStaff.Any())
        {
            availableStaff = await _context.Accounts.Include(a => a.Role)
                .Where(a => (a.Role.RoleName.Contains("Service Staff") || a.Role.RoleName.Contains("Phục vụ")) && a.IsActive == true).ToListAsync();
        }

        return new CheckInViewModel
        {
            CurrentEmployeeName = currentEmployeeName,
            AvailableRooms = availableRooms,
            AvailableServiceStaff = availableStaff,
            RoomId = roomId ?? 0,
            CheckInTime = DateTime.Now
        };
    }

    public async Task<(bool success, string message)> ProcessPaymentAsync(PaymentRequest request)
    {
        var invoice = await _context.Invoices.Include(i => i.InvoiceDetails).Include(i => i.Room).ThenInclude(r => r.RoomType)
            .FirstOrDefaultAsync(i => i.InvoiceId == request.InvoiceId);
        if (invoice == null) return (false, "Không tìm thấy hóa đơn.");

        invoice.CheckOutTime = DateTime.Now;
        invoice.ServiceTotal = invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);

        double hours = Math.Max(0, (invoice.CheckOutTime.Value - invoice.CheckInTime).TotalHours);
        invoice.RoomTotal = (decimal)hours * invoice.Room.RoomType.PricePerHour;
        invoice.GrandTotal = invoice.RoomTotal + invoice.ServiceTotal - (invoice.DiscountAmount ?? 0);
        invoice.Status = "Paid";
        invoice.Room.Status = "Available";

        await _context.SaveChangesAsync();
        return (true, "Thanh toán hóa đơn thành công!");
    }

    public async Task<(bool success, string message)> ChangeRoomAsync(
        ChangeRoomRequest request,
        int staffId,
        int? assignedStaffId = null)
    {
        if (string.IsNullOrWhiteSpace(request.Reason)) return (false, "Vui lòng nhập đầy đủ lý do đổi phòng.");
        if (request.Reason.Trim().Length > 255) return (false, "Lý do đổi phòng không được vượt quá 255 ký tự.");
        if (request.OldRoomStatus != "Available" && request.OldRoomStatus != "Maintenance")
            return (false, "Trạng thái phòng cũ không hợp lệ.");

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var invoice = await _context.Invoices
                .Include(i => i.Booking)
                .FirstOrDefaultAsync(i => i.InvoiceId == request.InvoiceId && i.Status == "Unpaid");
            if (invoice == null) return (false, "Không tìm thấy hóa đơn đang hoạt động.");

            if (invoice.BookingId is not int bookingId || invoice.Booking == null)
                return (false, "Hóa đơn không gắn với đơn đặt phòng hợp lệ.");

            if (assignedStaffId.HasValue
                && (invoice.Booking.StaffId != assignedStaffId.Value
                    || invoice.Booking.Status != "CheckedIn"))
            {
                return (false, "Bạn chỉ được đổi phòng đang được phân công phục vụ.");
            }

            var oldRoom = await _context.Rooms.FindAsync(invoice.RoomId);
            var newRoom = await _context.Rooms.FindAsync(request.NewRoomId);

            if (oldRoom == null) return (false, "Không tìm thấy phòng hiện tại.");
            if (oldRoom.RoomId == request.NewRoomId) return (false, "Phòng mới phải khác phòng hiện tại.");
            if (newRoom == null || newRoom.Status != "Available") return (false, "Phòng mới không tồn tại hoặc không sẵn sàng.");

            _context.RoomTransferHistories.Add(new RoomTransferHistory
            {
                BookingId = bookingId,
                FromRoomId = invoice.RoomId,
                ToRoomId = request.NewRoomId,
                TransferredAt = DateTime.Now,
                Reason = request.Reason.Trim(),
                ProcessedById = staffId
            });

            if (oldRoom != null)
            {
                oldRoom.Status = request.OldRoomStatus;
                if (request.OldRoomStatus == "Maintenance")
                {
                    _context.MaintenanceLogs.Add(new MaintenanceLog
                    {
                        EquipmentId = 1,
                        ReportedById = staffId,
                        IssueDescription = request.Reason.Trim(),
                        LogDate = DateTime.Now,
                        RepairCost = 0
                    });
                }
            }

            newRoom.Status = "InUse";
            invoice.RoomId = request.NewRoomId;
            invoice.Booking.RoomId = request.NewRoomId;

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return (true, "Đổi phòng thành công.");
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            return (false, "Có lỗi xảy ra: " + ex.Message);
        }
    }

    public async Task<(bool found, int roomId, string? status)> GetInvoiceRoomStateAsync(int invoiceId)
    {
        var invoice = await _context.Invoices
            .AsNoTracking()
            .Where(i => i.InvoiceId == invoiceId)
            .Select(i => new { i.RoomId, i.Status })
            .FirstOrDefaultAsync();

        return invoice == null
            ? (false, 0, null)
            : (true, invoice.RoomId, invoice.Status);
    }

    public async Task<bool> ProcessCheckInAsync(CheckInViewModel model, string? userName)
    {
        var room = await _context.Rooms.FindAsync(model.RoomId);
        if (room == null) return false;

        var receptionist = await _context.Accounts.FirstOrDefaultAsync(a => a.FullName == userName || a.Username == userName) ?? await _context.Accounts.FirstOrDefaultAsync();
        int receptionistId = receptionist?.AccountId ?? 1;

        int finalCustomerId = model.CustomerId ?? (await GetOrCreateGuestCustomerAsync());

        var booking = new Booking { CustomerId = finalCustomerId, RoomId = model.RoomId, CreatedById = receptionistId, StartTime = model.CheckInTime, EndTime = model.CheckOutTimeEstimated, BookingTime = DateTime.Now, Status = "CheckedIn" };
        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();

        _context.Invoices.Add(new Invoice { BookingId = booking.BookingId, RoomId = model.RoomId, ReceptionistId = receptionistId, CheckInTime = model.CheckInTime, Status = "Unpaid", RoomTotal = 0, ServiceTotal = 0, DiscountAmount = 0, GrandTotal = 0 });
        room.Status = "InUse";
        await _context.SaveChangesAsync();

        if (model.AssignedStaffIds != null && model.AssignedStaffIds.Any())
        {
            booking.StaffId = model.AssignedStaffIds.First();
            await _context.SaveChangesAsync();
        }

        return true;
    }

    private async Task<int> GetOrCreateGuestCustomerAsync()
    {
        var guest = await _context.Customers.FirstOrDefaultAsync(c => c.Phone == "0000000000");
        if (guest == null)
        {
            guest = new Customer { FullName = "Khách vãng lai", Phone = "0000000000", CreatedAt = DateTime.Now };
            _context.Customers.Add(guest);
            await _context.SaveChangesAsync();
        }
        return guest.CustomerId;
    }
}
