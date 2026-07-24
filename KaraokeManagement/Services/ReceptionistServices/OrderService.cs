using KaraokeManagement.Controllers;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;
namespace KaraokeManagement.Services.ReceptionistServices;
public class OrderService
{
    private readonly KaraokeManagementDbContext _context;
    public OrderService(KaraokeManagementDbContext context) => _context = context;

    public async Task<RoomDetailPosViewModel?> GetRoomDetailAsync(int roomId, string? userName)
    {
        var room = await _context.Rooms
            .Include(r => r.RoomType)
            .FirstOrDefaultAsync(r => r.RoomId == roomId);

        if (room == null) return null;

        var invoice = await _context.Invoices
            .Include(i => i.Booking).ThenInclude(b => b.Staff)
            .Include(i => i.InvoiceDetails)
            .ThenInclude(id => id.Service)
            .FirstOrDefaultAsync(i => i.RoomId == roomId && i.Status == "Unpaid");

        if (invoice == null)
        {
            var receptionist = await _context.Accounts.FirstOrDefaultAsync(a => a.FullName == userName || a.Username == userName)
                               ?? await _context.Accounts.FirstOrDefaultAsync();

            int receptionistId = receptionist?.AccountId ?? 1;

            invoice = new Invoice
            {
                RoomId = roomId,
                ReceptionistId = receptionistId,
                CheckInTime = DateTime.Now,
                Status = "Unpaid",
                RoomTotal = 0,
                ServiceTotal = 0,
                DiscountAmount = 0,
                GrandTotal = 0
            };

            _context.Invoices.Add(invoice);
            if (room.Status != "InUse") room.Status = "InUse";
            await _context.SaveChangesAsync();
        }

        var categories = await _context.Categories.Select(c => new CategoryViewModel { CategoryId = c.CategoryId, CategoryName = c.CategoryName }).ToListAsync();
        var serviceItems = await _context.ServiceItems.Include(s => s.Category)
            .Select(s => new PosProductItem { ServiceId = s.ServiceId, CategoryId = s.CategoryId, ServiceName = s.ServiceName, SellingPrice = s.SellingPrice, Unit = s.Unit, StockQuantity = s.StockQuantity ?? 0, CategoryName = s.Category.CategoryName , imageURL = s.ImageUrl ?? "/img/Reception_img/dia_trai_cay.jpg" }).ToListAsync();

        var orderItems = invoice.InvoiceDetails.Select(id => new PosOrderItem { InvoiceDetailId = id.InvoiceDetailId, ServiceId = id.ServiceId, ServiceName = id.Service.ServiceName, Unit = id.Service.Unit, Quantity = id.Quantity, UnitPrice = id.UnitPrice }).ToList();

        var availableRooms = await _context.Rooms.Include(r => r.RoomType).Where(r => r.Status == "Available" && r.RoomId != roomId)
            .Select(r => new PosRoomItem { RoomId = r.RoomId, RoomName = r.RoomName, RoomTypeName = r.RoomType.TypeName, PricePerHour = r.RoomType.PricePerHour }).ToListAsync();

        return new RoomDetailPosViewModel
        {
            RoomId = room.RoomId,
            RoomName = room.RoomName,
            RoomTypeName = room.RoomType.TypeName,
            PricePerHour = room.RoomType.PricePerHour,
            RoomStatus = room.Status ?? "InUse",
            InvoiceId = invoice.InvoiceId,
            StaffName = invoice.Booking?.Staff?.FullName ?? "Chưa phân công",
            CheckInTime = invoice.CheckInTime,
            OrderItems = orderItems,
            ProductItems = serviceItems,
            Categories = categories,
            AvailableRooms = availableRooms
        };
    }

    public async Task<(bool success, string message)> AddServiceItemAsync(AddServiceRequest request)
    {
        var service = await _context.ServiceItems.FindAsync(request.ServiceId);
        if (service == null) return (false, "Sản phẩm không tồn tại.");
        if (service.StockQuantity <= 0) return (false, "Sản phẩm đã hết hàng trong kho.");

        var invoice = await _context.Invoices.Include(i => i.InvoiceDetails)
            .FirstOrDefaultAsync(i => i.RoomId == request.RoomId && i.Status == "Unpaid");
        if (invoice == null) return (false, "Không tìm thấy hóa đơn chưa thanh toán cho phòng này.");

        var detail = invoice.InvoiceDetails.FirstOrDefault(d => d.ServiceId == request.ServiceId);
        if (detail != null) detail.Quantity += 1;
        else
        {
            detail = new InvoiceDetail { InvoiceId = invoice.InvoiceId, ServiceId = request.ServiceId, Quantity = 1, UnitPrice = service.SellingPrice };
            _context.InvoiceDetails.Add(detail);
        }

        if (service.StockQuantity.HasValue) service.StockQuantity -= 1;

        await _context.SaveChangesAsync();
        await RecalculateInvoiceTotalsAsync(invoice.InvoiceId);

        return (true, string.Empty);
    }

    public async Task<(bool success, string message)> UpdateServiceItemAsync(UpdateServiceRequest request)
    {
        var detail = await _context.InvoiceDetails.Include(d => d.Service).FirstOrDefaultAsync(d => d.InvoiceDetailId == request.InvoiceDetailId);
        if (detail == null) return (false, "Không tìm thấy chi tiết hóa đơn.");

        int diff = request.Quantity - detail.Quantity;
        if (diff > 0 && detail.Service.StockQuantity.HasValue && detail.Service.StockQuantity.Value < diff)
            return (false, $"Không đủ số lượng trong kho. Còn lại: {detail.Service.StockQuantity.Value}");

        if (detail.Service.StockQuantity.HasValue) detail.Service.StockQuantity -= diff;
        detail.Quantity = request.Quantity;

        await _context.SaveChangesAsync();
        await RecalculateInvoiceTotalsAsync(detail.InvoiceId);

        return (true, string.Empty);
    }

    public async Task<(bool success, string message)> RemoveServiceItemAsync(RemoveServiceRequest request)
    {
        var detail = await _context.InvoiceDetails.Include(d => d.Service).FirstOrDefaultAsync(d => d.InvoiceDetailId == request.InvoiceDetailId);
        if (detail == null) return (false, "Không tìm thấy chi tiết hóa đơn.");

        if (detail.Service.StockQuantity.HasValue) detail.Service.StockQuantity += detail.Quantity;

        int invoiceId = detail.InvoiceId;
        _context.InvoiceDetails.Remove(detail);

        await _context.SaveChangesAsync();
        await RecalculateInvoiceTotalsAsync(invoiceId);

        return (true, string.Empty);
    }

    private async Task RecalculateInvoiceTotalsAsync(int invoiceId)
    {
        var invoice = await _context.Invoices
            .Include(i => i.InvoiceDetails).Include(i => i.Room).ThenInclude(r => r.RoomType)
            .FirstOrDefaultAsync(i => i.InvoiceId == invoiceId);

        if (invoice != null)
        {
            decimal serviceTotal = invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);
            invoice.ServiceTotal = serviceTotal;

            var duration = DateTime.Now - invoice.CheckInTime;
            double hours = Math.Max(0, duration.TotalHours);
            decimal roomTotal = (decimal)hours * invoice.Room.RoomType.PricePerHour;

            invoice.RoomTotal = roomTotal;
            invoice.GrandTotal = roomTotal + serviceTotal - (invoice.DiscountAmount ?? 0);

            await _context.SaveChangesAsync();
        }
    }
}