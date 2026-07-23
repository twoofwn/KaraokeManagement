using System;
using System.Collections.Generic;
using KaraokeManagement.Models;

namespace KaraokeManagement.ViewModel
{
    public class ManagerInvoicesViewModel
    {
        public List<Invoice> Invoices { get; set; } = new List<Invoice>();
        public DateTime FromDate { get; set; }
        public DateTime ToDate { get; set; }
        public string? SearchInvoiceId { get; set; }
        public DateTime? SearchDate { get; set; }
        public int? SelectedRoomId { get; set; }
        public List<Room> Rooms { get; set; } = new List<Room>();
        
        public int CurrentPage { get; set; }
        public int TotalPages { get; set; }
        public int TotalCount { get; set; }
        public int StartEntry { get; set; }
        public int EndEntry { get; set; }
    }
}
