using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("MarketingCampaign")]
public partial class MarketingCampaign
{
    public int CampaignId { get; set; }
    public int? PromotionId { get; set; }
    public string CampaignName { get; set; } = null!;
    public string Channel { get; set; } = null!;
    public int? TargetTierId { get; set; }
    public string MessageTemplate { get; set; } = null!;
    public DateTime StartDate { get; set; }
    public string? Status { get; set; }

    public virtual Promotion? Promotion { get; set; }
    public virtual MembershipTier? TargetTier { get; set; }
}
