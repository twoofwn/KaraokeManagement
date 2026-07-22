using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class CustomerReview
{
    public int ReviewId { get; set; }
    public int InvoiceId { get; set; }
    public int CustomerId { get; set; }
    public int? StaffId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime? CreatedAt { get; set; }

    public virtual Customer Customer { get; set; } = null!;
    public virtual Invoice Invoice { get; set; } = null!;
    public virtual Account? Staff { get; set; }
}
