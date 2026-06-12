using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class Promotion
{
    public int PromotionId { get; set; }

    public string PromoCode { get; set; } = null!;

    public string PromoName { get; set; } = null!;

    public decimal? DiscountPercent { get; set; }

    public decimal? MaxDiscountAmount { get; set; }

    public DateTime StartDate { get; set; }

    public DateTime EndDate { get; set; }

    public virtual ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();
}
