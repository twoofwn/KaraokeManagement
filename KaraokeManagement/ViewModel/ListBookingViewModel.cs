namespace KaraokeManagement.ViewModel
{
    public class ListBookingViewModel
    {
        public List<BookingItemViewModel> Bookings { get; set; } = new List<BookingItemViewModel>();
        public string SearchString { get; set; } = string.Empty;
        public string CustomerFilter { get; set; } = string.Empty;
        public string DateRange { get; set; } = "all";
        public string SelectedStatus { get; set; } = "Pending";

        public int CurrentPage { get; set; } = 1;
        public int TotalPages { get; set; } = 1;
        public int TotalCount { get; set; }
        public int PageSize { get; set; } = 10;
    }

    public class UpdateBookingStatusRequest
    {
        public int BookingId { get; set; }
        public string Status { get; set; } = string.Empty; 
    }
}
