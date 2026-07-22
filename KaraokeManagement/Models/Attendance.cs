using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class Attendance
{
    public int AttendanceId { get; set; }
    public int AccountId { get; set; }
    public int? ScheduleId { get; set; }
    public DateTime CheckInTime { get; set; }
    public DateTime? CheckOutTime { get; set; }
    public decimal? TotalHours { get; set; }
    public string? Status { get; set; }
    public string? Note { get; set; }

    public virtual Account Account { get; set; } = null!;
    public virtual EmployeeSchedule? Schedule { get; set; }
}
