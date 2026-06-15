using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class Invoice
{
    public int InvoiceId { get; set; }

    public int? BookingId { get; set; }

    public int RoomId { get; set; }

    public int ReceptionistId { get; set; }

    public int? PromotionId { get; set; }

    public DateTime CheckInTime { get; set; }

    public DateTime? CheckOutTime { get; set; }

    public decimal? RoomTotal { get; set; }

    public decimal? ServiceTotal { get; set; }

    public decimal? DiscountAmount { get; set; }

    public decimal? GrandTotal { get; set; }

    public string? Status { get; set; }

    public virtual Booking? Booking { get; set; }

    public virtual ICollection<InvoiceDetail> InvoiceDetails { get; set; } = new List<InvoiceDetail>();

    public virtual ICollection<PaymentTransaction> PaymentTransactions { get; set; } = new List<PaymentTransaction>();

    public virtual Promotion? Promotion { get; set; }

    public virtual Account Receptionist { get; set; } = null!;

    public virtual Room Room { get; set; } = null!;
}
