using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.ManagerServices
{
    public class ExpenseService
    {
        private readonly KaraokeManagementDbContext _context;

        public ExpenseService(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public async Task<decimal> CalculatePayrollForMonthAsync(int year, int month)
        {
            var payrolls = await _context.Attendances
                .Where(a => a.CheckInTime.Year == year && a.CheckInTime.Month == month)
                .GroupBy(a => a.AccountId)
                .Select(g => new {
                    AccountId = g.Key,
                    TotalHours = g.Sum(a => a.TotalHours ?? 0m)
                })
                .ToListAsync();

            var profiles = await _context.EmployeeProfiles
                .Where(p => payrolls.Select(x => x.AccountId).Contains(p.AccountId))
                .ToDictionaryAsync(p => p.AccountId, p => p.BaseHourlyRate ?? 0m);

            decimal totalPayroll = 0;
            foreach (var item in payrolls)
            {
                if (profiles.TryGetValue(item.AccountId, out var rate))
                {
                    totalPayroll += item.TotalHours * rate;
                }
            }
            return totalPayroll;
        }

        public async Task<ExpensesViewModel> GetExpensesViewModelAsync()
        {
            var now = DateTime.Now;
            var startOfCurrentMonth = new DateTime(now.Year, now.Month, 1);
            var endOfCurrentMonth = startOfCurrentMonth.AddMonths(1).AddDays(-1);

            var startOfLastMonth = startOfCurrentMonth.AddMonths(-1);
            var endOfLastMonth = startOfCurrentMonth.AddDays(-1);

            var currentMonthExpenses = await _context.Expenses
                .Include(e => e.ExpenseCategory)
                .Where(e => e.ExpenseDate >= startOfCurrentMonth && e.ExpenseDate <= endOfCurrentMonth)
                .ToListAsync();

            var lastMonthExpenses = await _context.Expenses
                .Where(e => e.ExpenseDate >= startOfLastMonth && e.ExpenseDate <= endOfLastMonth)
                .ToListAsync();

            // Dynamic Payroll Integration
            var payrollCategory = new ExpenseCategory { CategoryId = -1, CategoryName = "Lương nhân viên" };

            decimal currentMonthPayroll = await CalculatePayrollForMonthAsync(now.Year, now.Month);
            decimal lastMonthPayroll = await CalculatePayrollForMonthAsync(startOfLastMonth.Year, startOfLastMonth.Month);

            if (currentMonthPayroll > 0)
            {
                currentMonthExpenses.Add(new Expense
                {
                    ExpenseId = -1,
                    CategoryId = -1,
                    ExpenseDate = startOfCurrentMonth,
                    Amount = currentMonthPayroll,
                    Note = $"Lương nhân viên tháng {now.Month:D2}/{now.Year} (Tự động tính toán)",
                    CreatedAt = startOfCurrentMonth,
                    ExpenseCategory = payrollCategory
                });
            }

            if (lastMonthPayroll > 0)
            {
                lastMonthExpenses.Add(new Expense
                {
                    ExpenseId = -2,
                    CategoryId = -1,
                    ExpenseDate = startOfLastMonth,
                    Amount = lastMonthPayroll,
                    Note = $"Lương nhân viên tháng {startOfLastMonth.Month:D2}/{startOfLastMonth.Year} (Tự động tính toán)",
                    CreatedAt = startOfLastMonth,
                    ExpenseCategory = payrollCategory
                });
            }

            decimal totalCurrentMonth = currentMonthExpenses.Sum(e => e.Amount);
            decimal totalLastMonth = lastMonthExpenses.Sum(e => e.Amount);

            decimal percentChange = 0;
            if (totalLastMonth > 0)
            {
                percentChange = ((totalCurrentMonth - totalLastMonth) / totalLastMonth) * 100;
            }

            var categoryGroup = currentMonthExpenses
                .GroupBy(e => e.ExpenseCategory.CategoryName)
                .Select(g => new { CategoryName = g.Key, Amount = g.Sum(e => e.Amount) })
                .OrderByDescending(g => g.Amount)
                .FirstOrDefault();

            string highestCatName = categoryGroup?.CategoryName ?? "Chưa có";
            decimal highestCatAmount = categoryGroup?.Amount ?? 0;
            decimal highestCatPercent = (totalCurrentMonth > 0 && categoryGroup != null)
                ? (highestCatAmount / totalCurrentMonth) * 100 : 0;

            var allExpenses = await _context.Expenses
                .Include(e => e.ExpenseCategory)
                .OrderByDescending(e => e.ExpenseDate)
                .ThenByDescending(e => e.CreatedAt)
                .ToListAsync();

            // Calculate payroll for historical months with attendance
            var attendanceMonths = await _context.Attendances
                .Select(a => new { a.CheckInTime.Year, a.CheckInTime.Month })
                .Distinct()
                .ToListAsync();

            var virtualExpenses = new List<Expense>();
            foreach (var m in attendanceMonths)
            {
                decimal payroll = await CalculatePayrollForMonthAsync(m.Year, m.Month);
                if (payroll > 0)
                {
                    var mStart = new DateTime(m.Year, m.Month, 1);
                    virtualExpenses.Add(new Expense
                    {
                        ExpenseId = -100 - (m.Year * 12 + m.Month),
                        CategoryId = -1,
                        ExpenseDate = mStart,
                        Amount = payroll,
                        Note = $"Lương nhân viên tháng {m.Month:D2}/{m.Year} (Tự động tính toán)",
                        CreatedAt = mStart,
                        ExpenseCategory = payrollCategory
                    });
                }
            }

            allExpenses.AddRange(virtualExpenses);
            allExpenses = allExpenses.OrderByDescending(e => e.ExpenseDate).ThenByDescending(e => e.CreatedAt).ToList();

            var categories = await _context.ExpenseCategories
                .OrderBy(c => c.CategoryName)
                .ToListAsync();

            categories.Add(payrollCategory);

            return new ExpensesViewModel
            {
                TotalMonthExpense = totalCurrentMonth,
                PercentChange = percentChange,
                HighestCategoryName = highestCatName,
                HighestCategoryAmount = highestCatAmount,
                HighestCategoryPercent = highestCatPercent,
                RecentExpenses = allExpenses,
                Categories = categories
            };
        }

        public async Task<(bool Success, string Message)> AddExpenseAsync(int categoryId, string dateStr, decimal amount, string? note)
        {
            if (categoryId <= 0 || amount <= 0)
                return (false, "Vui lòng nhập đầy đủ thông tin loại chi phí và số tiền lớn hơn 0.");

            DateTime expenseDate = DateTime.Now;
            if (!string.IsNullOrEmpty(dateStr))
            {
                if (DateTime.TryParse(dateStr + "-01", out var parsedMonthDate))
                    expenseDate = parsedMonthDate;
                else if (DateTime.TryParse(dateStr, out var parsedDate))
                    expenseDate = parsedDate;
            }

            var newExpense = new Expense
            {
                CategoryId = categoryId,
                ExpenseDate = expenseDate,
                Amount = amount,
                Note = note,
                CreatedAt = DateTime.Now
            };

            _context.Expenses.Add(newExpense);
            await _context.SaveChangesAsync();

            return (true, "Đã lưu chi phí thành công!");
        }

        public async Task<(bool Success, string Message, int CategoryId, string CategoryName)> CreateCategoryAsync(CreateCategoryModel payload)
        {
            if (payload == null || string.IsNullOrWhiteSpace(payload.CategoryName))
                return (false, "Tên danh mục không hợp lệ.", 0, string.Empty);

            var nameTrimmed = payload.CategoryName.Trim();
            var exists = await _context.ExpenseCategories.AnyAsync(c => c.CategoryName.ToLower() == nameTrimmed.ToLower());

            if (exists)
                return (false, "Danh mục này đã tồn tại.", 0, string.Empty);

            var newCategory = new ExpenseCategory { CategoryName = nameTrimmed };
            _context.ExpenseCategories.Add(newCategory);
            await _context.SaveChangesAsync();

            return (true, "Tạo danh mục thành công", newCategory.CategoryId, newCategory.CategoryName);
        }
    }
}
