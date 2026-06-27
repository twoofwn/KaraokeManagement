using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;

namespace KaraokeManagement.Controllers
{
    public class ManagerController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        public ManagerController(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            // Calculate Total Revenue from all Paid Invoices
            decimal totalRevenue = await _context.Invoices
                .Where(i => i.Status == "Paid")
                .SumAsync(i => i.GrandTotal ?? 0);

            // Calculate Total Expenses from Expense table + PurchaseOrder table
            decimal totalExpenses = await _context.Expenses
                .SumAsync(e => e.Amount);

            decimal totalPOAmount = await _context.PurchaseOrders
                .SumAsync(po => po.TotalAmount ?? 0);

            totalExpenses += totalPOAmount;

            decimal netProfit = totalRevenue - totalExpenses;
            double profitMargin = totalRevenue > 0 ? (double)(netProfit / totalRevenue) * 100 : 0;

            // Generate monthly trend for past 6 months
            var labels = new List<string>();
            var revenues = new List<decimal>();
            var expensesList = new List<decimal>();

            var now = DateTime.Now;
            for (int i = 5; i >= 0; i--)
            {
                var targetMonth = now.AddMonths(-i);
                var monthStart = new DateTime(targetMonth.Year, targetMonth.Month, 1);
                var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

                labels.Add($"Tháng {targetMonth.Month}/{targetMonth.Year.ToString().Substring(2)}");

                decimal rev = await _context.Invoices
                    .Where(i => i.Status == "Paid" && i.CheckOutTime >= monthStart && i.CheckOutTime <= monthEnd)
                    .SumAsync(i => i.GrandTotal ?? 0);
                revenues.Add(rev);

                decimal exp = await _context.Expenses
                    .Where(e => e.ExpenseDate >= monthStart && e.ExpenseDate <= monthEnd)
                    .SumAsync(e => e.Amount);

                decimal poAmt = await _context.PurchaseOrders
                    .Where(po => po.OrderDate >= monthStart && po.OrderDate <= monthEnd)
                    .SumAsync(po => po.TotalAmount ?? 0);

                expensesList.Add(exp + poAmt);
            }

            var viewModel = new FinancialDashboardViewModel
            {
                TotalRevenue = totalRevenue,
                TotalExpenses = totalExpenses,
                NetProfit = netProfit,
                ProfitMargin = profitMargin,
                MonthlyLabels = labels,
                MonthlyRevenues = revenues,
                MonthlyExpenses = expensesList
            };

            return View(viewModel);
        }


        public IActionResult StockIn()
        {
            return View();
        }

        public IActionResult Inventory()
        {
            return View();
        }

