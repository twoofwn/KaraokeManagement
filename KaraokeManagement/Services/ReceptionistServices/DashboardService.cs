using KaraokeManagement.Controllers;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.ReceptionistServices;
public class DashboardService
{
    private readonly KaraokeManagementDbContext _context;
    public DashboardService(KaraokeManagementDbContext context) => _context = context;

    // Dashboard
    public async Task<ReceptionistDashboardViewModel> GetDashboardAsync(string searchString, string roomType, string status)
    {
        var now = DateTime.Now;

        // Lay roomtype
        var roomTypes = await GetRoomTypesAsync();
        var statuses = new List<string> { "Tất cả", "SẴN SÀNG", "ĐANG SỬ DỤNG", "ĐANG BẢO TRÌ" };

        // Lay danh sach phong
        var dbRooms = await _context.Rooms
            .Include(r => r.RoomType)
            .Include(r => r.Bookings).ThenInclude(b => b.Customer)
            .Include(r => r.Equipment).ThenInclude(e => e.MaintenanceLogs)
            .ToListAsync();

        var roomCards = new List<RoomCardViewModel>();
        foreach (var room in dbRooms)
        {
            var card = await MapToRoomCardViewModelAsync(room, now);
            roomCards.Add(card);
        }

        // Filter
        var filteredCards = FilterRoomCards(roomCards, searchString, roomType, status);

        return new ReceptionistDashboardViewModel
        {
            RoomCards = filteredCards,
            RoomTypes = roomTypes,
            Statuses = statuses,
            SearchString = searchString ?? "",
            SelectedRoomType = roomType ?? "Tất cả loại",
            SelectedStatus = status ?? "Tất cả",
            ReadyCount = filteredCards.Count(r => r.Status == "SẴN SÀNG"),
            UsingCount = filteredCards.Count(r => r.Status == "ĐANG SỬ DỤNG"),
            MaintenanceCount = filteredCards.Count(r => r.Status == "ĐANG BẢO TRÌ")
        };
    }



    // Lay room type
    private async Task<List<string>> GetRoomTypesAsync()
    {
        var dbRoomTypes = await _context.RoomTypes
            .Select(rt => rt.TypeName.ToUpper())
            .Distinct()
            .ToListAsync();

        var roomTypes = new List<string> { "Tất cả loại" };
        roomTypes.AddRange(dbRoomTypes);
        return roomTypes;
    }


    // Map tung phong qua viewmodel
    private async Task<RoomCardViewModel> MapToRoomCardViewModelAsync(Room room, DateTime now)
    {
        string typeNameUpper = room.RoomType.TypeName.ToUpper();
        var activeBooking = room.Bookings
            .FirstOrDefault(b => b.StartTime <= now && b.EndTime >= now && b.Status == "CheckedIn");

        string cardStatus = "SẴN SÀNG";
        string timeLeft = "--:--:--";
        string? maintenanceNote = null;
        bool showCheckIn = true;
        bool showDots = false;

        if (room.Status == "Maintenance")
        {
            cardStatus = "ĐANG BẢO TRÌ";
            showCheckIn = false;
            showDots = true;
            maintenanceNote = await GetLatestMaintenanceNoteAsync(room.RoomName);
        }
        else if (room.Status == "InUse" || activeBooking != null)
        {
            cardStatus = "ĐANG SỬ DỤNG";
            showCheckIn = false;
            showDots = true;
            timeLeft = CalculateRemainingTime(activeBooking, now);
        }

        return new RoomCardViewModel
        {
            RoomId = room.RoomId,
            RoomName = room.RoomName,
            TypeName = typeNameUpper,
            Status = cardStatus,
            IconClass = GetRoomIconClass(typeNameUpper),
            PricePerHour = room.RoomType.PricePerHour,
            TimeLeft = timeLeft,
            MaintenanceDescription = maintenanceNote,
            ShowCheckInButton = showCheckIn,
            ShowMenuDots = showDots
        };
    }

    // Lay note bao tri moi nhat
    private async Task<string> GetLatestMaintenanceNoteAsync(string roomName)
    {
        var latestLog = await _context.MaintenanceLogs
            .Where(l => l.IssueDescription != null && l.IssueDescription.Contains(roomName))
            .OrderByDescending(l => l.LogDate)
            .FirstOrDefaultAsync();

        return latestLog?.IssueDescription ?? "Đang bảo trì/sửa chữa";
    }

    // Tinh thoi gian con lai
    private string CalculateRemainingTime(Booking? activeBooking, DateTime now)
    {
        if (activeBooking?.EndTime == null) return "--:--:--";

        var remaining = activeBooking.EndTime.Value - now;
        return remaining.TotalSeconds > 0
            ? string.Format("{0:00}:{1:00}:{2:00}", (int)remaining.TotalHours, remaining.Minutes, remaining.Seconds)
            : "00:00:00";
    }

    private string GetRoomIconClass(string typeNameUpper)
    {
        if (typeNameUpper.Contains("SUPER VIP") || typeNameUpper.Contains("PARTY"))
            return "fa-solid fa-music";
        if (typeNameUpper.Contains("VIP"))
            return "fa-solid fa-star";
        if (typeNameUpper.Contains("COUPLE"))
            return "fa-solid fa-heart";

        return "fa-solid fa-microphone";
    }

    // Filter
    private List<RoomCardViewModel> FilterRoomCards(List<RoomCardViewModel> cards, string searchString,string roomType, string status)
    {
        var query = cards.AsEnumerable();

        if (!string.IsNullOrWhiteSpace(searchString))
        {
            var term = searchString.Trim().ToLower();
            query = query.Where(r => r.RoomName.ToLower().Contains(term) || r.TypeName.ToLower().Contains(term));
        }

        if (!string.IsNullOrWhiteSpace(roomType) && roomType != "Tất cả loại")
        {
            query = query.Where(r => r.TypeName.Equals(roomType, StringComparison.OrdinalIgnoreCase));
        }

        if (!string.IsNullOrWhiteSpace(status) && status != "Tất cả")
        {
            query = query.Where(r => r.Status.Equals(status, StringComparison.OrdinalIgnoreCase));
        }

        return query.ToList();
    }
}