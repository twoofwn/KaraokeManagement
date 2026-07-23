using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("InvoiceDetail")]
public partial class InvoiceDetail
{
    public int InvoiceDetailId { get; set; }

    public int InvoiceId { get; set; }

    public int ServiceId { get; set; }

    public int Quantity { get; set; }

    public decimal UnitPrice { get; set; }

    public bool IsService { get; set; }

    public bool IsFulFilled { get; set; }

    public string? Note { get; set; }

    public virtual Invoice Invoice { get; set; } = null!;

    public virtual ServiceItem Service { get; set; } = null!;
}
