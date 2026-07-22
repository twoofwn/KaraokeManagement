using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("LeaveRequest")]
public partial class LeaveRequest
{
    public int LeaveRequestId { get; set; }
    public int AccountId { get; set; }
    public int ScheduleId { get; set; }
    public string Reason { get; set; } = null!;
    public string Status { get; set; } = "Pending"; // Pending, Approved, Rejected
    public DateTime? CreatedAt { get; set; }
    public int? ApprovedById { get; set; }

    public virtual Account Account { get; set; } = null!;
    public virtual EmployeeSchedule Schedule { get; set; } = null!;
    public virtual Account? ApprovedBy { get; set; }
}
