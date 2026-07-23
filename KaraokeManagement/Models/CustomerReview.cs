using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("CustomerReview")]
public partial class CustomerReview
{
    public int ReviewId { get; set; }
    public int BookingId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime? CreatedAt { get; set; }

    public virtual Booking Booking { get; set; } = null!;
}
