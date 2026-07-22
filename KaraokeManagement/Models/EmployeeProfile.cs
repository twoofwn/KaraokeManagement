using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class EmployeeProfile
{
    public int ProfileId { get; set; }
    public int AccountId { get; set; }
    public string IdentityCardNumber { get; set; } = null!;
    public DateOnly? DateOfBirth { get; set; }
    public string? Address { get; set; }
    public DateOnly HireDate { get; set; }
    public decimal? BaseHourlyRate { get; set; }
    public string? EmploymentStatus { get; set; }

    public virtual Account Account { get; set; } = null!;
}
