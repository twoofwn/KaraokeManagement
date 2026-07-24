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
            var (basePrice, priceBreakdowns) = CalculateBasePriceAndBreakdown(roomTypeObj, startDateTime, endDateTime, duration);
            var (surchargeAmount, surchargeNote) = await CalculateSurchargeAsync(startDateTime, basePrice);

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
                EstimatedTotalPrice = basePrice + surchargeAmount,
                PriceBreakdowns = priceBreakdowns
            };
        }

        private (decimal BasePrice, List<PriceBreakdownItem> Breakdowns) CalculateBasePriceAndBreakdown(RoomType roomTypeObj, DateTime startDateTime, DateTime endDateTime, int duration)
        {
            decimal basePrice = 0;
            var priceBreakdowns = new List<PriceBreakdownItem>();
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

                    var hoursInBlock = (decimal)(nextBlockEnd - currentCalcTime).TotalMinutes / 60m;
                    var blockPrice = hoursInBlock * currentRate;

                    basePrice += blockPrice;

                    priceBreakdowns.Add(new PriceBreakdownItem { TimeRange = $"{currentCalcTime:HH:mm} - {nextBlockEnd:HH:mm}", DurationHours = hoursInBlock, PricePerHour = currentRate, TotalPrice = blockPrice });
                    currentCalcTime = nextBlockEnd;
                }
            }
            else
            {
                decimal hours = duration / 60m;
                basePrice = hours * fallbackPrice;
                priceBreakdowns.Add(new PriceBreakdownItem { TimeRange = $"{startDateTime:HH:mm} - {endDateTime:HH:mm}", DurationHours = hours, PricePerHour = fallbackPrice, TotalPrice = basePrice });
            }

            return (basePrice, priceBreakdowns);
        }

        private async Task<(decimal SurchargeAmount, string SurchargeNote)> CalculateSurchargeAsync(DateTime startDateTime, decimal basePrice)
        {
            var holiday = await _context.Holidays.FirstOrDefaultAsync(h => h.IsActive && h.HolidayDate.Date == startDateTime.Date);

            if (holiday != null) return (basePrice * (holiday.SurchargePercent / 100m), $"{holiday.HolidayName} ({holiday.SurchargePercent.ToString("0.##")}%)");

            if (startDateTime.DayOfWeek == DayOfWeek.Saturday || startDateTime.DayOfWeek == DayOfWeek.Sunday)
            {
                var weekendPolicy = await _context.PricingPolicies.FirstOrDefaultAsync(p => p.IsActive && p.PolicyType == "Weekend");
                if (weekendPolicy != null) return (basePrice * (weekendPolicy.Value / 100m), $"{weekendPolicy.PolicyName} ({weekendPolicy.Value.ToString("0.##")}%)");
            }

            return (0, "");
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
