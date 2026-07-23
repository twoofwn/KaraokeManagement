using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("Booking")]
public partial class Booking
{
    public int BookingId { get; set; }

    public int CustomerId { get; set; }

    public int CreatedById { get; set; }

    public int RoomId { get; set; }

    public DateTime? BookingTime { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime? EndTime { get; set; }

    public string? Status { get; set; }

    public int? GuestCount { get; set; }

    public string? Note { get; set; }

    public int? StaffId { get; set; }

    public virtual Account CreatedBy { get; set; } = null!;
    public virtual Account? Staff { get; set; }

    public virtual Customer Customer { get; set; } = null!;

    public virtual ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();

    public virtual Room Room { get; set; } = null!;

    public virtual ICollection<RoomTransferHistory> RoomTransferHistories { get; set; } = new List<RoomTransferHistory>();
}
