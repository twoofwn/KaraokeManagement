using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("PurchaseOrder")]
public partial class PurchaseOrder
{
    public int PoId { get; set; }

    public int SupplierId { get; set; }

    public int CreatedById { get; set; }

    public DateTime? OrderDate { get; set; }

    public decimal? TotalAmount { get; set; }

    public virtual Account CreatedBy { get; set; } = null!;

    public virtual ICollection<PurchaseOrderDetail> PurchaseOrderDetails { get; set; } = new List<PurchaseOrderDetail>();

    public virtual Supplier Supplier { get; set; } = null!;
}
