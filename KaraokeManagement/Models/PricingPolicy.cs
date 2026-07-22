using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("PricingPolicy")]
public partial class PricingPolicy
{
    public int PolicyId { get; set; }

    public string PolicyName { get; set; } = null!;

    public string PolicyType { get; set; } = null!; // 'Weekend', 'Holiday'

    public decimal Value { get; set; }

    public bool IsActive { get; set; } = true;
}
