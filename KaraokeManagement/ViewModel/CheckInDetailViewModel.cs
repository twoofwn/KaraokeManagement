using System;
using System.Collections.Generic;
using KaraokeManagement.Models;

namespace KaraokeManagement.ViewModel
{
    public class CheckInDetailViewModel
    {
        public int BookingId { get; set; }
        public int CustomerId { get; set; }
        public string CustomerName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;


        public int CurrentRoomId { get; set; }
        public string CurrentRoomName { get; set; } = string.Empty;
        public string CurrentRoomTypeName { get; set; } = string.Empty;
        public decimal CurrentPricePerHour { get; set; }
        public string? CurrentRoomTypeImageUrl { get; set; }


        public DateTime StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public int? GuestCount { get; set; }
        public string? Note { get; set; }
        public string Status { get; set; } = string.Empty;

        // Danh sách phòng khả dụng để Đổi phòng (không trùng thời gian)
        public List<AvailableRoomItem> AvailableRoomsToSwitch { get; set; } = new List<AvailableRoomItem>();

        // Id phòng chọn đổi (Nếu người dùng chọn đổi)
        public int SelectedNewRoomId { get; set; }

        // Nhân viên phục vụ được chọn
        public int? SelectedStaffId { get; set; }

        // Danh sách nhân viên phục vụ khả dụng trong ca làm việc
        public List<StaffItem> EligibleStaffs { get; set; } = new List<StaffItem>();
    }

    public class StaffItem
    {
        public int AccountId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string ShiftInfo { get; set; } = string.Empty;
    }
}