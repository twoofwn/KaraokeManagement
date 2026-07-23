using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.ManagerServices
{
    public class InventoryService
    {
        private readonly KaraokeManagementDbContext _context;

        public InventoryService(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public async Task<List<Supplier>> GetAllSuppliersAsync() => await _context.Suppliers.ToListAsync();

        public async Task<object> SearchServicesAsync(string term)
        {
            var query = _context.ServiceItems.AsQueryable();
            if (!string.IsNullOrWhiteSpace(term)) query = query.Where(s => s.ServiceName.Contains(term));

            return await query
                .Select(s => new { s.ServiceId, s.ServiceName, s.Unit })
                .Take(15)
                .ToListAsync();
        }

        public async Task<InventoryViewModel> GetInventoryAsync()
        {
            var items = await _context.ServiceItems.Include(s => s.Category).ToListAsync();

            var latestPrices = await _context.PurchaseOrderDetails
                .Include(pod => pod.Po)
                .GroupBy(pod => pod.ServiceId)
                .Select(g => new
                {
                    ServiceId = g.Key,
                    LatestPrice = g.OrderByDescending(pod => pod.Po.OrderDate).Select(pod => pod.ImportPrice).FirstOrDefault()
                })
                .ToDictionaryAsync(x => x.ServiceId, x => x.LatestPrice);

            var vmItems = items.Select(item => new InventoryItemViewModel
            {
                ServiceId = item.ServiceId,
                ServiceName = item.ServiceName,
                CategoryName = item.Category.CategoryName,
                SellingPrice = item.SellingPrice,
                Unit = item.Unit,
                StockQuantity = item.StockQuantity ?? 0,
                ImportPrice = latestPrices.GetValueOrDefault(item.ServiceId, 0),
                Status = (item.StockQuantity ?? 0) <= 0 ? "Out of Stock" : (item.StockQuantity <= 10 ? "Low Stock" : "In Stock")
            }).ToList();

            return new InventoryViewModel
            {
                Items = vmItems,
                TotalValue = vmItems.Sum(x => x.StockQuantity * x.ImportPrice),
                LowStockCount = vmItems.Count(x => x.Status == "Low Stock"),
                ActiveCategoriesCount = await _context.Categories.CountAsync(),
                Categories = await _context.Categories.ToListAsync()
            };
        }

        public async Task<(bool Success, string Message)> SaveStockInAsync(StockInRequestModel model, int adminId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var po = new PurchaseOrder
                {
                    SupplierId = model.SupplierId,
                    OrderDate = model.OrderDate,
                    CreatedById = adminId,
                    TotalAmount = model.Items.Sum(i => i.Quantity * i.ImportPrice)
                };

                _context.PurchaseOrders.Add(po);
                await _context.SaveChangesAsync();

                foreach (var item in model.Items)
                {
                    _context.PurchaseOrderDetails.Add(new PurchaseOrderDetail
                    {
                        PoId = po.PoId,
                        ServiceId = item.ServiceId,
                        Quantity = item.Quantity,
                        ImportPrice = item.ImportPrice
                    });

                    var service = await _context.ServiceItems.FindAsync(item.ServiceId);
                    if (service != null)
                        service.StockQuantity = (service.StockQuantity ?? 0) + item.Quantity;
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return (true, "Lưu phiếu nhập thành công!");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return (false, "Có lỗi xảy ra: " + ex.Message);
            }
        }

        // ================= CÁC HÀM IMPLEMENT NỐT ================= //

        public async Task<(bool Success, string Message)> UpdateStockInAsync(UpdateStockInRequestModel model)
        {
            if (model == null || !model.Items.Any())
            {
                return (false, "Vui lòng thêm ít nhất 1 sản phẩm.");
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var existingPo = await _context.PurchaseOrders
                    .Include(p => p.PurchaseOrderDetails)
                    .FirstOrDefaultAsync(p => p.PoId == model.PoId);

                if (existingPo == null)
                    return (false, "Không tìm thấy phiếu nhập.");

                // 1. Hoàn trả Tồn kho cũ (Trừ đi số lượng đã nhập lúc trước)
                foreach (var oldItem in existingPo.PurchaseOrderDetails)
                {
                    var service = await _context.ServiceItems.FindAsync(oldItem.ServiceId);
                    if (service != null)
                    {
                        service.StockQuantity = (service.StockQuantity ?? 0) - oldItem.Quantity;
                    }
                }

                // 2. Xóa chi tiết phiếu cũ
                _context.PurchaseOrderDetails.RemoveRange(existingPo.PurchaseOrderDetails);

                // 3. Cập nhật thông tin phiếu nhập
                existingPo.SupplierId = model.SupplierId;
                existingPo.OrderDate = model.OrderDate;
                existingPo.TotalAmount = model.Items.Sum(i => i.Quantity * i.ImportPrice);

                // 4. Thêm chi tiết mới và Cập nhật Tồn kho mới
                foreach (var item in model.Items)
                {
                    var detail = new PurchaseOrderDetail
                    {
                        PoId = existingPo.PoId,
                        ServiceId = item.ServiceId,
                        Quantity = item.Quantity,
                        ImportPrice = item.ImportPrice
                    };
                    _context.PurchaseOrderDetails.Add(detail);

                    // Cộng thêm số lượng mới
                    var service = await _context.ServiceItems.FindAsync(item.ServiceId);
                    if (service != null)
                    {
                        service.StockQuantity = (service.StockQuantity ?? 0) + item.Quantity;
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return (true, "Cập nhật phiếu nhập thành công!");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return (false, "Có lỗi xảy ra: " + ex.Message);
            }
        }

        public async Task<(bool Success, string Message)> AddInventoryItemAsync(string serviceName, int categoryId, decimal sellingPrice, string unit, int stockQuantity, decimal importPrice, int adminId)
        {
            if (string.IsNullOrWhiteSpace(serviceName)) return (false, "Tên sản phẩm không được để trống.");
            if (sellingPrice < 0) return (false, "Giá bán không được nhỏ hơn 0.");
            if (stockQuantity < 0) return (false, "Số lượng tồn kho không được nhỏ hơn 0.");
            if (importPrice < 0) return (false, "Giá nhập không được nhỏ hơn 0.");

            bool exists = await _context.ServiceItems.AnyAsync(s => s.ServiceName.ToLower() == serviceName.ToLower() && s.CategoryId == categoryId);
            if (exists) return (false, "Sản phẩm này đã tồn tại trong danh mục này.");

            var newItem = new ServiceItem { ServiceName = serviceName, CategoryId = categoryId, SellingPrice = sellingPrice, Unit = unit, StockQuantity = stockQuantity };

            _context.ServiceItems.Add(newItem);
            await _context.SaveChangesAsync();

            if (stockQuantity > 0 && importPrice > 0)
            {
                var defaultSupplier = await _context.Suppliers.FirstOrDefaultAsync();
                int supplierId = defaultSupplier?.SupplierId ?? 1;

                var po = new PurchaseOrder { SupplierId = supplierId, CreatedById = adminId, OrderDate = DateTime.Now, TotalAmount = stockQuantity * importPrice };
                _context.PurchaseOrders.Add(po);
                await _context.SaveChangesAsync();

                var pod = new PurchaseOrderDetail
                {
                    PoId = po.PoId,
                    ServiceId = newItem.ServiceId,
                    ImportPrice = importPrice,
                    Quantity = stockQuantity
                };
                _context.PurchaseOrderDetails.Add(pod);
                await _context.SaveChangesAsync();
            }

            return (true, "Thêm hàng mới thành công!");
        }

        public async Task<ImportHistoryViewModel> GetImportHistoryAsync(int? supplierId, string? timeFilter, int page, int pageSize = 10)
        {
            var now = DateTime.Now;
            var startOfCurrentMonth = new DateTime(now.Year, now.Month, 1);
            var endOfCurrentMonth = startOfCurrentMonth.AddMonths(1).AddTicks(-1);

            var startOfLastMonth = startOfCurrentMonth.AddMonths(-1);
            var endOfLastMonth = startOfCurrentMonth.AddTicks(-1);

            // 1. Tính toán thống kê chung
            var currentMonthTotal = await _context.PurchaseOrders
                .Where(po => po.OrderDate >= startOfCurrentMonth && po.OrderDate <= endOfCurrentMonth)
                .SumAsync(po => po.TotalAmount ?? 0);

            var lastMonthTotal = await _context.PurchaseOrders
                .Where(po => po.OrderDate >= startOfLastMonth && po.OrderDate <= endOfLastMonth)
                .SumAsync(po => po.TotalAmount ?? 0);

            double percentChange = 0;
            if (lastMonthTotal > 0)
            {
                percentChange = (double)((currentMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
            }
            else if (currentMonthTotal > 0)
            {
                percentChange = 100;
            }

            var totalOrdersCount = await _context.PurchaseOrders.CountAsync();

            // 2. Query và bộ lọc
            var query = _context.PurchaseOrders
                .Include(po => po.Supplier)
                .AsQueryable();

            if (supplierId.HasValue && supplierId.Value > 0)
            {
                query = query.Where(po => po.SupplierId == supplierId.Value);
            }

            if (!string.IsNullOrEmpty(timeFilter))
            {
                if (timeFilter == "month")
                    query = query.Where(po => po.OrderDate >= startOfCurrentMonth && po.OrderDate <= endOfCurrentMonth);
                else if (timeFilter == "lastmonth")
                    query = query.Where(po => po.OrderDate >= startOfLastMonth && po.OrderDate <= endOfLastMonth);
            }

            // 3. Phân trang
            int totalCount = await query.CountAsync();
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages == 0) totalPages = 1;
            if (page < 1) page = 1;
            if (page > totalPages) page = totalPages;

            var purchaseOrders = await query.OrderByDescending(po => po.OrderDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

            var suppliers = await _context.Suppliers.ToListAsync();

            return new ImportHistoryViewModel
            {
                TotalSpentThisMonth = currentMonthTotal,
                PercentChange = percentChange,
                TotalOrders = totalOrdersCount,
                PurchaseOrders = purchaseOrders,
                Suppliers = suppliers,
                CurrentPage = page,
                TotalPages = totalPages,
                TotalCount = totalCount,
                SelectedSupplierId = supplierId,
                TimeFilter = timeFilter
            };
        }

        public async Task<ImportHistoryDetailViewModel?> GetImportHistoryDetailAsync(int poId)
        {
            var po = await _context.PurchaseOrders
                .Include(p => p.PurchaseOrderDetails)
                    .ThenInclude(d => d.Service)
                .Include(p => p.Supplier)
                .FirstOrDefaultAsync(p => p.PoId == poId);

            if (po == null) return null;

            return new ImportHistoryDetailViewModel
            {
                PurchaseOrder = po,
                Suppliers = await _context.Suppliers.ToListAsync()
            };
        }
    }
}

