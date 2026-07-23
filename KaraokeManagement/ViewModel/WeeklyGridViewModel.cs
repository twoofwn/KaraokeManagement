using KaraokeManagement.Models;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class WeeklyGridViewModel
    {
        public DateTime StartOfWeek { get; set; }
        public DateTime EndOfWeek { get; set; }
        public List<WorkShift> Shifts { get; set; } = new List<WorkShift>();
        public List<EmployeeSchedule> RawSchedules { get; set; } = new List<EmployeeSchedule>();
    }
}
