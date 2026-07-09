namespace KaraokeManagement.ViewModel
{
    public class StockInRequestModel
    {
        public int SupplierId { get; set; }
        public DateTime OrderDate { get; set; }
        public string? Note { get; set; }
        public List<StockInItemModel> Items { get; set; } = new List<StockInItemModel>();
    }
}
