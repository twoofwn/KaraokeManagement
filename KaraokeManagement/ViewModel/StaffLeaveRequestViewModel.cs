using KaraokeManagement.Models;
using System.Collections.Generic;

namespace KaraokeManagement.ViewModel
{
    public class StaffLeaveRequestViewModel
    {
        public Account Account { get; set; } = null!;
        public List<EmployeeSchedule> EligibleSchedules { get; set; } = new List<EmployeeSchedule>();
        public List<LeaveRequest> RequestHistory { get; set; } = new List<LeaveRequest>();
        public List<WorkShift> WorkShifts { get; set; } = new List<WorkShift>();
    }
}
