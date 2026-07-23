using KaraokeManagement.Models;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.CustomerServices
{
    public class ServiceItemService
    {
        private readonly KaraokeManagementDbContext _context;
        public ServiceItemService(KaraokeManagementDbContext context) { _context = context; }

        public async Task<List<Category>> GetAllCategoriesAsync() => await _context.Categories.ToListAsync();

        public async Task<List<ServiceItem>> GetFilteredServicesAsync(string searchString, int? categoryId, decimal? minPrice, decimal? maxPrice, string sortOrder)
        {
            var query = _context.ServiceItems.Include(s => s.Category).AsQueryable();

            if (!string.IsNullOrEmpty(searchString)) query = query.Where(s => s.ServiceName.Contains(searchString));
            if (categoryId.HasValue) query = query.Where(s => s.CategoryId == categoryId.Value);
            if (minPrice.HasValue) query = query.Where(s => s.SellingPrice >= minPrice.Value);
            if (maxPrice.HasValue) query = query.Where(s => s.SellingPrice <= maxPrice.Value);

            query = sortOrder switch
            {
                "price-asc" => query.OrderBy(s => s.SellingPrice),
                "price-desc" => query.OrderByDescending(s => s.SellingPrice),
                "name-asc" => query.OrderBy(s => s.ServiceName),
                "name-desc" => query.OrderByDescending(s => s.ServiceName),
                _ => query.OrderBy(s => s.ServiceName)
            };
            return await query.ToListAsync();
        }

        public async Task<ServiceItem> GetServiceDetailAsync(int id) => await _context.ServiceItems.Include(s => s.Category).FirstOrDefaultAsync(s => s.ServiceId == id);

        public async Task<List<Booking>> GetActiveBookingsForCustomerAsync(int customerId)
        {
            var now = DateTime.Now;
            return await _context.Bookings.Include(b => b.Room)
                .Where(b => b.CustomerId == customerId && b.Status == "CheckedIn" && b.StartTime <= now && (b.EndTime == null || b.EndTime >= now))
                .ToListAsync();
        }

        public async Task<List<ServiceItem>> GetSuggestedServicesAsync(int categoryId, int excludeServiceId)
        {
            return await _context.ServiceItems.Include(s => s.Category)
                .Where(s => s.CategoryId == categoryId && s.ServiceId != excludeServiceId)
                .Take(5).ToListAsync();
        }

        public async Task<(bool Success, string Message)> OrderServiceAsync(int customerId, int roomId, int serviceId, int quantity, string notes)
        {
            var now = DateTime.Now;
            var activeBooking = await _context.Bookings.FirstOrDefaultAsync(b => b.CustomerId == customerId && b.RoomId == roomId && b.Status == "CheckedIn" && b.StartTime <= now && (b.EndTime == null || b.EndTime >= now));
            if (activeBooking == null) return (false, "Không tìm thấy phiên hát đang hoạt động của bạn tại phòng này.");

            var serviceItem = await _context.ServiceItems.FindAsync(serviceId);
            if (serviceItem == null) return (false, "Dịch vụ không tồn tại.");
            if (serviceItem.StockQuantity.HasValue && serviceItem.StockQuantity.Value < quantity) return (false, $"Rất tiếc, kho chỉ còn {serviceItem.StockQuantity.Value} phần.");

            var currentInvoice = await _context.Invoices.FirstOrDefaultAsync(i => i.BookingId == activeBooking.BookingId);
            if (currentInvoice == null)
            {
                currentInvoice = new Invoice
                {
                    BookingId = activeBooking.BookingId,
                    RoomId = activeBooking.RoomId,
                    ReceptionistId = 4,
                    CheckInTime = activeBooking.StartTime,
                    Status = "Unpaid",
                    RoomTotal = 0,
                    ServiceTotal = 0,
                    GrandTotal = 0,
                    DiscountAmount = 0
                };
                _context.Invoices.Add(currentInvoice);
                await _context.SaveChangesAsync();
            }

            var invoiceDetail = new InvoiceDetail
            {
                InvoiceId = currentInvoice.InvoiceId,
                ServiceId = serviceId,
                Quantity = quantity,
                UnitPrice = serviceItem.SellingPrice,
                IsService = true,
                IsFulFilled = false,
                Note = notes
            };
            _context.InvoiceDetails.Add(invoiceDetail);

            if (serviceItem.StockQuantity.HasValue) serviceItem.StockQuantity -= quantity;

            currentInvoice.ServiceTotal = (currentInvoice.ServiceTotal ?? 0) + (serviceItem.SellingPrice * quantity);
            currentInvoice.GrandTotal = (currentInvoice.RoomTotal ?? 0) + currentInvoice.ServiceTotal - (currentInvoice.DiscountAmount ?? 0);

            await _context.SaveChangesAsync();
            return (true, "Đặt món thành công.");
        }
    }
}
