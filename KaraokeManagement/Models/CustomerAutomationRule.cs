using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class CustomerAutomationRule
{
    public int RuleId { get; set; }
    public string RuleName { get; set; } = null!;
    public string EventType { get; set; } = null!;
    public string ActionPayload { get; set; } = null!;
    public bool? IsActive { get; set; }
}
