using System.Collections.Generic;
using KaraokeManagement.Models;

namespace KaraokeManagement.ViewModel
{
    public class StaffDashboardViewModel
    {
        public Account Account { get; set; } = null!;
        public List<StaffScheduleItemViewModel> TodaySchedules { get; set; } = new List<StaffScheduleItemViewModel>();
    }

    public class StaffScheduleItemViewModel
    {
        public EmployeeSchedule Schedule { get; set; } = null!;
        public List<Room> AssignedRooms { get; set; } = new List<Room>();
    }
}
