using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using KaraokeManagement.Services;
using System.Security.Claims;

namespace KaraokeManagement.Controllers
{
    [Authorize(Roles = "Receptionist")]
    public class ReceptionistBookingController : Controller
    {
        private readonly KaraokeManagementDbContext _context;
        private readonly EmailService _emailService;

        public ReceptionistBookingController(KaraokeManagementDbContext context, EmailService emailService)
        {
            _context = context;
            _emailService = emailService;
        }

        [HttpGet]
        public async Task<IActionResult> ListBooking(
        string searchString,
        string customerFilter,
        string dateRange = "all",
        string status = "Pending",
        int page = 1)
        {
            var query = _context.Bookings
                .Include(b => b.Room)
                .Include(b => b.Customer)
                .Where(b => b.Status == "Pending")
                .AsQueryable();

            // Lọc theo tên hoặc SĐT
            if (!string.IsNullOrEmpty(customerFilter))
            {
                var term = customerFilter.Trim().ToLower();
                query = query.Where(b =>
                    b.Customer != null && (b.Customer.FullName.ToLower().Contains(term) || b.Customer.Phone.Contains(term))
                );
            }

            // Lọc thời gian
            DateTime now = DateTime.Now;
            if (!string.IsNullOrEmpty(dateRange) && dateRange != "all")
            {
                switch (dateRange.ToLower())
                {
                    case "3days":
                        DateTime threeDaysAgo = now.AddDays(-3).Date; // Bắt đầu từ 00:00 của 3 ngày trước
                        query = query.Where(b => b.StartTime >= threeDaysAgo);
                        break;

                    case "7days":
                        DateTime sevenDaysAgo = now.AddDays(-7).Date;
                        query = query.Where(b => b.StartTime >= sevenDaysAgo);
                        break;

                    case "30days":
                        DateTime thirtyDaysAgo = now.AddDays(-30).Date;
                        query = query.Where(b => b.StartTime >= thirtyDaysAgo);
                        break;
                }
            }

            int totalCount = await query.CountAsync();
            int pageSize = 10;
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages < 1) totalPages = 1;
            if (page < 1) page = 1;
            if (page > totalPages) page = totalPages;

            var bookings = await query
                .OrderByDescending(b => b.StartTime)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(b => new BookingItemViewModel
                {
                    BookingId = b.BookingId,
                    RoomName = b.Room != null ? b.Room.RoomName : "Chưa chọn",
                    CustomerName = b.Customer != null ? b.Customer.FullName : "Khách vãng lai",
                    CustomerPhone = b.Customer != null ? b.Customer.Phone : "",
                    StartTime = b.StartTime,
                    EndTime = b.EndTime,
                    GuestCount = b.GuestCount,
                    Note = b.Note,
                    Status = b.Status ?? "Pending"
                })
                .ToListAsync();

            var viewModel = new ListBookingViewModel
            {
                Bookings = bookings,
                SearchString = searchString ?? string.Empty,
                CustomerFilter = customerFilter ?? string.Empty,
                DateRange = dateRange,
                SelectedStatus = status,
                CurrentPage = page,
                TotalPages = totalPages,
                TotalCount = totalCount,
                PageSize = pageSize
            };

            return View(viewModel);
        }
        // UpdateBookingStatus
        [HttpPost]
        public async Task<IActionResult> UpdateBookingStatus([FromBody] UpdateBookingStatusRequest request)
        {
            if (request == null || request.BookingId <= 0)
            {
                return Json(new { success = false, message = "Dữ liệu không hợp lệ." });
            }

            var booking = await _context.Bookings
                .Include(b => b.Customer)
                .Include(b => b.Room)
                .FirstOrDefaultAsync(b => b.BookingId == request.BookingId);

            if (booking == null)
            {
                return Json(new { success = false, message = "Không tìm thấy thông tin đặt phòng." });
            }

            if (request.Status != "Confirmed" && request.Status != "Cancelled")
            {
                return Json(new { success = false, message = "Trạng thái cập nhật không hợp lệ." });
            }

            var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                              ?? User.FindFirstValue("AccountId");

            if (!int.TryParse(accountIdClaim, out int accountId) || accountId <= 0)
            {
                return Json(new { success = false, message = "Phiên làm việc hết hạn hoặc không xác định được tài khoản thao tác." });
            }

            booking.Status = request.Status;
            booking.CreatedById = accountId;
            await _context.SaveChangesAsync();

            if (request.Status == "Confirmed" && booking.Customer != null)
            {
                try
                {
                    string customerName = booking.Customer.FullName ?? "Quý khách";
                    string roomName = booking.Room?.RoomName ?? "Phòng Karaoke";
                    string startTime = booking.StartTime.ToString("dd/MM/yyyy HH:mm");
                    string bookingCode = $"{booking.BookingId:D5}";

                    string subject = $"[Minh Tuấn Karaoke] Xác nhận đơn đặt phòng {bookingCode}";
                    string body = $@"
                        <div style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                            <h2 style='color: #e11d48;'>Xác nhận đặt phòng thành công!</h2>
                            <p>Xin chào <b>{customerName}</b>,</p>
                            <p>Cảm ơn bạn đã lựa chọn <b>Minh Tuấn Karaoke</b>. Đơn đặt phòng của bạn đã được lễ tân xác nhận.</p>
                            <div style='background: #f9fafb; padding: 15px; border-radius: 8px; border: 1px solid #e5e7eb; margin: 20px 0;'>
                                <p style='margin: 5px 0;'><b>Mã đặt phòng:</b> {bookingCode}</p>
                                <p style='margin: 5px 0;'><b>Phòng:</b> {roomName}</p>
                                <p style='margin: 5px 0;'><b>Thời gian bắt đầu:</b> {startTime}</p>
                                <p style='margin: 5px 0;'><b>Số lượng khách:</b> {(booking.GuestCount.HasValue ? booking.GuestCount.Value.ToString() : "Chưa cập nhật")}</p>
                            </div>
                            <p>Vui lòng đến đúng giờ để có trải nghiệm tốt nhất.</p>
                            <p>Nếu có thay đổi hoặc cần hỗ trợ gấp, xin vui lòng liên hệ lễ tân qua SĐT: 0868754128.</p>
                            <p>Trân trọng,<br><b>Minh Tuấn Karaoke</b></p>
                        </div>";

                    _ = _emailService.SendEmailAsync(booking.Customer.Email, subject, body);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Gửi email thất bại: {ex.Message}");
                }
            }

            return Json(new { success = true, message = $"Đã cập nhật trạng thái đơn đặt phòng thành {request.Status}." });
        }
    }
}