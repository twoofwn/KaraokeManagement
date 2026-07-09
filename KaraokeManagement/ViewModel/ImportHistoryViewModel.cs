using KaraokeManagement.Models;

namespace KaraokeManagement.ViewModel
{
    public class ImportHistoryViewModel
    {
        public decimal TotalSpentThisMonth { get; set; }
        public double PercentChange { get; set; }
        public int TotalOrders { get; set; }
        public List<Supplier> Suppliers { get; set; } = new List<Supplier>();
        public List<PurchaseOrder> PurchaseOrders { get; set; } = new List<PurchaseOrder>();
        public int CurrentPage { get; set; }
        public int TotalPages { get; set; }
        public int TotalCount { get; set; }
        public int? SelectedSupplierId { get; set; }
        public string? TimeFilter { get; set; }
    }
}
