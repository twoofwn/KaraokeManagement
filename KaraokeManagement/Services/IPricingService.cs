using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace KaraokeManagement.Services
{
    public class FeeBreakdownItem
    {
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public double Hours { get; set; }
        public decimal PricePerHour { get; set; }
        public decimal Amount { get; set; }
        public string TimeSlotDescription { get; set; } = string.Empty;
    }

    public class PricingCalculationResult
    {
        public int RoomTypeId { get; set; }
        public string RoomTypeName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public decimal BaseFee { get; set; }
        public decimal WeekendSurchargePercent { get; set; }
        public string? WeekendPolicyName { get; set; }
        public decimal HolidaySurchargePercent { get; set; }
        public string? HolidayName { get; set; }
        public decimal TotalSurchargePercent { get; set; }
        public decimal SurchargeAmount { get; set; }
        public decimal TotalFeeBeforeRounding { get; set; }
        public decimal FinalFee { get; set; }
        public List<FeeBreakdownItem> BreakdownItems { get; set; } = new();
    }

    public interface IPricingService
    {
        Task<decimal> CalculateRoomFeeAsync(int roomTypeId, DateTime startTime, DateTime endTime);
        Task<PricingCalculationResult> GetDetailedCalculationAsync(int roomTypeId, DateTime startTime, DateTime endTime);
    }
}
