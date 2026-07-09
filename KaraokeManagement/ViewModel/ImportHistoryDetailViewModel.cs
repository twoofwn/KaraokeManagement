using KaraokeManagement.Models;

namespace KaraokeManagement.ViewModel
{
    public class ImportHistoryDetailViewModel
    {
        public PurchaseOrder PurchaseOrder { get; set; } = null!;
        public List<Supplier> Suppliers { get; set; } = new List<Supplier>();
    }
}
