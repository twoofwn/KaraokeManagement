using System;
using System.Collections.Generic;
using KaraokeManagement.Models;

namespace KaraokeManagement.ViewModel;

public class ExpensesViewModel
{
    public decimal TotalMonthExpense { get; set; }
    public decimal PercentChange { get; set; }
    public string HighestCategoryName { get; set; } = "Chưa có";
    public decimal HighestCategoryAmount { get; set; }
    public decimal HighestCategoryPercent { get; set; }
    public List<Expense> RecentExpenses { get; set; } = new List<Expense>();

    public static string GetCategoryDisplayName(string category)
    {
        return category?.ToLower() switch
        {
            "dien" => "Điện",
            "nuoc" => "Nước",
            "matbang" => "Mặt bằng",
            "baotri" => "Bảo trì",
            "khac" => "Khác",
            _ => "Khác"
        };
    }

    public static string GetCategoryIconClass(string category)
    {
        return category?.ToLower() switch
        {
            "dien" => "fa-solid fa-bolt",
            "nuoc" => "fa-solid fa-droplet",
            "matbang" => "fa-solid fa-shop",
            "baotri" => "fa-solid fa-screwdriver-wrench",
            _ => "fa-solid fa-credit-card"
        };
    }

    public static string GetCategoryBadgeClass(string category)
    {
        return category?.ToLower() switch
        {
            "dien" => "cat-electricity",
            "nuoc" => "cat-water",
            "matbang" => "cat-rent",
            "baotri" => "cat-maintenance",
            _ => "cat-rent"
        };
    }
}
