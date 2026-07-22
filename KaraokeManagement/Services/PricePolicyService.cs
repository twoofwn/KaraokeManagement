using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using KaraokeManagement.Models;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services
{
    public class PricePolicyService
    {
        private readonly KaraokeManagementDbContext _context;

        public PricePolicyService(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public async Task<decimal> CalculateRoomFeeAsync(int roomTypeId, DateTime startTime, DateTime endTime)
        {
            var result = await GetDetailedCalculationAsync(roomTypeId, startTime, endTime);
            return result.FinalFee;
        }

        public async Task<PricingCalculationResult> GetDetailedCalculationAsync(int roomTypeId, DateTime startTime, DateTime endTime)
        {
            var result = new PricingCalculationResult
            {
                RoomTypeId = roomTypeId,
                StartTime = startTime,
                EndTime = endTime
            };

            if (endTime <= startTime)
            {
                return result;
            }

            var roomType = await _context.RoomTypes.FirstOrDefaultAsync(rt => rt.RoomTypeId == roomTypeId);
            if (roomType == null)
            {
                return result;
            }
            result.RoomTypeName = roomType.TypeName;

            var defaultPricePerHour = roomType.PricePerHour;

            // Fetch room prices for this room type
            var allRoomPrices = await _context.RoomPrices
                .Where(rp => rp.RoomTypeId == roomTypeId)
                .OrderBy(rp => rp.StartTime)
                .ToListAsync();

            decimal totalBaseFee = 0m;
            var breakdownList = new List<FeeBreakdownItem>();

            // Loop through each day spanning from startTime to endTime
            for (var date = startTime.Date; date <= endTime.Date; date = date.AddDays(1))
            {
                var dayStart = startTime > date ? startTime : date;
                var dayEnd = endTime < date.AddDays(1) ? endTime : date.AddDays(1);

                if (dayEnd <= dayStart)
                    continue;

                // Active prices for this specific date
                var activePrices = allRoomPrices
                    .Where(rp => (rp.EffectiveFrom == null || rp.EffectiveFrom <= date) &&
                                 (rp.EffectiveTo == null || rp.EffectiveTo >= date))
                    .ToList();

                if (!activePrices.Any())
                {
                    // Fallback to default room type price
                    double hours = (dayEnd - dayStart).TotalHours;
                    decimal amount = (decimal)hours * defaultPricePerHour;
                    totalBaseFee += amount;
                    breakdownList.Add(new FeeBreakdownItem
                    {
                        StartTime = dayStart,
                        EndTime = dayEnd,
                        Hours = hours,
                        PricePerHour = defaultPricePerHour,
                        Amount = amount,
                        TimeSlotDescription = "Mặc định (Toàn thời gian)"
                    });
                }
                else
                {
                    // Track coverage of dayStart to dayEnd
                    var currentPointer = dayStart;

                    foreach (var rp in activePrices)
                    {
                        if (currentPointer >= dayEnd)
                            break;

                        var slotStart = date.Add(rp.StartTime);
                        DateTime slotEnd;

                        if (rp.EndTime == TimeSpan.Zero || rp.EndTime < rp.StartTime || rp.EndTime >= new TimeSpan(23, 59, 59))
                        {
                            slotEnd = date.AddDays(1);
                        }
                        else
                        {
                            slotEnd = date.Add(rp.EndTime);
                        }

                        // Gap before slot
                        if (currentPointer < slotStart && currentPointer < dayEnd)
                        {
                            var gapEnd = dayEnd < slotStart ? dayEnd : slotStart;
                            if (gapEnd > currentPointer)
                            {
                                double gapHours = (gapEnd - currentPointer).TotalHours;
                                decimal gapAmount = (decimal)gapHours * defaultPricePerHour;
                                totalBaseFee += gapAmount;
                                breakdownList.Add(new FeeBreakdownItem
                                {
                                    StartTime = currentPointer,
                                    EndTime = gapEnd,
                                    Hours = gapHours,
                                    PricePerHour = defaultPricePerHour,
                                    Amount = gapAmount,
                                    TimeSlotDescription = "Tiêu chuẩn (Ngoài khung giờ)"
                                });
                                currentPointer = gapEnd;
                            }
                        }

                        // Overlap with slot
                        var overlapStart = currentPointer > slotStart ? currentPointer : slotStart;
                        var overlapEnd = dayEnd < slotEnd ? dayEnd : slotEnd;

                        if (overlapEnd > overlapStart)
                        {
                            double hours = (overlapEnd - overlapStart).TotalHours;
                            decimal amount = (decimal)hours * rp.PricePerHour;
                            totalBaseFee += amount;
                            breakdownList.Add(new FeeBreakdownItem
                            {
                                StartTime = overlapStart,
                                EndTime = overlapEnd,
                                Hours = hours,
                                PricePerHour = rp.PricePerHour,
                                Amount = amount,
                                TimeSlotDescription = $"{rp.StartTime:hh\\:mm} - {rp.EndTime:hh\\:mm}"
                            });
                            currentPointer = overlapEnd;
                        }
                    }

                    // Remaining gap after active prices
                    if (currentPointer < dayEnd)
                    {
                        double remainingHours = (dayEnd - currentPointer).TotalHours;
                        decimal remainingAmount = (decimal)remainingHours * defaultPricePerHour;
                        totalBaseFee += remainingAmount;
                        breakdownList.Add(new FeeBreakdownItem
                        {
                            StartTime = currentPointer,
                            EndTime = dayEnd,
                            Hours = remainingHours,
                            PricePerHour = defaultPricePerHour,
                            Amount = remainingAmount,
                            TimeSlotDescription = "Tiêu chuẩn (Ngoài khung giờ)"
                        });
                    }
                }
            }

            result.BaseFee = totalBaseFee;
            result.BreakdownItems = breakdownList;

            // Check Weekend & Holiday Surcharges for the primary booking day (startTime.Date)
            var checkDate = startTime.Date;

            // 1. Weekend Surcharge Check
            if (checkDate.DayOfWeek == DayOfWeek.Saturday || checkDate.DayOfWeek == DayOfWeek.Sunday)
            {
                var weekendPolicy = await _context.PricingPolicies
                    .FirstOrDefaultAsync(p => p.PolicyType == "Weekend" && p.IsActive);
                if (weekendPolicy != null)
                {
                    result.WeekendSurchargePercent = weekendPolicy.Value;
                    result.WeekendPolicyName = weekendPolicy.PolicyName;
                }
            }

            // 2. Holiday Surcharge Check
            var holiday = await _context.Holidays
                .FirstOrDefaultAsync(h => h.HolidayDate == checkDate && h.IsActive);
            if (holiday != null)
            {
                if (holiday.SurchargePercent != 0)
                {
                    result.HolidaySurchargePercent = holiday.SurchargePercent;
                    result.HolidayName = holiday.HolidayName;
                }
                else
                {
                    var holidayPolicy = await _context.PricingPolicies
                        .FirstOrDefaultAsync(p => p.PolicyType == "Holiday" && p.IsActive);
                    if (holidayPolicy != null)
                    {
                        result.HolidaySurchargePercent = holidayPolicy.Value;
                        result.HolidayName = $"{holiday.HolidayName} ({holidayPolicy.PolicyName})";
                    }
                    else
                    {
                        result.HolidayName = holiday.HolidayName;
                    }
                }
            }

            result.TotalSurchargePercent = result.WeekendSurchargePercent + result.HolidaySurchargePercent;
            result.SurchargeAmount = result.BaseFee * (result.TotalSurchargePercent / 100m);
            result.TotalFeeBeforeRounding = result.BaseFee + result.SurchargeAmount;

            // Round to nearest 1,000 VND
            result.FinalFee = Math.Round(result.TotalFeeBeforeRounding / 1000m, MidpointRounding.AwayFromZero) * 1000m;

            return result;
        }
    }
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
}

