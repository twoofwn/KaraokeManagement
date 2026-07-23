using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.ManagerServices
{
    public class InvoiceService
    {
        private readonly KaraokeManagementDbContext _context;

        public InvoiceService(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public async Task<ManagerInvoicesViewModel> GetInvoicesAsync(string? searchInvoiceId, DateTime? searchDate, int? roomId, DateTime? fromDate, DateTime? toDate, int page)
        {
            var now = DateTime.Now;
            var end = toDate ?? new DateTime(now.Year, now.Month, now.Day, 23, 59, 59);
            var start = fromDate ?? new DateTime(now.Year, now.Month, 1).AddMonths(-1);

            var query = _context.Invoices
                .Include(i => i.Room)
                .Include(i => i.Booking)
                    .ThenInclude(b => b!.Customer)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(searchInvoiceId))
            {
                var cleanSearch = searchInvoiceId.Replace("#", "").Replace("INV-", "").Replace("inv-", "").Trim();
                query = query.Where(i => i.InvoiceId.ToString().Contains(cleanSearch));
            }

            if (roomId.HasValue && roomId.Value > 0)
            {
                query = query.Where(i => i.RoomId == roomId.Value);
            }

            if (searchDate.HasValue)
            {
                var targetDate = searchDate.Value.Date;
                query = query.Where(i => i.CheckInTime.Date == targetDate);
            }
            else
            {
                var searchStart = start.Date;
                var searchEnd = end.Date.AddDays(1).AddTicks(-1);
                query = query.Where(i => i.CheckInTime >= searchStart && i.CheckInTime <= searchEnd);
            }

            int totalCount = await query.CountAsync();
            int pageSize = 10;
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages == 0) totalPages = 1;

            if (page < 1) page = 1;
            if (page > totalPages) page = totalPages;

            var invoices = await query
                .OrderByDescending(i => i.CheckInTime)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            int startEntry = totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
            int endEntry = Math.Min(page * pageSize, totalCount);

            var roomsList = await _context.Rooms.OrderBy(r => r.RoomName).ToListAsync();

            return new ManagerInvoicesViewModel
            {
                Invoices = invoices,
                FromDate = start,
                ToDate = end,
                SearchInvoiceId = searchInvoiceId,
                SearchDate = searchDate,
                SelectedRoomId = roomId,
                Rooms = roomsList,
                CurrentPage = page,
                TotalPages = totalPages,
                TotalCount = totalCount,
                StartEntry = startEntry,
                EndEntry = endEntry
            };
        }

        public async Task<(bool Success, string Message, object Data)> GetInvoiceDetailAsync(int invoiceId)
        {
            try
            {
                var invoice = await _context.Invoices
                    .Include(i => i.Room).ThenInclude(r => r.RoomType)
                    .Include(i => i.Receptionist)
                    .Include(i => i.Booking).ThenInclude(b => b!.Customer).ThenInclude(c => c.Tier)
                    .Include(i => i.Booking).ThenInclude(b => b!.Staff)
                    .Include(i => i.InvoiceDetails).ThenInclude(d => d.Service)
                    .Include(i => i.PaymentTransactions).ThenInclude(t => t.Method)
                    .FirstOrDefaultAsync(i => i.InvoiceId == invoiceId);

                if (invoice == null)
                    return (false, "Không tìm thấy hóa đơn.", null!);

                var duration = (invoice.CheckOutTime ?? DateTime.Now) - invoice.CheckInTime;
                string durationText = $"{(int)duration.TotalHours} giờ {duration.Minutes} phút";

                var staffNamesText = invoice.Booking?.Staff?.FullName ?? "Chưa phân công";

                var details = new
                {
                    invoiceId = invoice.InvoiceId,
                    roomName = invoice.Room?.RoomName ?? "Chưa rõ",
                    roomTypeName = invoice.Room?.RoomType?.TypeName ?? "Chưa rõ",
                    pricePerHour = invoice.Room?.RoomType?.PricePerHour ?? 0,
                    checkInTime = invoice.CheckInTime.ToString("dd/MM/yyyy HH:mm"),
                    checkOutTime = invoice.CheckOutTime?.ToString("dd/MM/yyyy HH:mm") ?? "Chưa checkout",
                    durationText = durationText,
                    customerName = invoice.Booking?.Customer?.FullName ?? "Khách lẻ",
                    customerPhone = invoice.Booking?.Customer?.Phone ?? "N/A",
                    customerTier = invoice.Booking?.Customer?.Tier?.TierName ?? "Thường",
                    discountPercent = invoice.Booking?.Customer?.Tier?.DiscountPercent ?? 0,
                    staffNames = staffNamesText,
                    receptionistName = invoice.Receptionist?.FullName ?? "N/A",
                    roomTotal = invoice.RoomTotal ?? 0,
                    serviceTotal = invoice.ServiceTotal ?? 0,
                    discountAmount = invoice.DiscountAmount ?? 0,
                    grandTotal = invoice.GrandTotal ?? 0,
                    status = invoice.Status,
                    items = invoice.InvoiceDetails.Select(d => new
                    {
                        serviceName = d.Service?.ServiceName ?? "Dịch vụ không tồn tại",
                        quantity = d.Quantity,
                        unitPrice = d.UnitPrice,
                        total = d.Quantity * d.UnitPrice,
                        unit = d.Service?.Unit ?? "Cái"
                    }).ToList(),
                    payments = invoice.PaymentTransactions.Select(t => new
                    {
                        methodName = t.Method?.MethodName ?? "Chưa rõ",
                        amount = t.Amount,
                        date = t.TransactionDate?.ToString("dd/MM/yyyy HH:mm") ?? "",
                        refCode = t.ReferenceCode ?? ""
                    }).ToList()
                };

                return (true, "Thành công", details);
            }
            catch (Exception ex)
            {
                return (false, $"Lỗi hệ thống: {ex.Message}", null!);
            }
        }
    }
}
