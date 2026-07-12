using System;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class CheckInViewModel
    {
        // For rendering form context
        public string CurrentEmployeeName { get; set; } = string.Empty;
        public List<AvailableRoomItem> AvailableRooms { get; set; } = new List<AvailableRoomItem>();

        // For form submit binding
        public int? CustomerId { get; set; }
        public int RoomId { get; set; }
        public int GuestCount { get; set; } = 4;
        public DateTime CheckInTime { get; set; } = DateTime.Now;
        public DateTime? CheckOutTimeEstimated { get; set; }
        public string? Notes { get; set; }
    }

    public class AvailableRoomItem
    {
        public int RoomId { get; set; }
        public string RoomName { get; set; } = string.Empty;
        public string TypeName { get; set; } = string.Empty;
        public decimal PricePerHour { get; set; }
    }
}
