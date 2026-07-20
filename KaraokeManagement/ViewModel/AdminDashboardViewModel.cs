using System;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class AdminDashboardViewModel
    {
        // Thống kê tháng hiện tại
        public int NewCustomersThisMonth { get; set; }
        public double PercentCustomerChange { get; set; }
        public double HoursThisMonth { get; set; }
        public double PercentHoursChange { get; set; }
        public decimal RevenueThisMonth { get; set; }
        public double PercentRevenueChange { get; set; }
        public int InvoicesThisMonth { get; set; }
        public double PercentInvoiceChange { get; set; }

        // Tổng quan hệ thống
        public int TotalItems { get; set; }
        public int TotalCategories { get; set; }
        public int TotalUsers { get; set; }
        public int TotalRooms { get; set; }
        public int TotalCustomers { get; set; }

        // Biểu đồ & bảng xếp hạng
        public List<DailyUsagePoint> DailyUsage { get; set; } = new();
        public List<RoomUsageStat> TopRooms { get; set; } = new();
        public List<ServiceSalesStat> TopServices { get; set; } = new();
    }

    public class DailyUsagePoint
    {
        public int Day { get; set; }
        public double Hours { get; set; }
    }

    public class RoomUsageStat
    {
        public string RoomName { get; set; } = "";
        public string TypeName { get; set; } = "";
        public int Sessions { get; set; }
        public double Hours { get; set; }
        public decimal Revenue { get; set; }
    }

    public class ServiceSalesStat
    {
        public string ServiceName { get; set; } = "";
        public string CategoryName { get; set; } = "";
        public int Quantity { get; set; }
        public decimal Amount { get; set; }
    }
}
