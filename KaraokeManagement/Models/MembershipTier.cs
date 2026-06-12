using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class MembershipTier
{
    public int TierId { get; set; }

    public string TierName { get; set; } = null!;

    public decimal? DiscountPercent { get; set; }

    public int? MinPoints { get; set; }

    public virtual ICollection<Account> Accounts { get; set; } = new List<Account>();
}
