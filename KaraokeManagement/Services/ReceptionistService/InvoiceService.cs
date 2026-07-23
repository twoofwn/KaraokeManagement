using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;
namespace KaraokeManagement.Services.ReceptionistServices;
public class InvoiceService
{
    private readonly KaraokeManagementDbContext _context;
    public InvoiceService(KaraokeManagementDbContext context) => _context = context;

    public async Task<InvoiceHistoryViewModel> GetInvoiceHistoryAsync(string searchString, string customerFilter, DateTime? fromDate, DateTime? toDate, string status, int page)
    {
        var query = _context.Invoices.Include(i => i.Room).Include(i => i.Booking).ThenInclude(b => b.Customer).Include(i => i.Receptionist).AsQueryable();

        if (!string.IsNullOrEmpty(searchString))
        {
            var term = searchString.Trim().ToLower();
            string cleanTerm = term.Replace("#", "").Replace("lum-", "", StringComparison.OrdinalIgnoreCase);
            bool isNumeric = int.TryParse(cleanTerm, out int searchId);
            query = query.Where(i => (isNumeric && i.InvoiceId == searchId) || (i.Booking != null && i.Booking.Customer != null && i.Booking.Customer.FullName.ToLower().Contains(term)) || (i.Receptionist != null && i.Receptionist.FullName.ToLower().Contains(term)));
        }

        if (!string.IsNullOrEmpty(customerFilter))
        {
            var term = customerFilter.Trim().ToLower();
            query = query.Where(i => i.Booking != null && i.Booking.Customer != null && (i.Booking.Customer.FullName.ToLower().Contains(term) || i.Booking.Customer.Phone.Contains(term)));
        }

        if (fromDate.HasValue) query = query.Where(i => i.CheckInTime >= fromDate.Value);
        if (toDate.HasValue)
        {
            var endOfDay = toDate.Value.Date.AddDays(1).AddTicks(-1);
            query = query.Where(i => i.CheckInTime <= endOfDay);
        }
        if (!string.IsNullOrEmpty(status) && status != "All" && status != "Tất cả") query = query.Where(i => i.Status == status);

        int pageSize = 10;
        int totalCount = await query.CountAsync();
        int totalPages = Math.Max(1, (int)Math.Ceiling((double)totalCount / pageSize));
        page = Math.Clamp(page, 1, totalPages);

        var invoices = await query.OrderByDescending(i => i.CheckInTime).Skip((page - 1) * pageSize).Take(pageSize)
            .Select(i => new InvoiceItemViewModel
            {
                InvoiceId = i.InvoiceId,
                RoomName = i.Room.RoomName,
                CustomerName = i.Booking != null && i.Booking.Customer != null ? i.Booking.Customer.FullName : "Khách vãng lai",
                CustomerPhone = i.Booking != null && i.Booking.Customer != null ? i.Booking.Customer.Phone : "",
                ReceptionistName = i.Receptionist.FullName ?? "Chưa rõ",
                CheckInTime = i.CheckInTime,
                CheckOutTime = i.CheckOutTime,
                TotalAmount = i.GrandTotal ?? 0,
                Status = i.Status ?? "Unpaid"
            }).ToListAsync();

        return new InvoiceHistoryViewModel { Invoices = invoices, SearchString = searchString ?? string.Empty, CustomerFilter = customerFilter ?? string.Empty, FromDate = fromDate, ToDate = toDate, SelectedStatus = status, CurrentPage = page, TotalPages = totalPages, TotalCount = totalCount, PageSize = pageSize };
    }

    public async Task<CheckoutViewModel?> GetInvoiceDetailAsync(int invoiceId)
    {
        var invoice = await _context.Invoices.Include(i => i.Room).ThenInclude(r => r.RoomType).Include(i => i.InvoiceDetails).ThenInclude(id => id.Service).Include(i => i.Booking).ThenInclude(b => b.Customer).ThenInclude(c => c.Tier).FirstOrDefaultAsync(i => i.InvoiceId == invoiceId);
        if (invoice == null) return null;

        var duration = TimeSpan.FromSeconds(Math.Max(0, ((invoice.CheckOutTime ?? DateTime.Now) - invoice.CheckInTime).TotalSeconds));
        decimal roomTotal = invoice.RoomTotal ?? (decimal)duration.TotalHours * invoice.Room.RoomType.PricePerHour;
        decimal serviceTotal = invoice.ServiceTotal ?? invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);
        decimal discountPercent = invoice.Booking?.Customer?.Tier?.DiscountPercent ?? 0;
        decimal discountAmount = invoice.DiscountAmount ?? (roomTotal + serviceTotal) * discountPercent / 100;

        return new CheckoutViewModel
        {
            InvoiceId = invoice.InvoiceId,
            RoomId = invoice.RoomId,
            RoomName = invoice.Room.RoomName,
            RoomTypeName = invoice.Room.RoomType.TypeName,
            PricePerHour = invoice.Room.RoomType.PricePerHour,
            CheckInTime = invoice.CheckInTime,
            CheckOutTime = invoice.CheckOutTime ?? DateTime.Now,
            DurationHours = duration.TotalHours,
            DurationText = $"{(int)duration.TotalHours}h {duration.Minutes}m",
            RoomTotal = roomTotal,
            ServiceTotal = serviceTotal,
            DiscountPercent = discountPercent,
            DiscountAmount = discountAmount,
            GrandTotal = invoice.GrandTotal ?? (roomTotal + serviceTotal - discountAmount),
            CustomerName = invoice.Booking?.Customer?.FullName ?? "Khách vãng lai",
            CustomerPhone = invoice.Booking?.Customer?.Phone ?? "",
            CustomerTier = invoice.Booking?.Customer?.Tier?.TierName ?? "THƯỜNG",
            OrderItems = invoice.InvoiceDetails.Select(id => new CheckoutItemViewModel { ServiceName = id.Service.ServiceName, Quantity = id.Quantity, UnitPrice = id.UnitPrice, TotalPrice = id.Quantity * id.UnitPrice, Unit = id.Service.Unit }).ToList()
        };
    }
}