using KaraokeManagement.Controllers;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;
namespace KaraokeManagement.Services.ReceptionistServices;
public class PaymentService
{
    private readonly KaraokeManagementDbContext _context;
    public PaymentService(KaraokeManagementDbContext context) => _context = context;

    // Tong hop thong tin de check-out
    public async Task<CheckoutViewModel?> GetCheckoutViewModelAsync(int invoiceId)
    {
        var invoice = await _context.Invoices.Include(i => i.Room).ThenInclude(r => r.RoomType).Include(i => i.InvoiceDetails).ThenInclude(id => id.Service).Include(i => i.Booking).ThenInclude(b => b.Customer).ThenInclude(c => c.Tier).Include(i => i.Booking)
                                                .ThenInclude(b => b.Staff).FirstOrDefaultAsync(i => i.InvoiceId == invoiceId);
        if (invoice == null) return null;

        var duration = TimeSpan.FromSeconds(Math.Max(0, (DateTime.Now - invoice.CheckInTime).TotalSeconds));
        decimal roomTotal = (decimal)duration.TotalHours * invoice.Room.RoomType.PricePerHour;
        decimal serviceTotal = invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);
        decimal discountPercent = invoice.Booking?.Customer?.Tier?.DiscountPercent ?? 0;
        decimal discountAmount = (roomTotal + serviceTotal) * discountPercent / 100;

        var (surchargeAmount, surchargeNote) = await CalculateSurchargeAsync(invoice.CheckInTime, roomTotal);

        decimal grandTotal = roomTotal + serviceTotal - discountAmount + surchargeAmount;

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
            GrandTotal = grandTotal,
            CustomerName = invoice.Booking?.Customer?.FullName ?? "Khách vãng lai",
            CustomerPhone = invoice.Booking?.Customer?.Phone ?? "",
            CustomerTier = invoice.Booking?.Customer?.Tier?.TierName ?? "THƯỜNG",
            StaffName = invoice.Booking?.Staff?.FullName ?? "Chưa phân công",
            SurchargeAmount = surchargeAmount,
            SurchargeNote = surchargeNote,
            OrderItems = invoice.InvoiceDetails.Select(id => new CheckoutItemViewModel { ServiceName = id.Service.ServiceName, Quantity = id.Quantity, UnitPrice = id.UnitPrice, TotalPrice = id.Quantity * id.UnitPrice, Unit = id.Service.Unit }).ToList()
        };
    }

    // Xac nhan check-out
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
            await CheckAndUpdateCustomerTierAsync(invoice.Booking.CustomerId, model.GrandTotal);
        }

        await _context.SaveChangesAsync();
        return true;
    }

    // Tinh phu thu
    private async Task<(decimal SurchargeAmount, string SurchargeNote)> CalculateSurchargeAsync(DateTime startDateTime, decimal basePrice)
    {
        var holiday = await _context.Holidays.FirstOrDefaultAsync(h => h.IsActive && h.HolidayDate.Date == startDateTime.Date);

        if (holiday != null)
        {
            return (basePrice * (holiday.SurchargePercent / 100m), $"{holiday.HolidayName} ({holiday.SurchargePercent.ToString("0.##")}%)");
        }

        if (startDateTime.DayOfWeek == DayOfWeek.Saturday || startDateTime.DayOfWeek == DayOfWeek.Sunday)
        {
            var weekendPolicy = await _context.PricingPolicies.FirstOrDefaultAsync(p => p.IsActive && p.PolicyType == "Weekend");
            if (weekendPolicy != null)
            {
                return (basePrice * (weekendPolicy.Value / 100m), $"{weekendPolicy.PolicyName} ({weekendPolicy.Value.ToString("0.##")}%)");
            }
        }

        return (0, "");
    }

    // Update hang khach hang
    private async Task CheckAndUpdateCustomerTierAsync(int? customerId, decimal paidAmount)
    {
        if (!customerId.HasValue) return;

        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.CustomerId == customerId.Value);

        if (customer == null) return;

        var activePolicy = await _context.LoyalPointPolicies
            .FirstOrDefaultAsync(p => p.IsActive);

        decimal amountPerPoint = (activePolicy != null && activePolicy.AmountPerPoint > 0)
            ? activePolicy.AmountPerPoint
            : 10000m;

        int earnedPoints = (int)(paidAmount / amountPerPoint);
        customer.LoyaltyPoints = (customer.LoyaltyPoints ?? 0) + earnedPoints;

        var eligibleTier = await _context.MembershipTiers
            .Where(t => t.MinPoints != null && customer.LoyaltyPoints >= t.MinPoints)
            .OrderByDescending(t => t.MinPoints)
            .FirstOrDefaultAsync();

        if (eligibleTier != null && customer.TierId != eligibleTier.TierId)
        {
            customer.TierId = eligibleTier.TierId;
        }
    }
}