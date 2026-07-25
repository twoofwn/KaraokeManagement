using System.ComponentModel.DataAnnotations.Schema;

namespace KaraokeManagement.Models;

[Table("CancellationReason")]
public class CancellationReason
{
    public int CancellationReasonId { get; set; }

    public string Code { get; set; } = string.Empty;

    public string ReasonName { get; set; } = string.Empty;

    public string AppliesTo { get; set; } = "Both";

    public bool RequiresDetail { get; set; }

    public bool IsActive { get; set; } = true;

    public int SortOrder { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();
}
