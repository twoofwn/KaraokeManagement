namespace KaraokeManagement.ViewModel
{
    public class AssignedRoomViewModel
    {
        public int BookingId { get; set; }
        public int RoomId { get; set; }
        public string RoomName { get; set; } = null!;
        public string RoomTypeName { get; set; } = null!;
        public DateTime CheckInTime { get; set; }
        public int UnfulfilledCount { get; set; }
    }
}
