using KaraokeManagement.Controllers;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

public class DashboardService
{
    private readonly KaraokeManagementDbContext _context;
    public DashboardService(KaraokeManagementDbContext context) => _context = context;

    public async Task<ReceptionistDashboardViewModel> GetDashboardAsync(string searchString, string roomType, string status)
    {
        var dbRoomTypes = await _context.RoomTypes.Select(rt => rt.TypeName.ToUpper()).Distinct().ToListAsync();
        var roomTypes = new List<string> { "Tất cả loại" };
        roomTypes.AddRange(dbRoomTypes);

        var statuses = new List<string> { "Tất cả", "SẴN SÀNG", "ĐANG SỬ DỤNG", "ĐANG BẢO TRÌ" };
        var roomCards = new List<RoomCardViewModel>();
        var now = DateTime.Now;

        var dbRooms = await _context.Rooms
            .Include(r => r.RoomType)
            .Include(r => r.Bookings).ThenInclude(b => b.Customer)
            .Include(r => r.Equipment).ThenInclude(e => e.MaintenanceLogs)
            .ToListAsync();

        foreach (var room in dbRooms)
        {
            string cardStatus = "SẴN SÀNG";
            string timeLeft = "--:--:--";
            string? maintenanceNote = null;
            bool showCheckIn = true;
            bool showDots = false;

            var activeBooking = room.Bookings
                .FirstOrDefault(b => b.StartTime <= now && b.EndTime >= now && b.Status == "CheckedIn");

            if (room.Status == "Maintenance")
            {
                cardStatus = "ĐANG BẢO TRÌ";
                showCheckIn = false;
                showDots = true;

                var latestLog = await _context.MaintenanceLogs
                                    .Where(l => l.IssueDescription != null && l.IssueDescription.Contains(room.RoomName))
                                    .OrderByDescending(l => l.LogDate)
                                    .FirstOrDefaultAsync();

                maintenanceNote = latestLog?.IssueDescription ?? "Đang bảo trì/sửa chữa";
            }
            else if (room.Status == "InUse" || activeBooking != null)
            {
                cardStatus = "ĐANG SỬ DỤNG";
                showCheckIn = false;
                showDots = true;

                if (activeBooking != null && activeBooking.EndTime.HasValue)
                {
                    var remaining = activeBooking.EndTime.Value - now;
                    timeLeft = remaining.TotalSeconds > 0
                        ? string.Format("{0:00}:{1:00}:{2:00}", (int)remaining.TotalHours, remaining.Minutes, remaining.Seconds)
                        : "00:00:00";
                }
            }
            else
            {
                cardStatus = "SẴN SÀNG";
                showCheckIn = true;
                showDots = false;
            }

            string icon = "fa-solid fa-microphone";
            string typeNameUpper = room.RoomType.TypeName.ToUpper();
            if (typeNameUpper.Contains("SUPER VIP") || typeNameUpper.Contains("PARTY")) icon = "fa-solid fa-music";
            else if (typeNameUpper.Contains("VIP")) icon = "fa-solid fa-star";
            else if (typeNameUpper.Contains("COUPLE")) icon = "fa-solid fa-heart";

            roomCards.Add(new RoomCardViewModel
            {
                RoomId = room.RoomId,
                RoomName = room.RoomName,
                TypeName = typeNameUpper,
                Status = cardStatus,
                IconClass = icon,
                PricePerHour = room.RoomType.PricePerHour,
                TimeLeft = timeLeft,
                MaintenanceDescription = maintenanceNote,
                ShowCheckInButton = showCheckIn,
                ShowMenuDots = showDots
            });
        }

        if (!string.IsNullOrEmpty(searchString))
        {
            var term = searchString.Trim().ToLower();
            roomCards = roomCards.Where(r => r.RoomName.ToLower().Contains(term) || r.TypeName.ToLower().Contains(term)).ToList();
        }
        if (!string.IsNullOrEmpty(roomType) && roomType != "Tất cả loại")
            roomCards = roomCards.Where(r => r.TypeName.Equals(roomType, StringComparison.OrdinalIgnoreCase)).ToList();
        if (!string.IsNullOrEmpty(status) && status != "Tất cả")
            roomCards = roomCards.Where(r => r.Status.Equals(status, StringComparison.OrdinalIgnoreCase)).ToList();

        return new ReceptionistDashboardViewModel
        {
            RoomCards = roomCards,
            RoomTypes = roomTypes,
            Statuses = statuses,
            SearchString = searchString ?? "",
            SelectedRoomType = roomType ?? "Tất cả loại",
            SelectedStatus = status ?? "Tất cả",
            ReadyCount = roomCards.Count(r => r.Status == "SẴN SÀNG"),
            UsingCount = roomCards.Count(r => r.Status == "ĐANG SỬ DỤNG"),
            MaintenanceCount = roomCards.Count(r => r.Status == "ĐANG BẢO TRÌ")
        };
    }
}