        public IActionResult ImportHistory()
        {
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> Expenses()
        {
            var now = DateTime.Now;
            var startOfCurrentMonth = new DateTime(now.Year, now.Month, 1);
            var endOfCurrentMonth = startOfCurrentMonth.AddMonths(1).AddDays(-1);

            var startOfLastMonth = startOfCurrentMonth.AddMonths(-1);
            var endOfLastMonth = startOfCurrentMonth.AddDays(-1);

            var currentMonthExpenses = await _context.Expenses
                .Where(e => e.ExpenseDate >= startOfCurrentMonth && e.ExpenseDate <= endOfCurrentMonth)
                .ToListAsync();

            var lastMonthExpenses = await _context.Expenses
                .Where(e => e.ExpenseDate >= startOfLastMonth && e.ExpenseDate <= endOfLastMonth)
                .ToListAsync();

            decimal totalCurrentMonth = currentMonthExpenses.Sum(e => e.Amount);
            decimal totalLastMonth = lastMonthExpenses.Sum(e => e.Amount);

            decimal percentChange = 0;
            if (totalLastMonth > 0)
            {
                percentChange = ((totalCurrentMonth - totalLastMonth) / totalLastMonth) * 100;
            }

            // Find highest category in current month
            var categoryGroup = currentMonthExpenses
                .GroupBy(e => e.Category)
                .Select(g => new { Category = g.Key, Amount = g.Sum(e => e.Amount) })
                .OrderByDescending(g => g.Amount)
                .FirstOrDefault();

            string highestCatName = "Chưa có";
            decimal highestCatAmount = 0;
            decimal highestCatPercent = 0;

            if (categoryGroup != null)
            {
                highestCatName = ExpensesViewModel.GetCategoryDisplayName(categoryGroup.Category);
                highestCatAmount = categoryGroup.Amount;
                if (totalCurrentMonth > 0)
                {
                    highestCatPercent = (highestCatAmount / totalCurrentMonth) * 100;
                }
            }

            var allExpenses = await _context.Expenses
                .OrderByDescending(e => e.ExpenseDate)
                .ThenByDescending(e => e.CreatedAt)
                .ToListAsync();

            var viewModel = new ExpensesViewModel
            {
                TotalMonthExpense = totalCurrentMonth,
                PercentChange = percentChange,
                HighestCategoryName = highestCatName,
                HighestCategoryAmount = highestCatAmount,
                HighestCategoryPercent = highestCatPercent,
                RecentExpenses = allExpenses
            };

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddExpense(string category, string dateStr, decimal amount, string? note)
        {
            if (string.IsNullOrEmpty(category) || amount <= 0)
            {
                return Json(new { success = false, message = "Vui lòng nhập đầy đủ thông tin loại chi phí và số tiền lớn hơn 0." });
            }

            DateTime expenseDate = DateTime.Now;
            if (!string.IsNullOrEmpty(dateStr))
            {
                // UI inputs type="month" which gives "yyyy-MM", we can append "-01" to parse it as date
                if (DateTime.TryParse(dateStr + "-01", out var parsedDate))
                {
                    expenseDate = parsedDate;
                }
                else if (DateTime.TryParse(dateStr, out parsedDate))
                {
                    expenseDate = parsedDate;
                }
            }

            var newExpense = new Expense
            {
                Category = category,
                ExpenseDate = expenseDate,
                Amount = amount,
                Note = note,
                CreatedAt = DateTime.Now
            };

            _context.Expenses.Add(newExpense);
            await _context.SaveChangesAsync();

            return Json(new { success = true, message = "Đã lưu chi phí thành công!" });
        }

        [HttpGet]
        public async Task<IActionResult> Invoices(DateTime? fromDate, DateTime? toDate, int page = 1)
        {
            var now = DateTime.Now;
            var end = toDate ?? new DateTime(now.Year, now.Month, now.Day, 23, 59, 59);
            var start = fromDate ?? new DateTime(now.Year, now.Month, 1).AddMonths(-1); // Default to show more data initially

            var searchStart = start.Date;
            var searchEnd = end.Date.AddDays(1).AddTicks(-1);

            var query = _context.Invoices
                .Include(i => i.Room)
                .Where(i => i.Status == "Paid" && i.CheckOutTime >= searchStart && i.CheckOutTime <= searchEnd);

            int totalCount = await query.CountAsync();
            int pageSize = 10;
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages == 0) totalPages = 1;

            if (page < 1) page = 1;
            if (page > totalPages) page = totalPages;

            var invoices = await query
                .OrderByDescending(i => i.CheckOutTime)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            int startEntry = totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
            int endEntry = Math.Min(page * pageSize, totalCount);

            var viewModel = new ManagerInvoicesViewModel
            {
                Invoices = invoices,
                FromDate = start,
                ToDate = end,
                CurrentPage = page,
                TotalPages = totalPages,
                TotalCount = totalCount,
                StartEntry = startEntry,
                EndEntry = endEntry
            };

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> InvoiceDetails(int id)
        {
            var invoice = await _context.Invoices
                .Include(i => i.Room)
                .ThenInclude(r => r.RoomType)
                .Include(i => i.Receptionist)
                .Include(i => i.Booking)
                .ThenInclude(b => b.Customer)
                .ThenInclude(c => c.Tier)
                .Include(i => i.InvoiceDetails)
                .ThenInclude(d => d.Service)
                .Include(i => i.PaymentTransactions)
                .ThenInclude(t => t.Method)
                .FirstOrDefaultAsync(i => i.InvoiceId == id);

            if (invoice == null)
            {
                return Json(new { success = false, message = "Không tìm thấy hóa đơn." });
            }

            var duration = (invoice.CheckOutTime ?? DateTime.Now) - invoice.CheckInTime;
            string durationText = $"{(int)duration.TotalHours} giờ {duration.Minutes} phút";

            var details = new
            {
                invoiceId = invoice.InvoiceId,
                roomName = invoice.Room.RoomName,
                roomTypeName = invoice.Room.RoomType.TypeName,
                pricePerHour = invoice.Room.RoomType.PricePerHour,
                checkInTime = invoice.CheckInTime.ToString("dd/MM/yyyy HH:mm"),
                checkOutTime = invoice.CheckOutTime?.ToString("dd/MM/yyyy HH:mm") ?? "Chưa checkout",
                durationText = durationText,
                customerName = invoice.Booking?.Customer?.FullName ?? "Khách vãng lai",
                customerPhone = invoice.Booking?.Customer?.Phone ?? "N/A",
                customerTier = invoice.Booking?.Customer?.Tier?.TierName ?? "Thường",
                discountPercent = invoice.Booking?.Customer?.Tier?.DiscountPercent ?? 0,
                receptionistName = invoice.Receptionist?.FullName ?? "N/A",
                roomTotal = invoice.RoomTotal ?? 0,
                serviceTotal = invoice.ServiceTotal ?? 0,
                discountAmount = invoice.DiscountAmount ?? 0,
                grandTotal = invoice.GrandTotal ?? 0,
                status = invoice.Status,
                items = invoice.InvoiceDetails.Select(d => new
                {
                    serviceName = d.Service.ServiceName,
                    quantity = d.Quantity,
                    unitPrice = d.UnitPrice,
                    total = d.Quantity * d.UnitPrice,
                    unit = d.Service.Unit
                }).ToList(),
                payments = invoice.PaymentTransactions.Select(t => new
                {
                    methodName = t.Method.MethodName,
                    amount = t.Amount,
                    date = t.TransactionDate?.ToString("dd/MM/yyyy HH:mm") ?? "",
                    refCode = t.ReferenceCode ?? ""
                }).ToList()
            };

            return Json(new { success = true, data = details });
        }

        [HttpGet]
        public async Task<IActionResult> RevenueReport()
        {
            // Total Room vs Service Revenue
            decimal totalRoom = await _context.Invoices
                .Where(i => i.Status == "Paid")
                .SumAsync(i => i.RoomTotal ?? 0);

            decimal totalService = await _context.Invoices
                .Where(i => i.Status == "Paid")
                .SumAsync(i => i.ServiceTotal ?? 0);

            decimal totalRevenue = totalRoom + totalService;

            // Group by Room Type
            var roomTypeRevenue = await _context.Invoices
                .Where(i => i.Status == "Paid")
                .Include(i => i.Room).ThenInclude(r => r.RoomType)
                .GroupBy(i => i.Room.RoomType.TypeName)
                .Select(g => new { TypeName = g.Key, Amount = g.Sum(i => i.RoomTotal ?? 0) })
                .ToListAsync();

            // Group by Service Category
            var categoryRevenue = await _context.InvoiceDetails
                .Include(id => id.Invoice)
                .Include(id => id.Service).ThenInclude(s => s.Category)
                .Where(id => id.Invoice.Status == "Paid")
                .GroupBy(id => id.Service.Category.CategoryName)
                .Select(g => new { CategoryName = g.Key, Amount = g.Sum(id => id.Quantity * id.UnitPrice) })
                .ToListAsync();

            var viewModel = new FinancialDashboardViewModel
            {
                TotalRevenue = totalRevenue,
                TotalRoomRevenue = totalRoom,
                TotalServiceRevenue = totalService,
                RoomTypeLabels = roomTypeRevenue.Select(r => r.TypeName).ToList(),
                RoomTypeRevenues = roomTypeRevenue.Select(r => r.Amount).ToList(),
                CategoryLabels = categoryRevenue.Select(c => c.CategoryName).ToList(),
                CategoryRevenues = categoryRevenue.Select(c => c.Amount).ToList()
            };

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> ProfitReport()
        {
            var now = DateTime.Now;
            var profitItems = new List<MonthlyProfitReportItem>();

            // Generate monthly profit list for the past 12 months
            for (int i = 11; i >= 0; i--)
            {
                var targetMonth = now.AddMonths(-i);
                var monthStart = new DateTime(targetMonth.Year, targetMonth.Month, 1);
                var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

                decimal revenue = await _context.Invoices
                    .Where(i => i.Status == "Paid" && i.CheckOutTime >= monthStart && i.CheckOutTime <= monthEnd)
                    .SumAsync(i => i.GrandTotal ?? 0);

                decimal expenses = await _context.Expenses
                    .Where(e => e.ExpenseDate >= monthStart && e.ExpenseDate <= monthEnd)
                    .SumAsync(e => e.Amount);

                decimal poAmt = await _context.PurchaseOrders
                    .Where(po => po.OrderDate >= monthStart && po.OrderDate <= monthEnd)
                    .SumAsync(po => po.TotalAmount ?? 0);

                decimal totalExpenses = expenses + poAmt;
                decimal netProfit = revenue - totalExpenses;
                double margin = revenue > 0 ? (double)(netProfit / revenue) * 100 : 0;

                profitItems.Add(new MonthlyProfitReportItem
                {
                    MonthLabel = $"Tháng {targetMonth.Month}/{targetMonth.Year}",
                    Revenue = revenue,
                    Expenses = totalExpenses,
                    NetProfit = netProfit,
                    Margin = margin
                });
            }

            // Overall summary stats
            decimal totalRevenue = profitItems.Sum(x => x.Revenue);
            decimal totalExpensesAll = profitItems.Sum(x => x.Expenses);
            decimal netProfitAll = totalRevenue - totalExpensesAll;
            double profitMarginAll = totalRevenue > 0 ? (double)(netProfitAll / totalRevenue) * 100 : 0;

            var viewModel = new FinancialDashboardViewModel
            {
                TotalRevenue = totalRevenue,
                TotalExpenses = totalExpensesAll,
                NetProfit = netProfitAll,
                ProfitMargin = profitMarginAll,
                ProfitItems = profitItems
            };

            return View(viewModel);
        }
    }
}
