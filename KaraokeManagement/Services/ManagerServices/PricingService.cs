using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.ManagerServices
{
    public class PricingService
    {
        private readonly KaraokeManagementDbContext _context;

        public PricingService(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public async Task<DynamicPricingViewModel> GetDynamicPricingViewModelAsync(string tab)
        {
            return new DynamicPricingViewModel
            {
                RoomPrices = await _context.RoomPrices.Include(rp => rp.RoomType)
                                .OrderBy(rp => rp.RoomTypeId).ThenBy(rp => rp.StartTime).ToListAsync(),
                PricingPolicies = await _context.PricingPolicies.OrderBy(p => p.PolicyType).ToListAsync(),
                Holidays = await _context.Holidays.OrderBy(h => h.HolidayDate).ToListAsync(),
                RoomTypes = await _context.RoomTypes.OrderBy(rt => rt.TypeName).ToListAsync(),
                ActiveTab = tab
            };
        }

        // ================= ROOM PRICE =================
        public async Task CreateRoomPriceAsync(int roomTypeId, TimeSpan startTime, TimeSpan endTime, decimal pricePerHour, DateTime? effectiveFrom, DateTime? effectiveTo)
        {
            _context.RoomPrices.Add(new RoomPrice
            {
                RoomTypeId = roomTypeId,
                StartTime = startTime,
                EndTime = endTime,
                PricePerHour = pricePerHour,
                EffectiveFrom = effectiveFrom,
                EffectiveTo = effectiveTo
            });
            await _context.SaveChangesAsync();
        }

        public async Task EditRoomPriceAsync(int priceId, int roomTypeId, TimeSpan startTime, TimeSpan endTime, decimal pricePerHour, DateTime? effectiveFrom, DateTime? effectiveTo)
        {
            var existing = await _context.RoomPrices.FindAsync(priceId);
            if (existing != null)
            {
                existing.RoomTypeId = roomTypeId; existing.StartTime = startTime; existing.EndTime = endTime;
                existing.PricePerHour = pricePerHour; existing.EffectiveFrom = effectiveFrom; existing.EffectiveTo = effectiveTo;
                await _context.SaveChangesAsync();
            }
        }

        public async Task DeleteRoomPriceAsync(int priceId)
        {
            var existing = await _context.RoomPrices.FindAsync(priceId);
            if (existing != null)
            {
                _context.RoomPrices.Remove(existing);
                await _context.SaveChangesAsync();
            }
        }
        public async Task CreatePricingPolicyAsync(string policyName, string policyType, decimal value, bool isActive)
        {
            _context.PricingPolicies.Add(new PricingPolicy
            {
                PolicyName = policyName,
                PolicyType = policyType,
                Value = value,
                IsActive = isActive
            });
            await _context.SaveChangesAsync();
        }

        public async Task EditPricingPolicyAsync(int policyId, string policyName, string policyType, decimal value, bool isActive)
        {
            var existing = await _context.PricingPolicies.FindAsync(policyId);
            if (existing != null)
            {
                existing.PolicyName = policyName; existing.PolicyType = policyType;
                existing.Value = value; existing.IsActive = isActive;
                await _context.SaveChangesAsync();
            }
        }

        public async Task TogglePricingPolicyAsync(int policyId)
        {
            var existing = await _context.PricingPolicies.FindAsync(policyId);
            if (existing != null)
            {
                existing.IsActive = !existing.IsActive;
                await _context.SaveChangesAsync();
            }
        }

        public async Task DeletePricingPolicyAsync(int policyId)
        {
            var existing = await _context.PricingPolicies.FindAsync(policyId);
            if (existing != null)
            {
                _context.PricingPolicies.Remove(existing);
                await _context.SaveChangesAsync();
            }
        }
        public async Task CreateHolidayAsync(string holidayName, DateTime holidayDate, decimal surchargePercent, bool isActive)
        {
            _context.Holidays.Add(new Holiday
            {
                HolidayName = holidayName,
                HolidayDate = holidayDate,
                SurchargePercent = surchargePercent,
                IsActive = isActive
            });
            await _context.SaveChangesAsync();
        }

        public async Task EditHolidayAsync(int holidayId, string holidayName, DateTime holidayDate, decimal surchargePercent, bool isActive)
        {
            var existing = await _context.Holidays.FindAsync(holidayId);
            if (existing != null)
            {
                existing.HolidayName = holidayName; existing.HolidayDate = holidayDate;
                existing.SurchargePercent = surchargePercent; existing.IsActive = isActive;
                await _context.SaveChangesAsync();
            }
        }

        public async Task ToggleHolidayAsync(int holidayId)
        {
            var existing = await _context.Holidays.FindAsync(holidayId);
            if (existing != null)
            {
                existing.IsActive = !existing.IsActive;
                await _context.SaveChangesAsync();
            }
        }

        public async Task DeleteHolidayAsync(int holidayId)
        {
            var existing = await _context.Holidays.FindAsync(holidayId);
            if (existing != null)
            {
                _context.Holidays.Remove(existing);
                await _context.SaveChangesAsync();
            }
        }
    }
}
