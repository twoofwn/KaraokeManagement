using System.Collections.Generic;
using KaraokeManagement.Models;

namespace KaraokeManagement.ViewModel
{
    public class DynamicPricingViewModel
    {
        public List<RoomPrice> RoomPrices { get; set; } = new();
        public List<PricingPolicy> PricingPolicies { get; set; } = new();
        public List<Holiday> Holidays { get; set; } = new();
        public List<RoomType> RoomTypes { get; set; } = new();

        public string ActiveTab { get; set; } = "prices";
    }
}
