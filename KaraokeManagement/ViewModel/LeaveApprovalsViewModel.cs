using KaraokeManagement.Models;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class LeaveApprovalsViewModel
    {
        public List<LeaveRequest> PendingRequests { get; set; } = new List<LeaveRequest>();
        public List<LeaveRequest> HistoryRequests { get; set; } = new List<LeaveRequest>();
    }
}
