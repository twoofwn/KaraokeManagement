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

            var categories = await _context.ExpenseCategories
                .OrderBy(c => c.CategoryName)
                .ToListAsync();

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
