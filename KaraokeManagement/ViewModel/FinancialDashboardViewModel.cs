using System;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class FinancialDashboardViewModel
    {
        public int CustomersToday { get; set; }
        public decimal RevenueToday { get; set; }
        public int CustomersThisMonth { get; set; }
        public decimal RevenueThisMonth { get; set; }

        public decimal TotalRevenue { get; set; }
        public decimal TotalExpenses { get; set; }
        public decimal NetProfit { get; set; }
        public double ProfitMargin { get; set; }

        public decimal TotalRoomRevenue { get; set; }
        public decimal TotalServiceRevenue { get; set; }

        // Monthly trends for line chart
        public List<string> MonthlyLabels { get; set; } = new List<string>();
        public List<decimal> MonthlyRevenues { get; set; } = new List<decimal>();
        public List<decimal> MonthlyExpenses { get; set; } = new List<decimal>();

        // For revenue breakdown charts
        public List<string> RoomTypeLabels { get; set; } = new List<string>();
        public List<decimal> RoomTypeRevenues { get; set; } = new List<decimal>();

        public List<string> CategoryLabels { get; set; } = new List<string>();
        public List<decimal> CategoryRevenues { get; set; } = new List<decimal>();

        // For Profit Report monthly list
        public List<MonthlyProfitReportItem> ProfitItems { get; set; } = new List<MonthlyProfitReportItem>();
    }

    public class MonthlyProfitReportItem
    {
        public string MonthLabel { get; set; } = string.Empty;
        public decimal Revenue { get; set; }
        public decimal Expenses { get; set; }
        public decimal NetProfit { get; set; }
        public double Margin { get; set; }
    }
}
