using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

[Table("Holiday")]
public partial class Holiday
{
    public int HolidayId { get; set; }

    public string HolidayName { get; set; } = null!;

    public DateTime HolidayDate { get; set; }

    public decimal SurchargePercent { get; set; }

    public bool IsActive { get; set; } = true;
}
