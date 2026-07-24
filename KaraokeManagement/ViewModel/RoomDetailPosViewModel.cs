using System;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class RoomDetailPosViewModel
    {
        public int RoomId { get; set; }
        public string RoomName { get; set; } = string.Empty;
        public string RoomTypeName { get; set; } = string.Empty;
        public decimal PricePerHour { get; set; }
        public string RoomStatus { get; set; } = string.Empty;

        public int? InvoiceId { get; set; }
        public DateTime? CheckInTime { get; set; }

        public List<PosOrderItem> OrderItems { get; set; } = new List<PosOrderItem>();
        public List<PosProductItem> ProductItems { get; set; } = new List<PosProductItem>();
        public List<CategoryViewModel> Categories { get; set; } = new List<CategoryViewModel>();
        public List<PosRoomItem> AvailableRooms { get; set; } = new List<PosRoomItem>();
        public string? StaffName { get; set; }
    }

    public class PosRoomItem
    {
        public int RoomId { get; set; }
        public string RoomName { get; set; } = string.Empty;
        public string RoomTypeName { get; set; } = string.Empty;
        public decimal PricePerHour { get; set; }
    }

    public class PosOrderItem
    {
        public int InvoiceDetailId { get; set; }
        public int ServiceId { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public string? Unit { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal TotalPrice => Quantity * UnitPrice;
    }

    public class PosProductItem
    {
        public int ServiceId { get; set; }
        public int CategoryId { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public decimal SellingPrice { get; set; }
        public string? Unit { get; set; }
        public int StockQuantity { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string imageURL { get; set; }

    }

    public class CategoryViewModel
    {
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
    }
}
