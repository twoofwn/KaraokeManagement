using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models;

public partial class Category
{
    public int CategoryId { get; set; }

    public string CategoryName { get; set; } = null!;

    public virtual ICollection<ServiceItem> ServiceItems { get; set; } = new List<ServiceItem>();
}
