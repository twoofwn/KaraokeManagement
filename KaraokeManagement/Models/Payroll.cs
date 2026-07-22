using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("Payroll")]
public partial class Payroll
{
    public int PayrollId { get; set; }
    public int AccountId { get; set; }
    public int PayPeriodMonth { get; set; }
    public int PayPeriodYear { get; set; }
    public decimal BaseSalary { get; set; }
    public decimal? BonusAmount { get; set; }
    public decimal? DeductionAmount { get; set; }
    public decimal NetSalary { get; set; }
    public string? PaymentStatus { get; set; }
    public DateTime? PaymentDate { get; set; }
    public string? Note { get; set; }

    public virtual Account Account { get; set; } = null!;
}
