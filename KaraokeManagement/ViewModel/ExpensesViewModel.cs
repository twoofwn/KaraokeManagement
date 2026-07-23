using KaraokeManagement.Models;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel;

public class ExpensesViewModel
{
    public decimal TotalMonthExpense { get; set; }
    public decimal PercentChange { get; set; }
    public string HighestCategoryName { get; set; } = "Chưa có";
    public decimal HighestCategoryAmount { get; set; }
    public decimal HighestCategoryPercent { get; set; }
    public List<Expense> RecentExpenses { get; set; } = new List<Expense>();
    public List<ExpenseCategory> Categories { get; set; } = new List<ExpenseCategory>();

    public static string GetCategoryDisplayName(string categoryName)
    {
        return categoryName;
    }

    public static string GetCategoryIconClass(string categoryName)
    {
        return categoryName?.ToLower() switch
        {
            var s when s.Contains("điện") || s.Contains("dien") => "fa-solid fa-bolt",
            var s when s.Contains("nước") || s.Contains("nuoc") => "fa-solid fa-droplet",
            var s when s.Contains("mặt bằng") || s.Contains("matbang") || s.Contains("thuê") => "fa-solid fa-shop",
            var s when s.Contains("bảo trì") || s.Contains("baotri") => "fa-solid fa-screwdriver-wrench",
            var s when s.Contains("lương") || s.Contains("luong") => "fa-solid fa-user-tie",
            _ => "fa-solid fa-credit-card"
        };
    }

    public static string GetCategoryBadgeClass(string categoryName)
    {
        return categoryName?.ToLower() switch
        {
            var s when s.Contains("điện") || s.Contains("dien") => "cat-electricity",
            var s when s.Contains("nước") || s.Contains("nuoc") => "cat-water",
            var s when s.Contains("mặt bằng") || s.Contains("matbang") || s.Contains("thuê") => "cat-rent",
            var s when s.Contains("bảo trì") || s.Contains("baotri") => "cat-maintenance",
            var s when s.Contains("lương") || s.Contains("luong") => "cat-salary",
            _ => "cat-rent"
        };
    }
}
