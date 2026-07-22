using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class WorkShift
{
    public int ShiftId { get; set; }
    public string ShiftName { get; set; } = null!;
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }

    public virtual ICollection<EmployeeSchedule> EmployeeSchedules { get; set; } = new List<EmployeeSchedule>();
}
