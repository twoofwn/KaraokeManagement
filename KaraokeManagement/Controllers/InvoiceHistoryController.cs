using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;

namespace KaraokeManagement.Controllers
{
    public class InvoiceHistoryController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        public InvoiceHistoryController(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> Index(
            string searchString, 
            string customerFilter, 
            DateTime? fromDate, 
            DateTime? toDate, 
            string status = "All", 
            int page = 1)
        {
            var query = _context.Invoices
                .Include(i => i.Room)
                .Include(i => i.Booking)
                    .ThenInclude(b => b.Customer)
                .Include(i => i.Receptionist)
                .AsQueryable();

            // Search
            if (!string.IsNullOrEmpty(searchString))
            {
                var term = searchString.Trim().ToLower();
                int searchId = 0;
                string cleanTerm = term.Replace("#", "").Replace("lum-", "", StringComparison.OrdinalIgnoreCase);
                bool isNumeric = int.TryParse(cleanTerm, out searchId);

                query = query.Where(i => 
                    (isNumeric && i.InvoiceId == searchId) ||
                    (i.Booking != null && i.Booking.Customer != null && i.Booking.Customer.FullName.ToLower().Contains(term)) ||
                    (i.Receptionist != null && i.Receptionist.FullName.ToLower().Contains(term))
                );
            }

            // Search by Customer Name or Customer Phone
            if (!string.IsNullOrEmpty(customerFilter))
            {
                var term = customerFilter.Trim().ToLower();
                query = query.Where(i => 
                    (i.Booking != null && i.Booking.Customer != null && 
                        (i.Booking.Customer.FullName.ToLower().Contains(term) || 
                         i.Booking.Customer.Phone.Contains(term)))
                );
            }

            // FromDate
            if (fromDate.HasValue)
            {
                query = query.Where(i => i.CheckInTime >= fromDate.Value);
            }

            // ToDate
            if (toDate.HasValue)
            {
                var endOfDay = toDate.Value.Date.AddDays(1).AddTicks(-1);
                query = query.Where(i => i.CheckInTime <= endOfDay);
            }

            // Payment status
            if (!string.IsNullOrEmpty(status) && status != "All" && status != "Tất cả")
            {
                query = query.Where(i => i.Status == status);
            }

            int totalCount = await query.CountAsync();
            int pageSize = 10;
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages < 1) totalPages = 1;
            if (page < 1) page = 1;
            if (page > totalPages) page = totalPages;

            var invoices = await query
                .OrderByDescending(i => i.CheckInTime)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
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
                })
                .ToListAsync();

            var viewModel = new InvoiceHistoryViewModel
            {
                Invoices = invoices,
                SearchString = searchString ?? string.Empty,
                CustomerFilter = customerFilter ?? string.Empty,
                FromDate = fromDate,
                ToDate = toDate,
                SelectedStatus = status,
                CurrentPage = page,
                TotalPages = totalPages,
                TotalCount = totalCount,
                PageSize = pageSize
            };

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> GetInvoiceDetail(int invoiceId)
        {
            var invoice = await _context.Invoices
                .Include(i => i.Room)
                    .ThenInclude(r => r.RoomType)
                .Include(i => i.InvoiceDetails)
                    .ThenInclude(id => id.Service)
                .Include(i => i.Booking)
                    .ThenInclude(b => b.Customer)
                        .ThenInclude(c => c.Tier)
                .FirstOrDefaultAsync(i => i.InvoiceId == invoiceId);

            if (invoice == null)
            {
                return NotFound("Không tìm thấy thông tin hóa đơn.");
            }

            var checkInTime = invoice.CheckInTime;
            var checkOutTime = invoice.CheckOutTime ?? DateTime.Now;
            var duration = checkOutTime - checkInTime;
            if (duration.TotalSeconds < 0) duration = TimeSpan.Zero;

            double durationHours = duration.TotalHours;
            string durationText = $"{(int)duration.TotalHours}h {duration.Minutes}m";

            decimal pricePerHour = invoice.Room.RoomType.PricePerHour;
            decimal roomTotal = invoice.RoomTotal ?? (decimal)durationHours * pricePerHour;
            decimal serviceTotal = invoice.ServiceTotal ?? invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);

            decimal discountPercent = invoice.Booking?.Customer?.Tier?.DiscountPercent ?? 0;
            decimal discountAmount = invoice.DiscountAmount ?? (roomTotal + serviceTotal) * discountPercent / 100;
            decimal grandTotal = invoice.GrandTotal ?? (roomTotal + serviceTotal - discountAmount);

            var orderItems = invoice.InvoiceDetails.Select(id => new CheckoutItemViewModel
            {
                ServiceName = id.Service.ServiceName,
                Quantity = id.Quantity,
                UnitPrice = id.UnitPrice,
                TotalPrice = id.Quantity * id.UnitPrice,
                Unit = id.Service.Unit
            }).ToList();

            var viewModel = new CheckoutViewModel
            {
                InvoiceId = invoice.InvoiceId,
                RoomId = invoice.RoomId,
                RoomName = invoice.Room.RoomName,
                RoomTypeName = invoice.Room.RoomType.TypeName,
                PricePerHour = pricePerHour,
                CheckInTime = checkInTime,
                CheckOutTime = checkOutTime,
                DurationHours = durationHours,
                DurationText = durationText,
                RoomTotal = roomTotal,
                ServiceTotal = serviceTotal,
                DiscountPercent = discountPercent,
                DiscountAmount = discountAmount,
                GrandTotal = grandTotal,
                CustomerName = invoice.Booking?.Customer?.FullName ?? "Khách vãng lai",
                CustomerPhone = invoice.Booking?.Customer?.Phone ?? "",
                CustomerTier = invoice.Booking?.Customer?.Tier?.TierName ?? "THƯỜNG",
                OrderItems = orderItems
            };

            return PartialView("_InvoiceDetailModal", viewModel);
        }
    }
}
