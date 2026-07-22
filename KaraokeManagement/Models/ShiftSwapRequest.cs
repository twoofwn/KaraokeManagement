using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class ShiftSwapRequest
{
    public int SwapRequestId { get; set; }
    public int RequesterId { get; set; }
    public int RequesterScheduleId { get; set; }
    public int TargetId { get; set; }
    public int TargetScheduleId { get; set; }
    public string Status { get; set; } = "Pending"; // Pending, Consented, Approved, Rejected
    public DateTime? CreatedAt { get; set; }
    public int? ApprovedById { get; set; }

    public virtual Account Requester { get; set; } = null!;
    public virtual EmployeeSchedule RequesterSchedule { get; set; } = null!;
    public virtual Account Target { get; set; } = null!;
    public virtual EmployeeSchedule TargetSchedule { get; set; } = null!;
    public virtual Account? ApprovedBy { get; set; }
}
