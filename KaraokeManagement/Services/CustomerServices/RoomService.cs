using KaraokeManagement.Models;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.CustomerServices
{
    public class RoomService
    {
        private readonly KaraokeManagementDbContext _context;
        public RoomService(KaraokeManagementDbContext context) { _context = context; }

        public async Task<List<RoomType>> GetFilteredRoomTypesAsync(string searchString, decimal? minPrice, decimal? maxPrice, string sortOrder)
        {
            var query = _context.RoomTypes.Include(rt => rt.RoomImages).AsQueryable();

            if (!string.IsNullOrEmpty(searchString))
                query = query.Where(r => r.TypeName.Contains(searchString));
            if (minPrice.HasValue)
                query = query.Where(r => r.PricePerHour >= minPrice.Value);
            if (maxPrice.HasValue)
                query = query.Where(r => r.PricePerHour <= maxPrice.Value);

            query = sortOrder switch
            {
                "price-asc" => query.OrderBy(r => r.PricePerHour),
                "price-desc" => query.OrderByDescending(r => r.PricePerHour),
                _ => query.OrderBy(r => r.TypeName)
            };

            return await query.ToListAsync();
        }

        public async Task<RoomType> GetRoomTypeDetailAsync(int id)
        {
            return await _context.RoomTypes.Include(rt => rt.Rooms).Include(rt => rt.RoomPrices).Include(rt => rt.RoomImages).FirstOrDefaultAsync(rt => rt.RoomTypeId == id);
        }

        public async Task<List<PricingPolicy>> GetActivePricingPoliciesAsync()
        {
            return await _context.PricingPolicies.Where(p => p.IsActive).ToListAsync();
        }
    }
}
