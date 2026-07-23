using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("ExpenseCategory")]
public partial class ExpenseCategory
{
    [Key]
    public int CategoryId { get; set; }

    [Required]
    [StringLength(200)]
    public string CategoryName { get; set; } = null!;

    public virtual ICollection<Expense> Expenses { get; set; } = new List<Expense>();
}
