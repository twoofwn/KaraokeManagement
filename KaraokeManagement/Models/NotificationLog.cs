using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("NotificationLog")]
public partial class NotificationLog
{
    public int NotificationId { get; set; }
    public int? BookingId { get; set; }
    public int CustomerId { get; set; }
    public string Channel { get; set; } = null!;
    public string Recipient { get; set; } = null!;
    public string MessageContent { get; set; } = null!;
    public string? SentStatus { get; set; }
    public DateTime? SentAt { get; set; }

    public virtual Booking? Booking { get; set; }
    public virtual Customer Customer { get; set; } = null!;
}
