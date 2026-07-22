using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class CustomerCareLog
{
    public int LogId { get; set; }
    public int CustomerId { get; set; }
    public int AccountId { get; set; }
    public string InteractionType { get; set; } = null!;
    public string Notes { get; set; } = null!;
    public DateTime? LoggedDate { get; set; }

    public virtual Account Account { get; set; } = null!;
    public virtual Customer Customer { get; set; } = null!;
}
