using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models
{
    public class WeeklyScheduleBoardViewModel
    {
        public DateTime StartOfWeek { get; set; }
        public DateTime EndOfWeek { get; set; }
        public List<DayScheduleGroup> Days { get; set; } = new List<DayScheduleGroup>();
        public List<ShiftSwapRequest> PendingSwapRequests { get; set; } = new List<ShiftSwapRequest>();
        public List<LeaveRequest> PendingLeaveRequests { get; set; } = new List<LeaveRequest>();
        public List<Account> AllStaff { get; set; } = new List<Account>();
    }

    public class DayScheduleGroup
    {
        public DateOnly Date { get; set; }
        public string DayOfWeekName { get; set; } = null!;
        public List<ShiftScheduleSubGroup> Shifts { get; set; } = new List<ShiftScheduleSubGroup>();
    }

    public class ShiftScheduleSubGroup
    {
        public WorkShift Shift { get; set; } = null!;
        public List<EmployeeSchedule> Schedules { get; set; } = new List<EmployeeSchedule>();
    }
}
