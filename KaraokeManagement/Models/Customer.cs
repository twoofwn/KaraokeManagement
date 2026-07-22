using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class Customer
{
    public int CustomerId { get; set; }

    public int? TierId { get; set; }

    public string FullName { get; set; } = null!;

    public string Phone { get; set; } = null!;

    public string? Email { get; set; }

    public int? LoyaltyPoints { get; set; }

    public DateTime? CreatedAt { get; set; }

    public string PasswordHash { get; set; } = null!;

    public bool IsEmailVerified { get; set; } = false;
    public string? EmailVerificationToken { get; set; }
    public DateTime? EmailVerificationTokenExpiry { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual MembershipTier? Tier { get; set; }
}
