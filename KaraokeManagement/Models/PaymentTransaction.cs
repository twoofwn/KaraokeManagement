using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class PaymentTransaction
{
    public int TransactionId { get; set; }

    public int InvoiceId { get; set; }

    public int MethodId { get; set; }

    public decimal Amount { get; set; }

    public DateTime? TransactionDate { get; set; }

    public string? ReferenceCode { get; set; }

    public virtual Invoice Invoice { get; set; } = null!;

    public virtual PaymentMethod Method { get; set; } = null!;
}
