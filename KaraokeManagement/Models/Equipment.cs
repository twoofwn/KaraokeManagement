using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("Equipment")]
public partial class Equipment
{
    public int EquipmentId { get; set; }

    public int RoomId { get; set; }

    public string EquipmentName { get; set; } = null!;

    public string? SerialNumber { get; set; }

    public DateOnly? PurchaseDate { get; set; }

    public string? Status { get; set; }

    public virtual ICollection<MaintenanceLog> MaintenanceLogs { get; set; } = new List<MaintenanceLog>();

    public virtual Room Room { get; set; } = null!;
}
