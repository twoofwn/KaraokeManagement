using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KaraokeManagement.Models;

[Table("RoomImage")]
public class RoomImage
{
    [Key]
    public int RoomImageId { get; set; }

    public int RoomId { get; set; }

    [Required]
    [MaxLength(500)]
    public string ImageUrl { get; set; } = null!;

    [ForeignKey("RoomId")]
    public virtual Room? Room { get; set; }
}
