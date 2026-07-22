using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("PurchaseOrderDetail")]
public partial class PurchaseOrderDetail
{
    public int PodetailId { get; set; }

    public int PoId { get; set; }

    public int ServiceId { get; set; }

    public decimal ImportPrice { get; set; }

    public int Quantity { get; set; }

    public virtual PurchaseOrder Po { get; set; } = null!;

    public virtual ServiceItem Service { get; set; } = null!;
}
