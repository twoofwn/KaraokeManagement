using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class TrainingRecord
{
    public int TrainingId { get; set; }
    public int AccountId { get; set; }
    public string CourseName { get; set; } = null!;
    public DateOnly? CompletionDate { get; set; }
    public string? Result { get; set; }

    public virtual Account Account { get; set; } = null!;
}
