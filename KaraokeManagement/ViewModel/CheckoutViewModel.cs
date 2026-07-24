using System;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class CheckoutViewModel
    {
        public int InvoiceId { get; set; }
        public int RoomId { get; set; }
        public string RoomName { get; set; } = string.Empty;
        public string RoomTypeName { get; set; } = string.Empty;
        public decimal PricePerHour { get; set; }


        public DateTime CheckInTime { get; set; }
        public DateTime CheckOutTime { get; set; }
        public double DurationHours { get; set; }
        public string DurationText { get; set; } = string.Empty;

        public decimal RoomTotal { get; set; }
        public decimal ServiceTotal { get; set; }
        public decimal DiscountPercent { get; set; }
        public decimal DiscountAmount { get; set; }
        public decimal GrandTotal { get; set; }

        public string CustomerName { get; set; } = string.Empty;
        public string CustomerPhone { get; set; } = string.Empty;
        public string CustomerTier { get; set; } = string.Empty;

        public string StaffName { get; set; } = "Chýa phân công";

        public List<CheckoutItemViewModel> OrderItems { get; set; } = new List<CheckoutItemViewModel>();
    }

    public class CheckoutItemViewModel
    {
        public string ServiceName { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal TotalPrice { get; set; }
        public string? Unit { get; set; }
    }
}
