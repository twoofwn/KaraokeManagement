using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("Expense")]
public partial class Expense
{
    [Key]
    public int ExpenseId { get; set; }

    [Required]
    public int CategoryId { get; set; }

    [ForeignKey("CategoryId")]
    public virtual ExpenseCategory ExpenseCategory { get; set; } = null!;

    [Required]
    public DateTime ExpenseDate { get; set; }

    [Required]
    [Column(TypeName = "decimal(18, 2)")]
    public decimal Amount { get; set; }

    public string? Note { get; set; }

    public DateTime? CreatedAt { get; set; }
}
