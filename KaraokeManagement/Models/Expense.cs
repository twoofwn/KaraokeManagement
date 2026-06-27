using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class Expense
{
    public int ExpenseId { get; set; }

    public string Category { get; set; } = null!;

    public DateTime ExpenseDate { get; set; }

    public decimal Amount { get; set; }

    public string? Note { get; set; }

    public DateTime? CreatedAt { get; set; }
}
