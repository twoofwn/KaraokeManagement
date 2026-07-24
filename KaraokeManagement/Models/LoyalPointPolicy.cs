using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KaraokeManagement.Models;

[Table("LoyalPointPolicy")]
public class LoyalPointPolicy
{
    [Key]
    public int PolicyId { get; set; }

    [Required]
    [Column(TypeName = "decimal(18, 2)")]
    public decimal AmountPerPoint { get; set; } 

    public bool IsActive { get; set; } = true;
    [StringLength(255)]
    public string? Description { get; set; }
}