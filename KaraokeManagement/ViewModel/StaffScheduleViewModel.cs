using KaraokeManagement.Models;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class StaffScheduleViewModel
    {
        public Account Account { get; set; } = null!;
        public DateTime StartOfWeek { get; set; }
        public DateTime EndOfWeek { get; set; }
        public List<WorkShift> Shifts { get; set; } = new List<WorkShift>();
        public List<EmployeeSchedule> Schedules { get; set; } = new List<EmployeeSchedule>();
    }
}
