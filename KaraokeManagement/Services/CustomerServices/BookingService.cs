using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.CustomerServices
{
    public class BookingService
    {
        private readonly KaraokeManagementDbContext _context;
        public BookingService(KaraokeManagementDbContext context) { _context = context; }

        public async Task<bool> CheckAvailabilityAsync(int roomId, DateTime startDateTime, DateTime endDateTime)
        {
            return !await _context.Bookings.AnyAsync(b =>
                b.RoomId == roomId &&
                b.Status != "Cancelled" && b.Status != "Đã hủy" &&
                b.StartTime < endDateTime &&
                (b.EndTime == null || b.EndTime > startDateTime));
        }

        public async Task<BookingConfirmationViewModel> CalculateBookingConfirmationAsync(Customer customer, string roomName, string typeName, DateTime startDateTime, int duration)
        {
            DateTime endDateTime = startDateTime.AddMinutes(duration);
            var roomTypeObj = await _context.RoomTypes.Include(rt => rt.RoomPrices).FirstOrDefaultAsync(rt => rt.TypeName == typeName);
            decimal basePrice = 0;
            decimal fallbackPrice = roomTypeObj?.PricePerHour ?? 0;

            if (roomTypeObj != null && roomTypeObj.RoomPrices.Any())
            {
                DateTime currentCalcTime = startDateTime;
                while (currentCalcTime < endDateTime)
                {
                    var timeOfDay = currentCalcTime.TimeOfDay;
                    var activePrice = roomTypeObj.RoomPrices.FirstOrDefault(p => p.StartTime <= timeOfDay && p.EndTime > timeOfDay);
                    decimal currentRate = activePrice?.PricePerHour ?? fallbackPrice;
                    DateTime nextBlockEnd = activePrice != null ? currentCalcTime.Date.Add(activePrice.EndTime) : currentCalcTime.Date.AddDays(1);
                    if (nextBlockEnd > endDateTime) nextBlockEnd = endDateTime;
                    var minutesInBlock = (decimal)(nextBlockEnd - currentCalcTime).TotalMinutes;
                    basePrice += (minutesInBlock / 60m) * currentRate;
                    currentCalcTime = nextBlockEnd;
                }
            }
            else { basePrice = (duration / 60m) * fallbackPrice; }

            decimal surchargeAmount = 0;
            string surchargeNote = "";
            if (startDateTime.DayOfWeek == DayOfWeek.Saturday || startDateTime.DayOfWeek == DayOfWeek.Sunday)
            {
                var weekendPolicy = await _context.PricingPolicies.FirstOrDefaultAsync(p => p.IsActive && p.PolicyType == "Weekend");
                if (weekendPolicy != null)
                {
                    surchargeAmount = basePrice * (weekendPolicy.Value / 100m);
                    surchargeNote = $"{weekendPolicy.PolicyName} ({weekendPolicy.Value.ToString("0.##")}%)";
                }
            }

            return new BookingConfirmationViewModel
            {
                CustomerName = customer.FullName,
                Phone = customer.Phone,
                Email = customer.Email,
                RoomName = roomName,
                TypeName = typeName,
                BookingDate = startDateTime.ToString("yyyy-MM-dd"),
                StartTime = startDateTime.ToString("HH:mm"),
                Duration = duration,
                BasePrice = basePrice,
                SurchargeAmount = surchargeAmount,
                SurchargeNote = surchargeNote,
                EstimatedTotalPrice = basePrice + surchargeAmount
            };
        }

        public async Task<(bool Success, string Message)> ConfirmAndSaveBookingAsync(Booking booking, int customerId)
        {
            booking.CustomerId = customerId;
            booking.BookingTime = DateTime.Now;
            booking.Status = "Pending";
            if (booking.GuestCount <= 0) booking.GuestCount = 2;

            var adminAccount = await _context.Accounts.FirstOrDefaultAsync();
            booking.CreatedById = adminAccount != null ? adminAccount.AccountId : 1;

            bool isConflict = await CheckAvailabilityAsync(booking.RoomId, booking.StartTime, booking.EndTime ?? booking.StartTime.AddHours(1));
            if (!isConflict) return (false, "Rất tiếc! Phòng này vừa được khách khác đặt.");

            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();
            return (true, "Thành công");
        }

        public async Task<List<Booking>> GetCustomerBookingsAsync(int customerId)
        {
            return await _context.Bookings
                .Where(b => b.CustomerId == customerId)
                .Include(b => b.Room).ThenInclude(r => r.RoomType)
                .Include(b => b.Invoices)
                .OrderByDescending(b => b.StartTime)
                .ToListAsync();
        }

        public async Task<Booking> GetBookingDetailAsync(int bookingId, int customerId)
        {
            return await _context.Bookings
                .Include(b => b.Room).ThenInclude(r => r.RoomType)
                .Include(b => b.Invoices).ThenInclude(i => i.InvoiceDetails).ThenInclude(d => d.Service)
                .Include(b => b.Invoices).ThenInclude(i => i.PaymentTransactions)
                .FirstOrDefaultAsync(b => b.BookingId == bookingId && b.CustomerId == customerId);
        }
    }
}
