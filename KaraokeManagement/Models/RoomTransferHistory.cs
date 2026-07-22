
using System;

namespace KaraokeManagement.Models;

public partial class RoomTransferHistory
{
    public int TransferId { get; set; }

    public int BookingId { get; set; }

    public int FromRoomId { get; set; }

    public int ToRoomId { get; set; }

    public DateTime TransferredAt { get; set; }

    public string Reason { get; set; } = null!;

    public int ProcessedById { get; set; }

    // Navigation Properties
    public virtual Booking Booking { get; set; } = null!;

    public virtual Room FromRoom { get; set; } = null!;

    public virtual Room ToRoom { get; set; } = null!;

    public virtual Account ProcessedBy { get; set; } = null!;
}

