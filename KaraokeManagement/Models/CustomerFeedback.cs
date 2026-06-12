using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class CustomerFeedback
{
    public int FeedbackId { get; set; }

    public int InvoiceId { get; set; }

    public int CustomerId { get; set; }

    public int? Rating { get; set; }

    public string? Comment { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Account Customer { get; set; } = null!;

    public virtual Invoice Invoice { get; set; } = null!;
}
