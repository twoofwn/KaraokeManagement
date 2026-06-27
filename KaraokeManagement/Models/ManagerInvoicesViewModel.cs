using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models
{
    public class ManagerInvoicesViewModel
    {
        public List<Invoice> Invoices { get; set; } = new List<Invoice>();
        public DateTime FromDate { get; set; }
        public DateTime ToDate { get; set; }
        public int CurrentPage { get; set; }
        public int TotalPages { get; set; }
        public int TotalCount { get; set; }
        public int StartEntry { get; set; }
        public int EndEntry { get; set; }
    }
}
