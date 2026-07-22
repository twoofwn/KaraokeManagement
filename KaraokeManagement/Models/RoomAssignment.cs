using System;

namespace KaraokeManagement.Models
{
    public partial class RoomAssignment
    {
        public int RoomAssignmentId { get; set; }
        public int RoomId { get; set; }
        public int ScheduleId { get; set; }
        public DateTime AssignedAt { get; set; } = DateTime.Now;

        public virtual Room Room { get; set; } = null!;
        public virtual EmployeeSchedule Schedule { get; set; } = null!;
    }
}
