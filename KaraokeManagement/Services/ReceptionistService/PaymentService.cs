using KaraokeManagement.Controllers;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

public class PaymentService
{
    private readonly KaraokeManagementDbContext _context;
    public PaymentService(KaraokeManagementDbContext context) => _context = context;

    public async Task<(bool success, string message)> ProcessPaymentFastAsync(PaymentRequest request)
    {
        var invoice = await _context.Invoices
            .Include(i => i.InvoiceDetails)
            .Include(i => i.Room)
            .ThenInclude(r => r.RoomType)
            .FirstOrDefaultAsync(i => i.InvoiceId == request.InvoiceId);

        if (invoice == null)
        {
            return (false, "Không tìm thấy hóa đơn.");
        }

        var room = invoice.Room;
        invoice.CheckOutTime = DateTime.Now;

        decimal serviceTotal = invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);
        invoice.ServiceTotal = serviceTotal;

        var duration = invoice.CheckOutTime.Value - invoice.CheckInTime;
        double hours = duration.TotalHours;
        if (hours < 0) hours = 0;

        decimal roomTotal = (decimal)hours * room.RoomType.PricePerHour;
        invoice.RoomTotal = roomTotal;

        invoice.GrandTotal = roomTotal + serviceTotal - (invoice.DiscountAmount ?? 0);
        invoice.Status = "Paid";

        if (room != null)
        {
            room.Status = "Available";
        }

        await _context.SaveChangesAsync();

        return (true, "Thanh toán hóa đơn thành công!");
    }

    public async Task<CheckoutViewModel?> GetCheckoutViewModelAsync(int invoiceId)
    {
        var invoice = await _context.Invoices.Include(i => i.Room).ThenInclude(r => r.RoomType).Include(i => i.InvoiceDetails).ThenInclude(id => id.Service).Include(i => i.Booking).ThenInclude(b => b.Customer).ThenInclude(c => c.Tier).FirstOrDefaultAsync(i => i.InvoiceId == invoiceId);
        if (invoice == null) return null;

        var duration = TimeSpan.FromSeconds(Math.Max(0, (DateTime.Now - invoice.CheckInTime).TotalSeconds));
        decimal roomTotal = (decimal)duration.TotalHours * invoice.Room.RoomType.PricePerHour;
        decimal serviceTotal = invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);
        decimal discountPercent = invoice.Booking?.Customer?.Tier?.DiscountPercent ?? 0;
        decimal discountAmount = (roomTotal + serviceTotal) * discountPercent / 100;

        return new CheckoutViewModel
        {
            InvoiceId = invoice.InvoiceId,
            RoomId = invoice.RoomId,
            RoomName = invoice.Room.RoomName,
            RoomTypeName = invoice.Room.RoomType.TypeName,
            PricePerHour = invoice.Room.RoomType.PricePerHour,
            CheckInTime = invoice.CheckInTime,
            CheckOutTime = DateTime.Now,
            DurationHours = duration.TotalHours,
            DurationText = $"{(int)duration.TotalHours}h {duration.Minutes}m",
            RoomTotal = roomTotal,
            ServiceTotal = serviceTotal,
            DiscountPercent = discountPercent,
            DiscountAmount = discountAmount,
            GrandTotal = roomTotal + serviceTotal - discountAmount,
            CustomerName = invoice.Booking?.Customer?.FullName ?? "Khách vãng lai",
            CustomerPhone = invoice.Booking?.Customer?.Phone ?? "",
            CustomerTier = invoice.Booking?.Customer?.Tier?.TierName ?? "THƯỜNG",
            OrderItems = invoice.InvoiceDetails.Select(id => new CheckoutItemViewModel { ServiceName = id.Service.ServiceName, Quantity = id.Quantity, UnitPrice = id.UnitPrice, TotalPrice = id.Quantity * id.UnitPrice, Unit = id.Service.Unit }).ToList()
        };
    }

    public async Task<bool> ProcessCheckoutAsync(CheckoutViewModel model)
    {
        var invoice = await _context.Invoices.Include(i => i.Room).Include(i => i.Booking).FirstOrDefaultAsync(i => i.InvoiceId == model.InvoiceId);
        if (invoice == null) return false;

        invoice.CheckOutTime = model.CheckOutTime;
        invoice.RoomTotal = model.RoomTotal; invoice.ServiceTotal = model.ServiceTotal; invoice.DiscountAmount = model.DiscountAmount; invoice.GrandTotal = model.GrandTotal;
        invoice.Status = "Paid"; invoice.Room.Status = "Available";

        if (invoice.Booking != null)
        {
            invoice.Booking.Status = "Completed";
            invoice.Booking.EndTime = model.CheckOutTime;
        }

        await _context.SaveChangesAsync();
        return true;
    }
}