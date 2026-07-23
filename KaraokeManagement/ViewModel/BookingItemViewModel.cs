namespace KaraokeManagement.ViewModel
{
    public class BookingItemViewModel
    {
        public int BookingId { get; set; }
        public string RoomName { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public string CustomerPhone { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public int? GuestCount { get; set; }
        public string? Note { get; set; }
        public string Status { get; set; } = "Pending";
    }
}
