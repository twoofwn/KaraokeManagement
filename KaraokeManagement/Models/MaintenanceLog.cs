using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class MaintenanceLog
{
    public int LogId { get; set; }

    public int EquipmentId { get; set; }

    public int ReportedById { get; set; }

    public string? IssueDescription { get; set; }

    public decimal? RepairCost { get; set; }

    public DateTime? LogDate { get; set; }

    public virtual Equipment Equipment { get; set; } = null!;

    public virtual Account ReportedBy { get; set; } = null!;
}
