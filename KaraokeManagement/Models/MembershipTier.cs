using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("MembershipTier")]
public partial class MembershipTier
{
    public int TierId { get; set; }

    public string TierName { get; set; } = null!;

    public decimal? DiscountPercent { get; set; }

    public int? MinPoints { get; set; }

    public virtual ICollection<Customer> Customers { get; set; } = new List<Customer>();
}
