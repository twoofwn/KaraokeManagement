using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class ServiceItem
{
    public int ServiceId { get; set; }

    public int CategoryId { get; set; }

    public string ServiceName { get; set; } = null!;

    public decimal SellingPrice { get; set; }

    public string? Unit { get; set; }

    public int? StockQuantity { get; set; }

    public virtual Category Category { get; set; } = null!;

    public virtual ICollection<InvoiceDetail> InvoiceDetails { get; set; } = new List<InvoiceDetail>();

    public virtual ICollection<PurchaseOrderDetail> PurchaseOrderDetails { get; set; } = new List<PurchaseOrderDetail>();
}
