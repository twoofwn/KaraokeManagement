using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("RoomPrice")]
public partial class RoomPrice
{
    public int PriceId { get; set; }

    public int RoomTypeId { get; set; }

    public TimeSpan StartTime { get; set; }

    public TimeSpan EndTime { get; set; }

    public decimal PricePerHour { get; set; }

    public DateTime? EffectiveFrom { get; set; }

    public DateTime? EffectiveTo { get; set; }

    public virtual RoomType RoomType { get; set; } = null!;
}
