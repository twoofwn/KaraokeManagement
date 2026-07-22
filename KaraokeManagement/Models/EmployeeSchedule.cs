using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class EmployeeSchedule
{
    public int ScheduleId { get; set; }
    public int AccountId { get; set; }
    public int ShiftId { get; set; }
    public DateOnly WorkDate { get; set; }
    public string? Status { get; set; }
    public bool IsActive { get; set; } = true;

    public virtual Account Account { get; set; } = null!;
    public virtual WorkShift Shift { get; set; } = null!;
    public virtual ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();
}
