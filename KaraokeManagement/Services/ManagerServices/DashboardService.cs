using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.ManagerServices
{
    public class DashboardService
    {
        private readonly KaraokeManagementDbContext _context;
        public DashboardService(KaraokeManagementDbContext context) { _context = context; }

        public async Task<FinancialDashboardViewModel> GetDashboardDataAsync()
        {
            var now = DateTime.Now;
            var todayStart = now.Date;
            var todayEnd = todayStart.AddDays(1).AddTicks(-1);
            var monthStart = new DateTime(now.Year, now.Month, 1);
            var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

            int customersToday = await _context.Invoices.Where(i => i.CheckInTime >= todayStart && i.CheckInTime <= todayEnd && i.BookingId != null).Select(i => i.Booking!.CustomerId).Distinct().CountAsync();
            decimal revenueToday = await _context.Invoices.Where(i => i.Status == "Paid" && i.CheckOutTime >= todayStart && i.CheckOutTime <= todayEnd).SumAsync(i => i.GrandTotal ?? 0);
            int customersThisMonth = await _context.Invoices.Where(i => i.CheckInTime >= monthStart && i.CheckInTime <= monthEnd && i.BookingId != null).Select(i => i.Booking!.CustomerId).Distinct().CountAsync();
            decimal revenueThisMonth = await _context.Invoices.Where(i => i.Status == "Paid" && i.CheckOutTime >= monthStart && i.CheckOutTime <= monthEnd).SumAsync(i => i.GrandTotal ?? 0);

            decimal totalRevenue = await _context.Invoices.Where(i => i.Status == "Paid").SumAsync(i => i.GrandTotal ?? 0);
            decimal totalExpenses = await _context.Expenses.SumAsync(e => e.Amount) + await _context.PurchaseOrders.SumAsync(po => po.TotalAmount ?? 0);

            var profitItems = await BuildMonthlyProfitItemsAsync(now, 12);

            return new FinancialDashboardViewModel
            {
                CustomersToday = customersToday,
                RevenueToday = revenueToday,
                CustomersThisMonth = customersThisMonth,
                RevenueThisMonth = revenueThisMonth,
                TotalRevenue = totalRevenue,
                TotalExpenses = totalExpenses,
                NetProfit = totalRevenue - totalExpenses,
                ProfitMargin = totalRevenue > 0 ? (double)((totalRevenue - totalExpenses) / totalRevenue) * 100 : 0,
                MonthlyLabels = profitItems.Take(6).Select(p => p.MonthLabel).Reverse().ToList(),
                MonthlyRevenues = profitItems.Take(6).Select(p => p.Revenue).Reverse().ToList(),
                MonthlyExpenses = profitItems.Take(6).Select(p => p.Expenses).Reverse().ToList(),
                ProfitItems = profitItems
            };
        }

        public async Task<FinancialDashboardViewModel> GetRevenueReportAsync()
        {
            decimal totalRoom = await _context.Invoices.Where(i => i.Status == "Paid").SumAsync(i => i.RoomTotal ?? 0);
            decimal totalService = await _context.Invoices.Where(i => i.Status == "Paid").SumAsync(i => i.ServiceTotal ?? 0);

            var roomTypeRevenue = await _context.Invoices.Where(i => i.Status == "Paid")
                .Include(i => i.Room).ThenInclude(r => r.RoomType)
                .GroupBy(i => i.Room.RoomType.TypeName)
                .Select(g => new { TypeName = g.Key, Amount = g.Sum(i => i.RoomTotal ?? 0) }).ToListAsync();

            var categoryRevenue = await _context.InvoiceDetails.Include(id => id.Invoice).Include(id => id.Service).ThenInclude(s => s.Category)
                .Where(id => id.Invoice.Status == "Paid").GroupBy(id => id.Service.Category.CategoryName)
                .Select(g => new { CategoryName = g.Key, Amount = g.Sum(id => id.Quantity * id.UnitPrice) }).ToListAsync();

            return new FinancialDashboardViewModel
            {
                TotalRevenue = totalRoom + totalService,
                TotalRoomRevenue = totalRoom,
                TotalServiceRevenue = totalService,
                RoomTypeLabels = roomTypeRevenue.Select(r => r.TypeName).ToList(),
                RoomTypeRevenues = roomTypeRevenue.Select(r => r.Amount).ToList(),
                CategoryLabels = categoryRevenue.Select(c => c.CategoryName).ToList(),
                CategoryRevenues = categoryRevenue.Select(c => c.Amount).ToList()
            };
        }

        public async Task<FinancialDashboardViewModel> GetProfitReportAsync()
        {
            var profitItems = await BuildMonthlyProfitItemsAsync(DateTime.Now, 12);
            decimal totalRev = profitItems.Sum(x => x.Revenue);
            decimal totalExp = profitItems.Sum(x => x.Expenses);

            return new FinancialDashboardViewModel
            {
                TotalRevenue = totalRev,
                TotalExpenses = totalExp,
                NetProfit = totalRev - totalExp,
                ProfitMargin = totalRev > 0 ? (double)((totalRev - totalExp) / totalRev) * 100 : 0,
                ProfitItems = profitItems
            };
        }

        private async Task<List<MonthlyProfitReportItem>> BuildMonthlyProfitItemsAsync(DateTime now, int monthsCount)
        {
            var profitItems = new List<MonthlyProfitReportItem>();
            for (int i = 0; i < monthsCount; i++)
            {
                var targetMonth = now.AddMonths(-i);
                var monthStart = new DateTime(targetMonth.Year, targetMonth.Month, 1);
                var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

                decimal rev = await _context.Invoices.Where(x => x.Status == "Paid" && x.CheckOutTime >= monthStart && x.CheckOutTime <= monthEnd).SumAsync(x => x.GrandTotal ?? 0);
                decimal exp = await _context.Expenses.Where(e => e.ExpenseDate >= monthStart && e.ExpenseDate <= monthEnd).SumAsync(e => e.Amount);
                decimal poAmt = await _context.PurchaseOrders.Where(po => po.OrderDate >= monthStart && po.OrderDate <= monthEnd).SumAsync(po => po.TotalAmount ?? 0);
                decimal totalExp = exp + poAmt;

                profitItems.Add(new MonthlyProfitReportItem
                {
                    MonthLabel = $"Tháng {targetMonth.Month}/{targetMonth.Year}",
                    Revenue = rev,
                    Expenses = totalExp,
                    NetProfit = rev - totalExp,
                    Margin = rev > 0 ? (double)((rev - totalExp) / rev) * 100 : 0
                });
            }
            return profitItems;
        }
    }
}
