namespace KaraokeManagement.ViewModel
{
    public class AssignedDetailViewModel
    {
        public int BookingId { get; set; }
        public string RoomName { get; set; } = null!;
        public string RoomTypeName { get; set; } = null!;
        public DateTime CheckInTime { get; set; }
        public string? Note { get; set; }

        public List<ServiceItemDetail> Services { get; set; } = new();
    }

    public class ServiceItemDetail
    {
        public int InvoiceDetailId { get; set; }
        public string ServiceName { get; set; } = null!;
        public int Quantity { get; set; }
        public bool IsFulFilled { get; set; }
        public string? Note { get; set; }
    }
}
