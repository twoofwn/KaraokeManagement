using KaraokeManagement.Controllers;

namespace KaraokeManagement.ViewModel
{
    public class ReceptionistDashboardViewModel
    {
        public List<RoomCardViewModel> RoomCards { get; set; } = new List<RoomCardViewModel>();
        public List<string> RoomTypes { get; set; } = new List<string>();
        public List<string> Statuses { get; set; } = new List<string>();

        public string SearchString { get; set; } = string.Empty;
        public string SelectedRoomType { get; set; } = string.Empty;
        public string SelectedStatus { get; set; } = string.Empty;

        public int ReadyCount { get; set; }
        public int UsingCount { get; set; }
        public int MaintenanceCount { get; set; }
    }

    public class RoomCardViewModel
    {
        public int RoomId { get; set; }
        public string RoomName { get; set; } = string.Empty;
        public string TypeName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string IconClass { get; set; } = string.Empty;
        public decimal PricePerHour { get; set; }
        public string? TimeLeft { get; set; }
        public string? MaintenanceDescription { get; set; }
        public bool ShowCheckInButton { get; set; }
        public bool ShowMenuDots { get; set; }
    }

    public class AddServiceRequest
    {
        public int RoomId { get; set; }
        public int ServiceId { get; set; }
    }

    public class UpdateServiceRequest
    {
        public int InvoiceDetailId { get; set; }
        public int Quantity { get; set; }
    }

    public class RemoveServiceRequest
    {
        public int InvoiceDetailId { get; set; }
    }

    public class ChangeRoomRequest
    {
        public int InvoiceId { get; set; }
        public int NewRoomId { get; set; }
        public string OldRoomStatus { get; set; } = "Available";
        public string? Reason { get; set; }
    }
    public class PaymentRequest
    {
        public int InvoiceId { get; set; }
    }

    public class CreateCustomerRequest
    {
        public string Phone { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? Email { get; set; }
    }
}
