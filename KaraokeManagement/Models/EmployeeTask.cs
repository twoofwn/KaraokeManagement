using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class EmployeeTask
{
    public int TaskId { get; set; }
    public int AssignedToId { get; set; }
    public int CreatedById { get; set; }
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public DateTime DueDate { get; set; }
    public string? Status { get; set; }

    public virtual Account AssignedTo { get; set; } = null!;
    public virtual Account CreatedBy { get; set; } = null!;
}
