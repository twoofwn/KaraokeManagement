using System;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class InvoiceHistoryViewModel
    {
        public List<InvoiceItemViewModel> Invoices { get; set; } = new List<InvoiceItemViewModel>();
        public string SearchString { get; set; } = string.Empty;
        public string CustomerFilter { get; set; } = string.Empty;
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public string SelectedStatus { get; set; } = "All";

        // Pagination
        public int CurrentPage { get; set; } = 1;
        public int TotalPages { get; set; } = 1;
        public int TotalCount { get; set; } = 0;
        public int PageSize { get; set; } = 10;
    }

    public class InvoiceItemViewModel
    {
        public int InvoiceId { get; set; }
        public string RoomName { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public string CustomerPhone { get; set; } = string.Empty;
        public string ReceptionistName { get; set; } = string.Empty;
        public DateTime CheckInTime { get; set; }
        public DateTime? CheckOutTime { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}
