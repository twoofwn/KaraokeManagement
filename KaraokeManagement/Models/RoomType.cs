using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class RoomType
{
    public int RoomTypeId { get; set; }

    public string TypeName { get; set; } = null!;

    public decimal PricePerHour { get; set; }

    public string? Description { get; set; }

    public string? ImageUrl { get; set; }

    public int Capacity { get; set; }

    public virtual ICollection<Room> Rooms { get; set; } = new List<Room>();

    public virtual ICollection<RoomPrice> RoomPrices { get; set; } = new List<RoomPrice>();
}
