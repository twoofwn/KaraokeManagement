using System;
using System.Collections.Generic;

namespace KaraokeManagement.Models
{
    public class EmployeeListViewModel
    {
        public List<EmployeeViewModel> Employees { get; set; } = new List<EmployeeViewModel>();
        public List<Role> Roles { get; set; } = new List<Role>();
    }

    public class EmployeeViewModel
    {
        public int AccountId { get; set; }
        public string Username { get; set; } = null!;
        public string? Password { get; set; } // Used for creation only
        public string FullName { get; set; } = null!;
        public string? Phone { get; set; }
        public string? Email { get; set; }
        public string IdentityCardNumber { get; set; } = null!;
        public DateOnly? DateOfBirth { get; set; }
        public string? Address { get; set; }
        public DateOnly HireDate { get; set; }
        public decimal? BaseHourlyRate { get; set; }
        public string? EmploymentStatus { get; set; }
        public int RoleId { get; set; }
        public string? RoleName { get; set; }
    }

    public class ScheduleListViewModel
    {
        public List<EmployeeSchedule> Schedules { get; set; } = new List<EmployeeSchedule>();
        public List<WorkShift> Shifts { get; set; } = new List<WorkShift>();
        public List<Account> StaffList { get; set; } = new List<Account>();
        public DateOnly FilterDate { get; set; }
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public List<DateOnly> WeekDays { get; set; } = new List<DateOnly>();
    }

    public class BatchSchedulePayload
    {
        public List<ScheduleAddDto> AddedRecords { get; set; } = new List<ScheduleAddDto>();
        public List<ScheduleUpdateDto> UpdatedRecords { get; set; } = new List<ScheduleUpdateDto>();
        public List<int> DeletedRecordIds { get; set; } = new List<int>();
    }

    public class ScheduleAddDto
    {
        public int AccountId { get; set; }
        public int ShiftId { get; set; }
        public DateOnly WorkDate { get; set; }
        public string? Status { get; set; } = "Scheduled";
    }

    public class ScheduleUpdateDto
    {
        public int ScheduleId { get; set; }
        public int AccountId { get; set; }
        public int ShiftId { get; set; }
        public DateOnly WorkDate { get; set; }
    }

    public class ShiftGridViewModel
    {
        public WorkShift Shift { get; set; } = null!;
        public ScheduleListViewModel Model { get; set; } = null!;
        public string[] DayNames { get; set; } = Array.Empty<string>();
    }

    public class AttendanceListViewModel
    {
        public List<Attendance> Attendances { get; set; } = new List<Attendance>();
        public List<Account> StaffList { get; set; } = new List<Account>();
        public DateTime FilterStartDate { get; set; }
        public DateTime FilterEndDate { get; set; }
    }

    public class EmployeeDetailViewModel
    {
        public string Username { get; set; } = null!;
        public string FullName { get; set; } = null!;
        public string RoleName { get; set; } = null!;
        public string? Phone { get; set; }
        public string? Email { get; set; }
        public string IdentityCardNumber { get; set; } = null!;
        public DateOnly? DateOfBirth { get; set; }
        public string? Address { get; set; }
        public DateOnly HireDate { get; set; }
        public decimal? BaseHourlyRate { get; set; }
        public bool IsActive { get; set; }
    }

    public class EmployeeReportItemViewModel
    {
        public string Month { get; set; } = null!;
        public decimal WorkingHours { get; set; }
        public int ShiftsWorked { get; set; }
        public int DaysOff { get; set; }
    }
}
