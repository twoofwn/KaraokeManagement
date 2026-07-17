using System.Collections.Generic;
using KaraokeManagement.Models;

namespace KaraokeManagement.ViewModel
{
    public class InventoryViewModel
    {
        public List<InventoryItemViewModel> Items { get; set; } = new List<InventoryItemViewModel>();
        public decimal TotalValue { get; set; }
        public int LowStockCount { get; set; }
        public int ActiveCategoriesCount { get; set; }
        public List<Category> Categories { get; set; } = new List<Category>();
    }

    public class InventoryItemViewModel
    {
        public int ServiceId { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public string CategoryName { get; set; } = string.Empty;
        public decimal SellingPrice { get; set; }
        public string? Unit { get; set; }
        public int StockQuantity { get; set; }
        public decimal ImportPrice { get; set; }
        public string Status { get; set; } = "In Stock";
    }
}
