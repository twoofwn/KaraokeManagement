using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace KaraokeManagement.Controllers
{
    [Authorize(Roles = "Receptionist")]
    public class ReceptionistController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        public ReceptionistController(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> Index(string searchString, string roomType, string status)
        {
            // Lay danh sach loai phong
            var dbRoomTypes = await _context.RoomTypes.Select(rt => rt.TypeName.ToUpper()).Distinct().ToListAsync();
            List<string> roomTypes = new List<string> { "Tất cả loại" };
            roomTypes.AddRange(dbRoomTypes);

            List<string> statuses = new List<string> { "Tất cả", "SẴN SÀNG", "ĐANG SỬ DỤNG", "ĐANG BẢO TRÌ" };

            List<RoomCardViewModel> roomCards = new List<RoomCardViewModel>();
            var now = DateTime.Now;

            try
            {
                var dbRooms = await _context.Rooms
                    .Include(r => r.RoomType)
                    .Include(r => r.Bookings).ThenInclude(b => b.Customer)
                    .Include(r => r.Equipment).ThenInclude(e => e.MaintenanceLogs)
                    .ToListAsync();

                foreach (var room in dbRooms)
                {
                    string cardStatus = "SẴN SÀNG";
                    string timeLeft = "--:--:--";
                    string maintenanceNote = null;
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

                        maintenanceNote = latestLog != null ? latestLog.IssueDescription : "Đang bảo trì/sửa chữa";
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
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"DB Loading failed: {ex.Message}");
            }

            int readyCount = roomCards.Count(r => r.Status == "SẴN SÀNG");
            int usingCount = roomCards.Count(r => r.Status == "ĐANG SỬ DỤNG");
            int maintenanceCount = roomCards.Count(r => r.Status == "ĐANG BẢO TRÌ");

            if (!string.IsNullOrEmpty(searchString))
            {
                var term = searchString.Trim().ToLower();
                roomCards = roomCards.Where(r => r.RoomName.ToLower().Contains(term) || r.TypeName.ToLower().Contains(term)).ToList();
            }

            if (!string.IsNullOrEmpty(roomType) && roomType != "Tất cả loại")
            {
                roomCards = roomCards.Where(r => r.TypeName.Equals(roomType, StringComparison.OrdinalIgnoreCase)).ToList();
            }

            if (!string.IsNullOrEmpty(status) && status != "Tất cả")
            {
                roomCards = roomCards.Where(r => r.Status.Equals(status, StringComparison.OrdinalIgnoreCase)).ToList();
            }

            var viewModel = new ReceptionistDashboardViewModel
            {
                RoomCards = roomCards,
                RoomTypes = roomTypes,
                Statuses = statuses,
                SearchString = searchString,
                SelectedRoomType = roomType ?? "Tất cả loại",
                SelectedStatus = status ?? "Tất cả",

                ReadyCount = readyCount,
                UsingCount = usingCount,
                MaintenanceCount = maintenanceCount
            };

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> Detail(int roomId)
        {
            var room = await _context.Rooms
                .Include(r => r.RoomType)
                .FirstOrDefaultAsync(r => r.RoomId == roomId);

            if (room == null)
            {
                return RedirectToAction("Index");
            }

            // Find active unpaid invoice
            var invoice = await _context.Invoices
                .Include(i => i.InvoiceDetails)
                .ThenInclude(id => id.Service)
                .FirstOrDefaultAsync(i => i.RoomId == roomId && i.Status == "Unpaid");

            if (invoice == null)
            {
                var userName = User.Identity?.Name;
                var receptionist = await _context.Accounts.FirstOrDefaultAsync(a => a.FullName == userName || a.Username == userName);
                if (receptionist == null)
                {
                    receptionist = await _context.Accounts.FirstOrDefaultAsync();
                }
                int receptionistId = receptionist?.AccountId ?? 1;

                invoice = new Invoice
                {
                    RoomId = roomId,
                    ReceptionistId = receptionistId,
                    CheckInTime = DateTime.Now,
                    Status = "Unpaid",
                    RoomTotal = 0,
                    ServiceTotal = 0,
                    DiscountAmount = 0,
                    GrandTotal = 0
                };

                _context.Invoices.Add(invoice);
                if (room.Status != "InUse")
                {
                    room.Status = "InUse";
                }
                await _context.SaveChangesAsync();
            }

            var categories = await _context.Categories
                .Select(c => new CategoryViewModel
                {
                    CategoryId = c.CategoryId,
                    CategoryName = c.CategoryName
                })
                .ToListAsync();

            var serviceItems = await _context.ServiceItems
                .Include(s => s.Category)
                .Select(s => new PosProductItem
                {
                    ServiceId = s.ServiceId,
                    CategoryId = s.CategoryId,
                    ServiceName = s.ServiceName,
                    SellingPrice = s.SellingPrice,
                    Unit = s.Unit,
                    StockQuantity = s.StockQuantity ?? 0,
                    CategoryName = s.Category.CategoryName
                })
                .ToListAsync();

            var orderItems = invoice.InvoiceDetails.Select(id => new PosOrderItem
            {
                InvoiceDetailId = id.InvoiceDetailId,
                ServiceId = id.ServiceId,
                ServiceName = id.Service.ServiceName,
                Unit = id.Service.Unit,
                Quantity = id.Quantity,
                UnitPrice = id.UnitPrice
            }).ToList();

            var availableRooms = await _context.Rooms
                .Include(r => r.RoomType)
                .Where(r => r.Status == "Available" && r.RoomId != roomId)
                .Select(r => new PosRoomItem
                {
                    RoomId = r.RoomId,
                    RoomName = r.RoomName,
                    RoomTypeName = r.RoomType.TypeName,
                    PricePerHour = r.RoomType.PricePerHour
                })
                .ToListAsync();

            var viewModel = new RoomDetailPosViewModel
            {
                RoomId = room.RoomId,
                RoomName = room.RoomName,
                RoomTypeName = room.RoomType.TypeName,
                PricePerHour = room.RoomType.PricePerHour,
                RoomStatus = room.Status ?? "InUse",
                InvoiceId = invoice.InvoiceId,
                CheckInTime = invoice.CheckInTime,
                OrderItems = orderItems,
                ProductItems = serviceItems,
                Categories = categories,
                AvailableRooms = availableRooms
            };

            return View(viewModel);
        }

        private async Task RecalculateInvoiceTotals(int invoiceId)
        {
            var invoice = await _context.Invoices
                .Include(i => i.InvoiceDetails)
                .Include(i => i.Room)
                .ThenInclude(r => r.RoomType)
                .FirstOrDefaultAsync(i => i.InvoiceId == invoiceId);

            if (invoice != null)
            {
                decimal serviceTotal = invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);
                invoice.ServiceTotal = serviceTotal;

                var duration = DateTime.Now - invoice.CheckInTime;
                double hours = duration.TotalHours;
                if (hours < 0) hours = 0;
                decimal roomTotal = (decimal)hours * invoice.Room.RoomType.PricePerHour;
                invoice.RoomTotal = roomTotal;

                invoice.GrandTotal = roomTotal + serviceTotal - (invoice.DiscountAmount ?? 0);

                await _context.SaveChangesAsync();
            }
        }

        [HttpPost]
        public async Task<IActionResult> AddServiceItem([FromBody] AddServiceRequest request)
        {
            var service = await _context.ServiceItems.FindAsync(request.ServiceId);
            if (service == null)
            {
                return Json(new { success = false, message = "Sản phẩm không tồn tại." });
            }

            if (service.StockQuantity.HasValue && service.StockQuantity.Value <= 0)
            {
                return Json(new { success = false, message = "Sản phẩm đã hết hàng trong kho." });
            }

            var invoice = await _context.Invoices
                .Include(i => i.InvoiceDetails)
                .FirstOrDefaultAsync(i => i.RoomId == request.RoomId && i.Status == "Unpaid");

            if (invoice == null)
            {
                return Json(new { success = false, message = "Không tìm thấy hóa đơn chưa thanh toán cho phòng này." });
            }

            var detail = invoice.InvoiceDetails.FirstOrDefault(d => d.ServiceId == request.ServiceId);
            if (detail != null)
            {
                detail.Quantity += 1;
            }
            else
            {
                detail = new InvoiceDetail
                {
                    InvoiceId = invoice.InvoiceId,
                    ServiceId = request.ServiceId,
                    Quantity = 1,
                    UnitPrice = service.SellingPrice
                };
                _context.InvoiceDetails.Add(detail);
            }

            if (service.StockQuantity.HasValue)
            {
                service.StockQuantity -= 1;
            }

            await _context.SaveChangesAsync();
            await RecalculateInvoiceTotals(invoice.InvoiceId);

            return Json(new { success = true });
        }

        [HttpPost]
        public async Task<IActionResult> UpdateServiceItem([FromBody] UpdateServiceRequest request)
        {
            var detail = await _context.InvoiceDetails
                .Include(d => d.Service)
                .FirstOrDefaultAsync(d => d.InvoiceDetailId == request.InvoiceDetailId);

            if (detail == null)
            {
                return Json(new { success = false, message = "Không tìm thấy chi tiết hóa đơn." });
            }

            int diff = request.Quantity - detail.Quantity;
            if (diff > 0)
            {
                if (detail.Service.StockQuantity.HasValue && detail.Service.StockQuantity.Value < diff)
                {
                    return Json(new { success = false, message = $"Không đủ số lượng trong kho. Còn lại: {detail.Service.StockQuantity.Value}" });
                }
            }

            if (detail.Service.StockQuantity.HasValue)
            {
                detail.Service.StockQuantity -= diff;
            }

            detail.Quantity = request.Quantity;

            await _context.SaveChangesAsync();
            await RecalculateInvoiceTotals(detail.InvoiceId);

            return Json(new { success = true });
        }

        [HttpPost]
        public async Task<IActionResult> RemoveServiceItem([FromBody] RemoveServiceRequest request)
        {
            var detail = await _context.InvoiceDetails
                .Include(d => d.Service)
                .FirstOrDefaultAsync(d => d.InvoiceDetailId == request.InvoiceDetailId);

            if (detail == null)
            {
                return Json(new { success = false, message = "Không tìm thấy chi tiết hóa đơn." });
            }

            if (detail.Service.StockQuantity.HasValue)
            {
                detail.Service.StockQuantity += detail.Quantity;
            }

            int invoiceId = detail.InvoiceId;
            _context.InvoiceDetails.Remove(detail);

            await _context.SaveChangesAsync();
            await RecalculateInvoiceTotals(invoiceId);

            return Json(new { success = true });
        }

        [HttpPost]
        public async Task<IActionResult> ChangeRoom([FromBody] ChangeRoomRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Reason))
            {
                return Json(new { success = false, message = "Vui lòng nhập đầy đủ lý do đổi phòng." });
            }

            // Lấy Staff ID từ Claims
            var staffIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                             ?? User.FindFirst("AccountId")?.Value
                             ?? User.FindFirst("UserId")?.Value;

            if (!int.TryParse(staffIdClaim, out int staffId))
            {
                staffId = 1;
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var invoice = await _context.Invoices.FindAsync(request.InvoiceId);
                if (invoice == null)
                {
                    return Json(new { success = false, message = "Không tìm thấy hóa đơn." });
                }

                var oldRoom = await _context.Rooms.FindAsync(invoice.RoomId);
                var newRoom = await _context.Rooms.FindAsync(request.NewRoomId);

                if (newRoom == null)
                {
                    return Json(new { success = false, message = "Phòng mới không tồn tại." });
                }
                if (newRoom.Status != "Available")
                {
                    return Json(new { success = false, message = "Phòng mới không sẵn sàng." });
                }

                int oldRoomId = invoice.RoomId;

                //  Ghi lịch sử chuyển phòng vào RoomTransferHistory
                var transferLog = new RoomTransferHistory
                {
                    BookingId = invoice.BookingId.Value,
                    FromRoomId = oldRoomId,
                    ToRoomId = request.NewRoomId,
                    TransferredAt = DateTime.Now,
                    Reason = request.Reason,
                    ProcessedById = staffId
                };
                _context.RoomTransferHistories.Add(transferLog);

                // Cập nhật trạng thái phòng cũ
                if (oldRoom != null)
                {
                    oldRoom.Status = request.OldRoomStatus;


                    if (request.OldRoomStatus == "Maintenance")
                    {
                        var maintenanceLog = new MaintenanceLog
                        {
                            EquipmentId = 1,
                            ReportedById = staffId,
                            IssueDescription = request.Reason,
                            LogDate = DateTime.Now,
                            RepairCost = 0
                        };
                        _context.MaintenanceLogs.Add(maintenanceLog);
                    }
                }

                newRoom.Status = "InUse";
                invoice.RoomId = request.NewRoomId;

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Json(new { success = true, message = "Đổi phòng thành công." });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return Json(new { success = false, message = "Có lỗi xảy ra trong quá trình đổi phòng: " + ex.Message });
            }
        }

        [HttpPost]
        public async Task<IActionResult> ProcessPayment([FromBody] PaymentRequest request)
        {
            var invoice = await _context.Invoices
                .Include(i => i.InvoiceDetails)
                .Include(i => i.Room)
                .ThenInclude(r => r.RoomType)
                .FirstOrDefaultAsync(i => i.InvoiceId == request.InvoiceId);

            if (invoice == null)
            {
                return Json(new { success = false, message = "Không tìm thấy hóa đơn." });
            }

            var room = invoice.Room;
            invoice.CheckOutTime = DateTime.Now;

            decimal serviceTotal = invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);
            invoice.ServiceTotal = serviceTotal;

            var duration = invoice.CheckOutTime.Value - invoice.CheckInTime;
            double hours = duration.TotalHours;
            if (hours < 0) hours = 0;

            decimal roomTotal = (decimal)hours * room.RoomType.PricePerHour;
            invoice.RoomTotal = roomTotal;

            invoice.GrandTotal = roomTotal + serviceTotal - (invoice.DiscountAmount ?? 0);
            invoice.Status = "Paid";

            room.Status = "Available";

            await _context.SaveChangesAsync();

            return Json(new { success = true, message = "Thanh toán hóa đơn thành công!" });
        }

        [HttpGet]
        public async Task<IActionResult> CheckIn(int? roomId)
        {
            var availableRooms = await _context.Rooms
                .Include(r => r.RoomType)
                .Where(r => r.Status == "Available" || r.RoomId == roomId)
                .Select(r => new AvailableRoomItem
                {
                    RoomId = r.RoomId,
                    RoomName = r.RoomName,
                    TypeName = r.RoomType.TypeName,
                    PricePerHour = r.RoomType.PricePerHour
                })
                .ToListAsync();

            // Load active shift service staff
            var today = DateOnly.FromDateTime(DateTime.Today);
            var nowTime = DateTime.Now.TimeOfDay;
            var activeShift = await _context.WorkShifts
                .FirstOrDefaultAsync(s => (s.StartTime <= nowTime && s.EndTime >= nowTime) 
                                          || (s.StartTime > s.EndTime && (nowTime >= s.StartTime || nowTime <= s.EndTime)));

            var activeShiftId = activeShift?.ShiftId;

            var availableStaff = await _context.EmployeeSchedules
                .Include(s => s.Account).ThenInclude(a => a.Role)
                .Where(s => s.WorkDate == today 
                            && s.ShiftId == activeShiftId 
                            && s.IsActive 
                            && s.Status != "Off" 
                            && (s.Account.Role.RoleName.Contains("Service Staff") || s.Account.Role.RoleName.Contains("Phục vụ")))
                .Select(s => s.Account)
                .ToListAsync();

            if (!availableStaff.Any())
            {
                availableStaff = await _context.EmployeeSchedules
                    .Include(s => s.Account).ThenInclude(a => a.Role)
                    .Where(s => s.WorkDate == today 
                                && s.IsActive 
                                && s.Status != "Off" 
                                && (s.Account.Role.RoleName.Contains("Service Staff") || s.Account.Role.RoleName.Contains("Phục vụ")))
                    .Select(s => s.Account)
                    .ToListAsync();
            }

            if (!availableStaff.Any())
            {
                availableStaff = await _context.Accounts
                    .Include(a => a.Role)
                    .Where(a => a.Role.RoleName.Contains("Service Staff") || a.Role.RoleName.Contains("Phục vụ"))
                    .ToListAsync();
            }

            var currentEmployeeName = User.Identity?.Name ?? "Nguyễn Minh Anh";

            var viewModel = new CheckInViewModel
            {
                CurrentEmployeeName = currentEmployeeName,
                AvailableRooms = availableRooms,
                AvailableServiceStaff = availableStaff,
                RoomId = roomId ?? 0,
                CheckInTime = DateTime.Now
            };

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> GetCustomerByPhone(string phone)
        {
            if (string.IsNullOrWhiteSpace(phone) || !KaraokeManagement.Helpers.ValidationHelper.IsValidPhoneNumber(phone, allowGuestDefault: true))
            {
                return Json(new { found = false });
            }

            var customer = await _context.Customers
                .Include(c => c.Tier)
                .FirstOrDefaultAsync(c => c.Phone == phone);

            if (customer == null)
            {
                return Json(new { found = false });
            }

            return Json(new
            {
                found = true,
                customerId = customer.CustomerId,
                fullName = customer.FullName,
                phone = customer.Phone,
                points = customer.LoyaltyPoints ?? 0,
                tierName = customer.Tier?.TierName ?? "THƯỜNG"
            });
        }

        [HttpPost]
        public async Task<IActionResult> CreateCustomer([FromBody] CreateCustomerRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FullName))
            {
                return Json(new { success = false, message = "Họ và tên là bắt buộc." });
            }

            if (!KaraokeManagement.Helpers.ValidationHelper.IsValidPhoneNumber(request.Phone, allowGuestDefault: false))
            {
                return Json(new { success = false, message = "Số điện thoại không hợp lệ." });
            }

            var existing = await _context.Customers.FirstOrDefaultAsync(c => c.Phone == request.Phone);
            if (existing != null)
            {
                return Json(new { success = false, message = "Số điện thoại đã tồn tại." });
            }

            var defaultTier = await _context.MembershipTiers.OrderBy(t => t.MinPoints).FirstOrDefaultAsync();

            var customer = new Customer
            {
                Phone = request.Phone,
                FullName = request.FullName,
                Email = request.Email,
                LoyaltyPoints = 0,
                TierId = defaultTier?.TierId,
                CreatedAt = DateTime.Now
            };

            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();

            var tierName = defaultTier?.TierName ?? "THƯỜNG";

            return Json(new
            {
                success = true,
                customerId = customer.CustomerId,
                fullName = customer.FullName,
                phone = customer.Phone,
                points = 0,
                tierName = tierName
            });
        }

        [HttpPost]
        public async Task<IActionResult> CheckIn(CheckInViewModel model)
        {
            var room = await _context.Rooms.FindAsync(model.RoomId);
            if (room == null)
            {
                ModelState.AddModelError("", "Phòng được chọn không tồn tại.");
                model.AvailableRooms = await _context.Rooms
                    .Include(r => r.RoomType)
                    .Where(r => r.Status == "Available" || r.RoomId == model.RoomId)
                    .Select(r => new AvailableRoomItem
                    {
                        RoomId = r.RoomId,
                        RoomName = r.RoomName,
                        TypeName = r.RoomType.TypeName,
                        PricePerHour = r.RoomType.PricePerHour
                    })
                    .ToListAsync();
                
                // Reload service staff
                var today = DateOnly.FromDateTime(DateTime.Today);
                var nowTime = DateTime.Now.TimeOfDay;
                var activeShift = await _context.WorkShifts
                    .FirstOrDefaultAsync(s => (s.StartTime <= nowTime && s.EndTime >= nowTime) 
                                              || (s.StartTime > s.EndTime && (nowTime >= s.StartTime || nowTime <= s.EndTime)));

                var activeShiftId = activeShift?.ShiftId;

                var availableStaff = await _context.EmployeeSchedules
                    .Include(s => s.Account).ThenInclude(a => a.Role)
                    .Where(s => s.WorkDate == today 
                                && s.ShiftId == activeShiftId 
                                && s.IsActive 
                                && s.Status != "Off" 
                                && (s.Account.Role.RoleName.Contains("Service Staff") || s.Account.Role.RoleName.Contains("Phục vụ")))
                    .Select(s => s.Account)
                    .ToListAsync();

                if (!availableStaff.Any())
                {
                    availableStaff = await _context.EmployeeSchedules
                        .Include(s => s.Account).ThenInclude(a => a.Role)
                        .Where(s => s.WorkDate == today 
                                    && s.IsActive 
                                    && s.Status != "Off" 
                                    && (s.Account.Role.RoleName.Contains("Service Staff") || s.Account.Role.RoleName.Contains("Phục vụ")))
                        .Select(s => s.Account)
                        .ToListAsync();
                }

                if (!availableStaff.Any())
                {
                    availableStaff = await _context.Accounts
                        .Include(a => a.Role)
                        .Where(a => a.Role.RoleName.Contains("Service Staff") || a.Role.RoleName.Contains("Phục vụ"))
                        .ToListAsync();
                }

                model.AvailableServiceStaff = availableStaff;
                model.CurrentEmployeeName = User.Identity?.Name ?? "Phạm Mai (Lễ Tân ca 2)";
                return View(model);
            }

            var userName = User.Identity?.Name;
            var receptionist = await _context.Accounts.FirstOrDefaultAsync(a => a.FullName == userName || a.Username == userName);
            if (receptionist == null)
            {
                receptionist = await _context.Accounts.FirstOrDefaultAsync();
            }
            int receptionistId = receptionist?.AccountId ?? 1;

            int finalCustomerId;
            if (model.CustomerId.HasValue)
            {
                finalCustomerId = model.CustomerId.Value;
            }
            else
            {
                var guest = await _context.Customers.FirstOrDefaultAsync(c => c.Phone == "0000000000");
                if (guest == null)
                {
                    guest = new Customer
                    {
                        FullName = "Khách vãng lai",
                        Phone = "0000000000",
                        CreatedAt = DateTime.Now
                    };
                    _context.Customers.Add(guest);
                    await _context.SaveChangesAsync();
                }
                finalCustomerId = guest.CustomerId;
            }

            var booking = new Booking
            {
                CustomerId = finalCustomerId,
                RoomId = model.RoomId,
                CreatedById = receptionistId,
                StartTime = model.CheckInTime,
                EndTime = model.CheckOutTimeEstimated,
                BookingTime = DateTime.Now,
                Status = "CheckedIn"
            };
            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();

            var invoice = new Invoice
            {
                BookingId = booking.BookingId,
                RoomId = model.RoomId,
                ReceptionistId = receptionistId,
                CheckInTime = model.CheckInTime,
                Status = "Unpaid",
                RoomTotal = 0,
                ServiceTotal = 0,
                DiscountAmount = 0,
                GrandTotal = 0
            };
            _context.Invoices.Add(invoice);

            room.Status = "InUse";
            await _context.SaveChangesAsync();

            // Save room assignment directly to Booking if selected
            if (model.AssignedStaffIds != null && model.AssignedStaffIds.Any())
            {
                booking.StaffId = model.AssignedStaffIds.First();
                await _context.SaveChangesAsync();
            }

            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Checkout(int invoiceId)
        {
            var invoice = await _context.Invoices
                .Include(i => i.Room)
                    .ThenInclude(r => r.RoomType)
                .Include(i => i.InvoiceDetails)
                    .ThenInclude(id => id.Service)
                .Include(i => i.Booking)
                    .ThenInclude(b => b.Customer)
                        .ThenInclude(c => c.Tier)
                .FirstOrDefaultAsync(i => i.InvoiceId == invoiceId);

            if (invoice == null)
            {
                return NotFound("Không tìm thấy hóa đơn cần thanh toán.");
            }

            var checkInTime = invoice.CheckInTime;
            var checkOutTime = DateTime.Now;
            var duration = checkOutTime - checkInTime;
            if (duration.TotalSeconds < 0) duration = TimeSpan.Zero;

            double durationHours = duration.TotalHours;
            string durationText = $"{(int)duration.TotalHours}h {duration.Minutes}m";

            decimal pricePerHour = invoice.Room.RoomType.PricePerHour;
            decimal roomTotal = (decimal)durationHours * pricePerHour;

            decimal serviceTotal = invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);

            decimal discountPercent = invoice.Booking?.Customer?.Tier?.DiscountPercent ?? 0;
            decimal discountAmount = (roomTotal + serviceTotal) * discountPercent / 100;
            decimal grandTotal = roomTotal + serviceTotal - discountAmount;

            var orderItems = invoice.InvoiceDetails.Select(id => new CheckoutItemViewModel
            {
                ServiceName = id.Service.ServiceName,
                Quantity = id.Quantity,
                UnitPrice = id.UnitPrice,
                TotalPrice = id.Quantity * id.UnitPrice,
                Unit = id.Service.Unit
            }).ToList();

            var viewModel = new CheckoutViewModel
            {
                InvoiceId = invoice.InvoiceId,
                RoomId = invoice.RoomId,
                RoomName = invoice.Room.RoomName,
                RoomTypeName = invoice.Room.RoomType.TypeName,
                PricePerHour = pricePerHour,
                CheckInTime = checkInTime,
                CheckOutTime = checkOutTime,
                DurationHours = durationHours,
                DurationText = durationText,
                RoomTotal = roomTotal,
                ServiceTotal = serviceTotal,
                DiscountPercent = discountPercent,
                DiscountAmount = discountAmount,
                GrandTotal = grandTotal,
                CustomerName = invoice.Booking?.Customer?.FullName ?? "Khách vãng lai",
                CustomerPhone = invoice.Booking?.Customer?.Phone ?? "",
                CustomerTier = invoice.Booking?.Customer?.Tier?.TierName ?? "THƯỜNG",
                OrderItems = orderItems
            };

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> Checkout(CheckoutViewModel model)
        {
            var invoice = await _context.Invoices
                .Include(i => i.Room)
                .Include(i => i.Booking)
                .FirstOrDefaultAsync(i => i.InvoiceId == model.InvoiceId);

            if (invoice == null)
            {
                return NotFound("Không tìm thấy hóa đơn cần thanh toán.");
            }

            invoice.CheckOutTime = model.CheckOutTime;
            invoice.RoomTotal = model.RoomTotal;
            invoice.ServiceTotal = model.ServiceTotal;
            invoice.DiscountAmount = model.DiscountAmount;
            invoice.GrandTotal = model.GrandTotal;
            invoice.Status = "Paid";

            invoice.Room.Status = "Available";

            if (invoice.Booking != null)
            {
                invoice.Booking.Status = "Completed";
                invoice.Booking.EndTime = model.CheckOutTime;
            }

            await _context.SaveChangesAsync();

            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> InvoiceHistory(
            string searchString,
            string customerFilter,
            DateTime? fromDate,
            DateTime? toDate,
            string status = "All",
            int page = 1)
        {
            var query = _context.Invoices
                .Include(i => i.Room)
                .Include(i => i.Booking)
                    .ThenInclude(b => b.Customer)
                .Include(i => i.Receptionist)
                .AsQueryable();

            if (!string.IsNullOrEmpty(searchString))
            {
                var term = searchString.Trim().ToLower();
                int searchId = 0;
                string cleanTerm = term.Replace("#", "").Replace("lum-", "", StringComparison.OrdinalIgnoreCase);
                bool isNumeric = int.TryParse(cleanTerm, out searchId);

                query = query.Where(i =>
                    (isNumeric && i.InvoiceId == searchId) ||
                    (i.Booking != null && i.Booking.Customer != null && i.Booking.Customer.FullName.ToLower().Contains(term)) ||
                    (i.Receptionist != null && i.Receptionist.FullName.ToLower().Contains(term))
                );
            }

            if (!string.IsNullOrEmpty(customerFilter))
            {
                var term = customerFilter.Trim().ToLower();
                query = query.Where(i =>
                    (i.Booking != null && i.Booking.Customer != null &&
                        (i.Booking.Customer.FullName.ToLower().Contains(term) ||
                         i.Booking.Customer.Phone.Contains(term)))
                );
            }

            if (fromDate.HasValue)
            {
                query = query.Where(i => i.CheckInTime >= fromDate.Value);
            }

            if (toDate.HasValue)
            {
                var endOfDay = toDate.Value.Date.AddDays(1).AddTicks(-1);
                query = query.Where(i => i.CheckInTime <= endOfDay);
            }

            if (!string.IsNullOrEmpty(status) && status != "All" && status != "Tất cả")
            {
                query = query.Where(i => i.Status == status);
            }

            int totalCount = await query.CountAsync();
            int pageSize = 10;
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages < 1) totalPages = 1;
            if (page < 1) page = 1;
            if (page > totalPages) page = totalPages;

            var invoices = await query
                .OrderByDescending(i => i.CheckInTime)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(i => new InvoiceItemViewModel
                {
                    InvoiceId = i.InvoiceId,
                    RoomName = i.Room.RoomName,
                    CustomerName = i.Booking != null && i.Booking.Customer != null ? i.Booking.Customer.FullName : "Khách vãng lai",
                    CustomerPhone = i.Booking != null && i.Booking.Customer != null ? i.Booking.Customer.Phone : "",
                    ReceptionistName = i.Receptionist.FullName ?? "Chưa rõ",
                    CheckInTime = i.CheckInTime,
                    CheckOutTime = i.CheckOutTime,
                    TotalAmount = i.GrandTotal ?? 0,
                    Status = i.Status ?? "Unpaid"
                })
                .ToListAsync();

            var viewModel = new InvoiceHistoryViewModel
            {
                Invoices = invoices,
                SearchString = searchString ?? string.Empty,
                CustomerFilter = customerFilter ?? string.Empty,
                FromDate = fromDate,
                ToDate = toDate,
                SelectedStatus = status,
                CurrentPage = page,
                TotalPages = totalPages,
                TotalCount = totalCount,
                PageSize = pageSize
            };

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> GetInvoiceDetail(int invoiceId)
        {
            var invoice = await _context.Invoices
                .Include(i => i.Room)
                    .ThenInclude(r => r.RoomType)
                .Include(i => i.InvoiceDetails)
                    .ThenInclude(id => id.Service)
                .Include(i => i.Booking)
                    .ThenInclude(b => b.Customer)
                        .ThenInclude(c => c.Tier)
                .FirstOrDefaultAsync(i => i.InvoiceId == invoiceId);

            if (invoice == null)
            {
                return NotFound("Không tìm thấy thông tin hóa đơn.");
            }

            var checkInTime = invoice.CheckInTime;
            var checkOutTime = invoice.CheckOutTime ?? DateTime.Now;
            var duration = checkOutTime - checkInTime;
            if (duration.TotalSeconds < 0) duration = TimeSpan.Zero;

            double durationHours = duration.TotalHours;
            string durationText = $"{(int)duration.TotalHours}h {duration.Minutes}m";

            decimal pricePerHour = invoice.Room.RoomType.PricePerHour;
            decimal roomTotal = invoice.RoomTotal ?? (decimal)durationHours * pricePerHour;
            decimal serviceTotal = invoice.ServiceTotal ?? invoice.InvoiceDetails.Sum(id => id.Quantity * id.UnitPrice);

            decimal discountPercent = invoice.Booking?.Customer?.Tier?.DiscountPercent ?? 0;
            decimal discountAmount = invoice.DiscountAmount ?? (roomTotal + serviceTotal) * discountPercent / 100;
            decimal grandTotal = invoice.GrandTotal ?? (roomTotal + serviceTotal - discountAmount);

            var orderItems = invoice.InvoiceDetails.Select(id => new CheckoutItemViewModel
            {
                ServiceName = id.Service.ServiceName,
                Quantity = id.Quantity,
                UnitPrice = id.UnitPrice,
                TotalPrice = id.Quantity * id.UnitPrice,
                Unit = id.Service.Unit
            }).ToList();

            var viewModel = new CheckoutViewModel
            {
                InvoiceId = invoice.InvoiceId,
                RoomId = invoice.RoomId,
                RoomName = invoice.Room.RoomName,
                RoomTypeName = invoice.Room.RoomType.TypeName,
                PricePerHour = pricePerHour,
                CheckInTime = checkInTime,
                CheckOutTime = checkOutTime,
                DurationHours = durationHours,
                DurationText = durationText,
                RoomTotal = roomTotal,
                ServiceTotal = serviceTotal,
                DiscountPercent = discountPercent,
                DiscountAmount = discountAmount,
                GrandTotal = grandTotal,
                CustomerName = invoice.Booking?.Customer?.FullName ?? "Khách vãng lai",
                CustomerPhone = invoice.Booking?.Customer?.Phone ?? "",
                CustomerTier = invoice.Booking?.Customer?.Tier?.TierName ?? "THƯỜNG",
                OrderItems = orderItems
            };

            return PartialView("_InvoiceDetailModal", viewModel);
        }
    }


}