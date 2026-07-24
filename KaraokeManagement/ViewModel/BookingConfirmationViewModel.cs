namespace KaraokeManagement.ViewModel
{

    public class BookingConfirmationViewModel
    {
        public string CustomerName { get; set; } = null!;
        public string Phone { get; set; } = null!;
        public string? Email { get; set; }
        public string RoomName { get; set; } = null!;
        public string TypeName { get; set; } = null!;
        public string BookingDate { get; set; } = null!;
        public string StartTime { get; set; } = null!;
        public int Duration { get; set; }
        public decimal BasePrice { get; set; }
        public decimal SurchargeAmount { get; set; }
        public string? SurchargeNote { get; set; }
        public decimal EstimatedTotalPrice { get; set; }
        public List<PriceBreakdownItem> PriceBreakdowns { get; set; } = new List<PriceBreakdownItem>();
    }

    public class PriceBreakdownItem
    {
        public string TimeRange { get; set; } = string.Empty;
        public decimal DurationHours { get; set; }
        public decimal PricePerHour { get; set; }
        public decimal TotalPrice { get; set; }
    }
}
