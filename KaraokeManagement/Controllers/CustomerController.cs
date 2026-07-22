using KaraokeManagement.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Controllers
{
    public class CustomerController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        // Tiêm DbContext vào Controller
        public CustomerController(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpGet]
        public IActionResult Rooms(string searchString, decimal? minPrice, decimal? maxPrice, string sortOrder)
        {
            // Lưu lại các giá trị lọc vào ViewBag để hiển thị lại lên form sau khi load
            ViewBag.SearchString = searchString;
            ViewBag.MinPrice = minPrice;
            ViewBag.MaxPrice = maxPrice;
            ViewBag.SortOrder = sortOrder;

            // Truy vấn lấy dữ liệu RoomType
            var roomTypes = _context.RoomTypes.AsQueryable();

            // 1. Lọc theo tên phòng
            if (!string.IsNullOrEmpty(searchString))
            {
                roomTypes = roomTypes.Where(r => r.TypeName.Contains(searchString));
            }

            // 2. Lọc theo giá thấp nhất
            if (minPrice.HasValue)
            {
                roomTypes = roomTypes.Where(r => r.PricePerHour >= minPrice.Value);
            }

            // 3. Lọc theo giá cao nhất
            if (maxPrice.HasValue)
            {
                roomTypes = roomTypes.Where(r => r.PricePerHour <= maxPrice.Value);
            }

            // 4. Sắp xếp
            switch (sortOrder)
            {
                case "price-asc":
                    roomTypes = roomTypes.OrderBy(r => r.PricePerHour);
                    break;
                case "price-desc":
                    roomTypes = roomTypes.OrderByDescending(r => r.PricePerHour);
                    break;
                default:
                    roomTypes = roomTypes.OrderBy(r => r.TypeName); // Mặc định sắp xếp theo tên
                    break;
            }

            // Trả về view danh sách RoomType
            return View(roomTypes.ToList());
        }

        [HttpGet]
        public IActionResult RoomDetail(int id)
        {
            var roomType = _context.RoomTypes
                .Include(rt => rt.Rooms)
                .Include(rt => rt.RoomPrices)
                .FirstOrDefault(rt => rt.RoomTypeId == id);

            if (roomType == null)
            {
                return NotFound();
            }

            // Lấy danh sách các chính sách phụ thu đang hoạt động
            ViewBag.ActivePolicies = _context.PricingPolicies
                .Where(p => p.IsActive)
                .ToList();

            return View(roomType);
        }

        [HttpGet]
        public IActionResult Services(string searchString, int? categoryId, decimal? minPrice, decimal? maxPrice, string sortOrder)
        {
            // Lưu lại state để hiển thị lại trên form
            ViewBag.SearchString = searchString;
            ViewBag.CategoryId = categoryId;
            ViewBag.MinPrice = minPrice;
            ViewBag.MaxPrice = maxPrice;
            ViewBag.SortOrder = sortOrder;

            // Truyền danh sách Category ra View để làm thẻ Select Dropdown
            ViewBag.Categories = _context.Categories.ToList();

            // Khởi tạo query lấy ServiceItem kèm theo Category
            var services = _context.ServiceItems.Include(s => s.Category).AsQueryable();

            // 1. Lọc theo từ khóa (Tên dịch vụ)
            if (!string.IsNullOrEmpty(searchString))
            {
                services = services.Where(s => s.ServiceName.Contains(searchString));
            }

            // 2. Lọc theo danh mục
            if (categoryId.HasValue)
            {
                services = services.Where(s => s.CategoryId == categoryId.Value);
            }

            // 3. Lọc theo giá Min/Max
            if (minPrice.HasValue)
            {
                services = services.Where(s => s.SellingPrice >= minPrice.Value);
            }
            if (maxPrice.HasValue)
            {
                services = services.Where(s => s.SellingPrice <= maxPrice.Value);
            }

            // 4. Sắp xếp
            switch (sortOrder)
            {
                case "price-asc":
                    services = services.OrderBy(s => s.SellingPrice);
                    break;
                case "price-desc":
                    services = services.OrderByDescending(s => s.SellingPrice);
                    break;
                case "name-asc":
                    services = services.OrderBy(s => s.ServiceName);
                    break;
                case "name-desc":
                    services = services.OrderByDescending(s => s.ServiceName);
                    break;
                default:
                    services = services.OrderBy(s => s.ServiceName);
                    break;
            }

            return View(services.ToList());
        }

        [HttpGet]
        public IActionResult ServiceDetail(int id)
        {
            // Lấy thông tin dịch vụ hiện tại, kèm theo Category
            var service = _context.ServiceItems
                .Include(s => s.Category)
                .FirstOrDefault(s => s.ServiceId == id);

            if (service == null)
            {
                return NotFound(); // Trả về 404 nếu không tìm thấy ID
            }

            // Lấy các dịch vụ gợi ý (cùng danh mục, nhưng khác dịch vụ hiện tại) - Lấy tối đa 5 cái
            var suggestedServices = _context.ServiceItems
                .Include(s => s.Category)
                .Where(s => s.CategoryId == service.CategoryId && s.ServiceId != id)
                .Take(5)
                .ToList();

            // Truyền danh sách gợi ý qua ViewBag
            ViewBag.SuggestedServices = suggestedServices;

            // Trả Model ServiceItem ra View
            return View(service);
        }

        [HttpGet]
        public IActionResult BookingConfirmation(string roomName, string typeName, string bookingDate, string startTime, int duration)
        {
            // Truyền dữ liệu sang View thông qua ViewBag
            ViewBag.RoomName = roomName;
            ViewBag.TypeName = typeName;
            ViewBag.BookingDate = bookingDate;
            ViewBag.StartTime = startTime;
            ViewBag.Duration = duration;

            return View();
        }
    }
}
