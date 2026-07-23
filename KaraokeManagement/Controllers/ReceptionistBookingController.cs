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
                        DateTime threeDaysAgo = now.AddDays(-3).Date;
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

        [HttpGet]
        public async Task<IActionResult> CheckIn(string search = "")
        {
            DateTime todayStart = DateTime.Today; 
            DateTime todayEnd = todayStart.AddDays(1).AddTicks(-1); 

            // Loc cac booking co status la Confirmed va trong hom nay
            var query = _context.Bookings
                .Include(b => b.Customer)
                .Include(b => b.Room)
                    .ThenInclude(r => r.RoomType)
                .Where(b => b.Status == "Confirmed"
                         && b.StartTime >= todayStart
                         && b.StartTime <= todayEnd)
                .AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                search = search.Trim().ToLower();
                query = query.Where(b => (b.Customer != null && b.Customer.FullName.ToLower().Contains(search))
                                      || (b.Customer != null && b.Customer.Phone != null && b.Customer.Phone.Contains(search))
                                      || (b.Room != null && b.Room.RoomName.ToLower().Contains(search)));
            }

            var pendingBookings = await query.OrderBy(b => b.StartTime).ToListAsync();
            return View(pendingBookings);
        }

        // CheckinDetail
        [HttpGet]
        public async Task<IActionResult> CheckInDetail(int id)
        {
            var booking = await _context.Bookings
                .Include(b => b.Customer)
                .Include(b => b.Room)
                .ThenInclude(r => r.RoomType)
                .FirstOrDefaultAsync(b => b.BookingId == id);

            if (booking == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy thông tin đơn đặt phòng này!";
                return RedirectToAction("CheckIn");
            }

            DateTime startTime = booking.StartTime;
            DateTime endTime = booking.EndTime ?? startTime.AddHours(2);

            // Tim phong available, ko dc trung lich
            var occupiedRoomIds = await _context.Bookings
                .Where(b => b.BookingId != booking.BookingId
                         && (b.Status == "Confirmed" || b.Status == "CheckedIn")
                         && b.StartTime < endTime
                         && (b.EndTime ?? b.StartTime.AddHours(2)) > startTime)
                .Select(b => b.RoomId)
                .Distinct()
                .ToListAsync();

            // Tim phong available, ko dc trung lich
            var availableRooms = await _context.Rooms
                .Include(r => r.RoomType)
                .Where(r => !occupiedRoomIds.Contains(r.RoomId))
                .Select(r => new AvailableRoomItem
                {
                    RoomId = r.RoomId,
                    RoomName = r.RoomName,
                    TypeName = r.RoomType.TypeName,
                    PricePerHour = r.RoomType.PricePerHour
                })
                .ToListAsync();

            // Tìm danh sách nhân viên phục vụ có lịch làm việc trùng khung giờ booking
            DateOnly bookingDate = DateOnly.FromDateTime(booking.StartTime);
            TimeSpan bookingStart = booking.StartTime.TimeOfDay;
            TimeSpan bookingEnd = (booking.EndTime ?? booking.StartTime.AddHours(2)).TimeOfDay;

            var scheduledStaffList = await _context.EmployeeSchedules
                .Include(s => s.Account)
                .ThenInclude(a => a.Role)
                .Include(s => s.Shift)
                .Where(s => s.WorkDate == bookingDate 
                          && s.IsActive 
                          && (s.Account.Role.RoleName == "Service Staff" || s.Account.Role.RoleName.Contains("Phục vụ"))
                          && s.Account.IsActive == true)
                .ToListAsync();

            var matchedStaff = scheduledStaffList.Where(s => {
                var shiftStart = s.Shift.StartTime;
                var shiftEnd = s.Shift.EndTime;
                if (shiftEnd > shiftStart)
                {
                    return bookingStart < shiftEnd && bookingEnd > shiftStart;
                }
                else
                {
                    return bookingStart >= shiftStart || bookingEnd <= shiftEnd || bookingStart < shiftEnd;
                }
            }).Select(s => new StaffItem
            {
                AccountId = s.Account.AccountId,
                FullName = s.Account.FullName,
                Phone = s.Account.Phone ?? string.Empty,
                ShiftInfo = $"{s.Shift.ShiftName} ({s.Shift.StartTime:hh\\:mm} - {s.Shift.EndTime:hh\\:mm})"
            }).ToList();

            if (!matchedStaff.Any())
            {
                var allStaff = await _context.Accounts
                    .Include(a => a.Role)
                    .Where(a => (a.Role.RoleName == "Service Staff" || a.Role.RoleName.Contains("Phục vụ")) && a.IsActive == true)
                    .ToListAsync();

                matchedStaff = allStaff.Select(a => new StaffItem
                {
                    AccountId = a.AccountId,
                    FullName = a.FullName,
                    Phone = a.Phone ?? string.Empty,
                    ShiftInfo = "Không có ca trực (Tất cả)"
                }).ToList();
            }

            var viewModel = new CheckInDetailViewModel
            {
                BookingId = booking.BookingId,
                CustomerId = booking.CustomerId,
                CustomerName = booking.Customer.FullName,
                Phone = booking.Customer.Phone,
                Email = booking.Customer.Email,
                CurrentRoomId = booking.RoomId,
                CurrentRoomName = booking.Room.RoomName,
                CurrentRoomTypeName = booking.Room.RoomType.TypeName,
                CurrentPricePerHour = booking.Room.RoomType.PricePerHour,
                CurrentRoomTypeImageUrl = booking.Room.RoomType.ImageUrl,
                StartTime = booking.StartTime,
                EndTime = booking.EndTime,
                GuestCount = booking.GuestCount,
                Note = booking.Note,
                Status = booking.Status ?? "Confirmed",
                SelectedNewRoomId = booking.RoomId,
                AvailableRoomsToSwitch = availableRooms,
                SelectedStaffId = booking.StaffId,
                EligibleStaffs = matchedStaff
            };

            return View(viewModel);
        }

        // Confirm Checkin
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ConfirmCheckIn(CheckInDetailViewModel model)
        {
            var booking = await _context.Bookings.FirstOrDefaultAsync(b => b.BookingId == model.BookingId);
            if (booking == null)
            {
                return NotFound();
            }

            var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                              ?? User.FindFirstValue("AccountId");

            if (!int.TryParse(accountIdClaim, out int accountId) || accountId <= 0)
            {
                return Json(new { success = false, message = "Phiên làm việc hết hạn hoặc không xác định được tài khoản thao tác." });
            }

            // Cap nhat thong tin khach hang
            var customer = await _context.Customers.FirstOrDefaultAsync(c => c.CustomerId == booking.CustomerId);
            if (customer != null)
            {
                customer.FullName = model.CustomerName;
                customer.Phone = model.Phone;
                customer.Email = model.Email;
                _context.Customers.Update(customer);
            }

            // Cập nhật RoomId nếu có chọn đổi phòng
            if (model.SelectedNewRoomId > 0 && model.SelectedNewRoomId != booking.RoomId)
            {
                booking.RoomId = model.SelectedNewRoomId;
            }

            // Cập nhật số lượng khách và ghi chú
            booking.GuestCount = model.GuestCount;
            booking.Note = model.Note;

            // Cập nhật nhân viên phục vụ
            if (model.SelectedStaffId.HasValue && model.SelectedStaffId.Value > 0)
            {
                booking.StaffId = model.SelectedStaffId;
            }
            else
            {
                booking.StaffId = null;
            }

            // Cập nhật trạng thái Booking sang CheckedIn
            booking.Status = "CheckedIn";
            _context.Bookings.Update(booking);

            // Cập nhật trạng thái phòng sang Occupied
            var room = await _context.Rooms.FirstOrDefaultAsync(r => r.RoomId == booking.RoomId);
            if (room != null)
            {
                room.Status = "Occupied";
                _context.Rooms.Update(room);
            }

            // Tao Invoice moi
            var invoice = new Invoice
            {
                BookingId = booking.BookingId,
                RoomId = booking.RoomId,
                ReceptionistId = accountId,
                PromotionId = 2,
                CheckInTime = DateTime.Now,
                Status = "Unpaid",
                RoomTotal = 0,
                ServiceTotal = 0,
                GrandTotal = 0
            };

            _context.Invoices.Add(invoice);
            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = "Check-in thành công!";
            return RedirectToAction("Index", "Receptionist");
        }

        // Huy Booking
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CancelBooking(int bookingId)
        {
            var booking = await _context.Bookings.FirstOrDefaultAsync(b => b.BookingId == bookingId);
            if (booking != null)
            {
                booking.Status = "Cancelled";
                _context.Bookings.Update(booking);
                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "Đã hủy đơn đặt phòng thành công.";
            }

            return RedirectToAction("CheckIn");
        }
    }
}