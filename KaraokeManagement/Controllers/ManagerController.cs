using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace KaraokeManagement.Controllers
{
    [Authorize(Roles = "Manager")]
    public class ManagerController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        public ManagerController(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var today = DateTime.Today;
            var startOfDay = today;
            var endOfDay = today.AddDays(1).AddTicks(-1);

            var startOfMonth = new DateTime(today.Year, today.Month, 1);
            var endOfMonth = startOfMonth.AddMonths(1).AddTicks(-1);

            // 1. Số khách hôm nay (Distinct CustomerId từ các hoá đơn có Booking phát sinh hôm nay)
            int customersToday = await _context.Invoices
                .Where(i => i.CheckInTime >= startOfDay && i.CheckInTime <= endOfDay && i.BookingId != null)
                .Select(i => i.Booking!.CustomerId)
                .Distinct()
                .CountAsync();

            // 2. Doanh thu hôm nay (Từ các hoá đơn đã thanh toán hôm nay)
            decimal revenueToday = await _context.Invoices
                .Where(i => i.Status == "Paid" && i.CheckOutTime >= startOfDay && i.CheckOutTime <= endOfDay)
                .SumAsync(i => i.GrandTotal ?? 0);

            // 3. Số khách tháng này
            int customersThisMonth = await _context.Invoices
                .Where(i => i.CheckInTime >= startOfMonth && i.CheckInTime <= endOfMonth && i.BookingId != null)
                .Select(i => i.Booking!.CustomerId)
                .Distinct()
                .CountAsync();

            // 4. Doanh thu tháng này
            decimal revenueThisMonth = await _context.Invoices
                .Where(i => i.Status == "Paid" && i.CheckOutTime >= startOfMonth && i.CheckOutTime <= endOfMonth)
                .SumAsync(i => i.GrandTotal ?? 0);

            // Calculate Total Revenue from all Paid Invoices
            decimal totalRevenue = await _context.Invoices
                .Where(i => i.Status == "Paid")
                .SumAsync(i => i.GrandTotal ?? 0);

            // Calculate Total Expenses from Expense table + PurchaseOrder table
            decimal totalExpenses = await _context.Expenses
                .SumAsync(e => e.Amount);

            decimal totalPOAmount = await _context.PurchaseOrders
                .SumAsync(po => po.TotalAmount ?? 0);

            totalExpenses += totalPOAmount;

            decimal netProfit = totalRevenue - totalExpenses;
            double profitMargin = totalRevenue > 0 ? (double)(netProfit / totalRevenue) * 100 : 0;

            // Generate monthly trend for past 6 months
            var labels = new List<string>();
            var revenues = new List<decimal>();
            var expensesList = new List<decimal>();

            var now = DateTime.Now;
            for (int i = 5; i >= 0; i--)
            {
                var targetMonth = now.AddMonths(-i);
                var monthStart = new DateTime(targetMonth.Year, targetMonth.Month, 1);
                var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

                labels.Add($"Tháng {targetMonth.Month}/{targetMonth.Year.ToString().Substring(2)}");

                decimal rev = await _context.Invoices
                    .Where(i => i.Status == "Paid" && i.CheckOutTime >= monthStart && i.CheckOutTime <= monthEnd)
                    .SumAsync(i => i.GrandTotal ?? 0);
                revenues.Add(rev);

                decimal exp = await _context.Expenses
                    .Where(e => e.ExpenseDate >= monthStart && e.ExpenseDate <= monthEnd)
                    .SumAsync(e => e.Amount);

                decimal poAmt = await _context.PurchaseOrders
                    .Where(po => po.OrderDate >= monthStart && po.OrderDate <= monthEnd)
                    .SumAsync(po => po.TotalAmount ?? 0);

                expensesList.Add(exp + poAmt);
            }

            var viewModel = new FinancialDashboardViewModel
            {
                CustomersToday = customersToday,
                RevenueToday = revenueToday,
                CustomersThisMonth = customersThisMonth,
                RevenueThisMonth = revenueThisMonth,

                TotalRevenue = totalRevenue,
                TotalExpenses = totalExpenses,
                NetProfit = netProfit,
                ProfitMargin = profitMargin,
                MonthlyLabels = labels,
                MonthlyRevenues = revenues,
                MonthlyExpenses = expensesList
            };

            return View(viewModel);
        }


        public IActionResult StockIn()
        {
            ViewBag.Suppliers = _context.Suppliers.ToList();
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> SearchServices(string term)

        {
            var query = _context.ServiceItems.AsQueryable();

            if (!string.IsNullOrWhiteSpace(term))
            {
                query = query.Where(s => s.ServiceName.Contains(term));
            }

            var services = await query
                .Select(s => new
                {
                    serviceId = s.ServiceId,
                    serviceName = s.ServiceName,
                    unit = s.Unit
                })
                .Take(15)
                .ToListAsync();

            return Json(services);
        }

        [HttpPost]
        public async Task<IActionResult> SaveStockIn([FromBody] StockInRequestModel model)
        {
            if (model == null || !model.Items.Any())
            {
                return Json(new { success = false, message = "Vui lòng thêm ít nhất 1 sản phẩm." });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Tạo Purchase Order mới
                var po = new PurchaseOrder
                {
                    SupplierId = model.SupplierId,
                    OrderDate = model.OrderDate,
                    CreatedById = 1, // FIX CỨNG TẠM: Thay bằng ID User đăng nhập thực tế của bạn
                    TotalAmount = model.Items.Sum(i => i.Quantity * i.ImportPrice)
                };

                _context.PurchaseOrders.Add(po);
                await _context.SaveChangesAsync(); // Lưu để lấy PoId

                // 2. Thêm Chi tiết và Cập nhật Tồn kho
                foreach (var item in model.Items)
                {
                    var detail = new PurchaseOrderDetail
                    {
                        PoId = po.PoId,
                        ServiceId = item.ServiceId,
                        Quantity = item.Quantity,
                        ImportPrice = item.ImportPrice
                    };
                    _context.PurchaseOrderDetails.Add(detail);

                    // Cập nhật số lượng tồn trong ServiceItem
                    var service = await _context.ServiceItems.FindAsync(item.ServiceId);
                    if (service != null)
                    {
                        service.StockQuantity = (service.StockQuantity ?? 0) + item.Quantity;
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Json(new { success = true, message = "Lưu phiếu nhập thành công!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return Json(new { success = false, message = "Có lỗi xảy ra: " + ex.Message });
            }
        }

        public async Task<IActionResult> Inventory()
        {
            var items = await _context.ServiceItems
                .Include(s => s.Category)
                .ToListAsync();

            var latestImportPrices = await _context.PurchaseOrderDetails
                .Include(pod => pod.Po)
                .GroupBy(pod => pod.ServiceId)
                .Select(g => new
                {
                    ServiceId = g.Key,
                    LatestPrice = g.OrderByDescending(pod => pod.Po.OrderDate).Select(pod => pod.ImportPrice).FirstOrDefault()
                })
                .ToDictionaryAsync(x => x.ServiceId, x => x.LatestPrice);

            var vmItems = items.Select(item =>
            {
                decimal importPrice = latestImportPrices.TryGetValue(item.ServiceId, out var price) ? price : 0;
                string status = "In Stock";
                if ((item.StockQuantity ?? 0) <= 0) status = "Out of Stock";
                else if ((item.StockQuantity ?? 0) <= 10) status = "Low Stock";

                return new InventoryItemViewModel
                {
                    ServiceId = item.ServiceId,
                    ServiceName = item.ServiceName,
                    CategoryName = item.Category.CategoryName,
                    SellingPrice = item.SellingPrice,
                    Unit = item.Unit,
                    StockQuantity = item.StockQuantity ?? 0,
                    ImportPrice = importPrice,
                    Status = status
                };
            }).ToList();

            decimal totalValue = vmItems.Sum(x => x.StockQuantity * x.ImportPrice);
            int lowStockCount = vmItems.Count(x => x.Status == "Low Stock");
            int activeCategoriesCount = await _context.Categories.CountAsync();
            var categories = await _context.Categories.ToListAsync();

            var viewModel = new InventoryViewModel
            {
                Items = vmItems,
                TotalValue = totalValue,
                LowStockCount = lowStockCount,
                ActiveCategoriesCount = activeCategoriesCount,
                Categories = categories
            };

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddInventoryItem(string serviceName, int categoryId, decimal sellingPrice, string unit, int stockQuantity, decimal importPrice)
        {
            if (string.IsNullOrWhiteSpace(serviceName))
            {
                return Json(new { success = false, message = "Tên sản phẩm không được để trống." });
            }
            if (sellingPrice < 0)
            {
                return Json(new { success = false, message = "Giá bán không được nhỏ hơn 0." });
            }
            if (stockQuantity < 0)
            {
                return Json(new { success = false, message = "Số lượng tồn kho không được nhỏ hơn 0." });
            }
            if (importPrice < 0)
            {
                return Json(new { success = false, message = "Giá nhập không được nhỏ hơn 0." });
            }

            bool exists = await _context.ServiceItems.AnyAsync(s => s.ServiceName.ToLower() == serviceName.ToLower() && s.CategoryId == categoryId);
            if (exists)
            {
                return Json(new { success = false, message = "Sản phẩm này đã tồn tại trong danh mục này." });
            }

            var newItem = new ServiceItem
            {
                ServiceName = serviceName,
                CategoryId = categoryId,
                SellingPrice = sellingPrice,
                Unit = unit,
                StockQuantity = stockQuantity
            };

            _context.ServiceItems.Add(newItem);
            await _context.SaveChangesAsync();

            // If initial stock and import price are provided, create a PurchaseOrder record
            if (stockQuantity > 0 && importPrice > 0)
            {
                var defaultSupplier = await _context.Suppliers.FirstOrDefaultAsync();
                int supplierId = defaultSupplier?.SupplierId ?? 1;

                var po = new PurchaseOrder
                {
                    SupplierId = supplierId,
                    CreatedById = 2, // Hung Manager
                    OrderDate = DateTime.Now,
                    TotalAmount = stockQuantity * importPrice
                };
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

            return Json(new { success = true, message = "Thêm hàng mới thành công!" });
        }

        [HttpGet]
        public async Task<IActionResult> ImportHistory(int? supplierId, string? timeFilter, int page = 1)
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
                percentChange = 100; // Tăng 100% nếu tháng trước bằng 0 mà tháng này có
            }

            var totalOrdersCount = await _context.PurchaseOrders.CountAsync();

            // 2. Xây dựng Query danh sách
            var query = _context.PurchaseOrders
                .Include(po => po.Supplier)
                .AsQueryable();

            // Áp dụng bộ lọc Nhà cung cấp
            if (supplierId.HasValue && supplierId.Value > 0)
            {
                query = query.Where(po => po.SupplierId == supplierId.Value);
            }

            // Áp dụng bộ lọc Thời gian
            if (!string.IsNullOrEmpty(timeFilter))
            {
                if (timeFilter == "month")
                    query = query.Where(po => po.OrderDate >= startOfCurrentMonth && po.OrderDate <= endOfCurrentMonth);
                else if (timeFilter == "lastmonth")
                    query = query.Where(po => po.OrderDate >= startOfLastMonth && po.OrderDate <= endOfLastMonth);
            }

            // 3. Phân trang (Server-side)
            int pageSize = 10;
            int totalCount = await query.CountAsync();
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages == 0) totalPages = 1;
            if (page < 1) page = 1;
            if (page > totalPages) page = totalPages;

            var purchaseOrders = await query
                .OrderByDescending(po => po.OrderDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            // 4. Lấy danh sách nhà cung cấp cho Dropdown
            var suppliers = await _context.Suppliers.ToListAsync();

            var viewModel = new KaraokeManagement.ViewModel.ImportHistoryViewModel
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

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> ImportHistoryDetail(int id)
        {
            var po = await _context.PurchaseOrders
                .Include(p => p.PurchaseOrderDetails)
                    .ThenInclude(d => d.Service)
                .Include(p => p.Supplier)
                .FirstOrDefaultAsync(p => p.PoId == id);

            if (po == null)
            {
                return RedirectToAction("ImportHistory");
            }

            var viewModel = new KaraokeManagement.ViewModel.ImportHistoryDetailViewModel
            {
                PurchaseOrder = po,
                Suppliers = await _context.Suppliers.ToListAsync()
            };

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> UpdateStockIn([FromBody] KaraokeManagement.ViewModel.UpdateStockInRequestModel model)
        {
            if (model == null || !model.Items.Any())
            {
                return Json(new { success = false, message = "Vui lòng thêm ít nhất 1 sản phẩm." });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var existingPo = await _context.PurchaseOrders
                    .Include(p => p.PurchaseOrderDetails)
                    .FirstOrDefaultAsync(p => p.PoId == model.PoId);

                if (existingPo == null)
                    return Json(new { success = false, message = "Không tìm thấy phiếu nhập." });

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

                return Json(new { success = true, message = "Cập nhật phiếu nhập thành công!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return Json(new { success = false, message = "Có lỗi xảy ra: " + ex.Message });
            }
        }

        [HttpGet]
        public async Task<IActionResult> Expenses()
        {
            var now = DateTime.Now;
            var startOfCurrentMonth = new DateTime(now.Year, now.Month, 1);
            var endOfCurrentMonth = startOfCurrentMonth.AddMonths(1).AddDays(-1);

            var startOfLastMonth = startOfCurrentMonth.AddMonths(-1);
            var endOfLastMonth = startOfCurrentMonth.AddDays(-1);

            var currentMonthExpenses = await _context.Expenses
                .Where(e => e.ExpenseDate >= startOfCurrentMonth && e.ExpenseDate <= endOfCurrentMonth)
                .ToListAsync();

            var lastMonthExpenses = await _context.Expenses
                .Where(e => e.ExpenseDate >= startOfLastMonth && e.ExpenseDate <= endOfLastMonth)
                .ToListAsync();

            decimal totalCurrentMonth = currentMonthExpenses.Sum(e => e.Amount);
            decimal totalLastMonth = lastMonthExpenses.Sum(e => e.Amount);

            decimal percentChange = 0;
            if (totalLastMonth > 0)
            {
                percentChange = ((totalCurrentMonth - totalLastMonth) / totalLastMonth) * 100;
            }

            // Find highest category in current month
            var categoryGroup = currentMonthExpenses
                .GroupBy(e => e.Category)
                .Select(g => new { Category = g.Key, Amount = g.Sum(e => e.Amount) })
                .OrderByDescending(g => g.Amount)
                .FirstOrDefault();

            string highestCatName = "Chưa có";
            decimal highestCatAmount = 0;
            decimal highestCatPercent = 0;

            if (categoryGroup != null)
            {
                highestCatName = ExpensesViewModel.GetCategoryDisplayName(categoryGroup.Category);
                highestCatAmount = categoryGroup.Amount;
                if (totalCurrentMonth > 0)
                {
                    highestCatPercent = (highestCatAmount / totalCurrentMonth) * 100;
                }
            }

            var allExpenses = await _context.Expenses
                .OrderByDescending(e => e.ExpenseDate)
                .ThenByDescending(e => e.CreatedAt)
                .ToListAsync();

            var viewModel = new ExpensesViewModel
            {
                TotalMonthExpense = totalCurrentMonth,
                PercentChange = percentChange,
                HighestCategoryName = highestCatName,
                HighestCategoryAmount = highestCatAmount,
                HighestCategoryPercent = highestCatPercent,
                RecentExpenses = allExpenses
            };

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddExpense(string category, string dateStr, decimal amount, string? note)
        {
            if (string.IsNullOrEmpty(category) || amount <= 0)
            {
                return Json(new { success = false, message = "Vui lòng nhập đầy đủ thông tin loại chi phí và số tiền lớn hơn 0." });
            }

            DateTime expenseDate = DateTime.Now;
            if (!string.IsNullOrEmpty(dateStr))
            {
                // UI inputs type="month" which gives "yyyy-MM", we can append "-01" to parse it as date
                if (DateTime.TryParse(dateStr + "-01", out var parsedDate))
                {
                    expenseDate = parsedDate;
                }
                else if (DateTime.TryParse(dateStr, out parsedDate))
                {
                    expenseDate = parsedDate;
                }
            }

            var newExpense = new Expense
            {
                Category = category,
                ExpenseDate = expenseDate,
                Amount = amount,
                Note = note,
                CreatedAt = DateTime.Now
            };

            _context.Expenses.Add(newExpense);
            await _context.SaveChangesAsync();

            return Json(new { success = true, message = "Đã lưu chi phí thành công!" });
        }

        [HttpGet]
        public async Task<IActionResult> Invoices(DateTime? fromDate, DateTime? toDate, int page = 1)
        {
            var now = DateTime.Now;
            var end = toDate ?? new DateTime(now.Year, now.Month, now.Day, 23, 59, 59);
            var start = fromDate ?? new DateTime(now.Year, now.Month, 1).AddMonths(-1); // Default to show more data initially

            var searchStart = start.Date;
            var searchEnd = end.Date.AddDays(1).AddTicks(-1);

            var query = _context.Invoices
                .Include(i => i.Room)
                .Where(i => i.Status == "Paid" && i.CheckOutTime >= searchStart && i.CheckOutTime <= searchEnd);

            int totalCount = await query.CountAsync();
            int pageSize = 10;
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages == 0) totalPages = 1;

            if (page < 1) page = 1;
            if (page > totalPages) page = totalPages;

            var invoices = await query
                .OrderByDescending(i => i.CheckOutTime)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            int startEntry = totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
            int endEntry = Math.Min(page * pageSize, totalCount);

            var viewModel = new ManagerInvoicesViewModel
            {
                Invoices = invoices,
                FromDate = start,
                ToDate = end,
                CurrentPage = page,
                TotalPages = totalPages,
                TotalCount = totalCount,
                StartEntry = startEntry,
                EndEntry = endEntry
            };

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> InvoiceDetails(int id)
        {
            var invoice = await _context.Invoices
                .Include(i => i.Room)
                .ThenInclude(r => r.RoomType)
                .Include(i => i.Receptionist)
                .Include(i => i.Booking)
                .ThenInclude(b => b!.Customer)
                .ThenInclude(c => c.Tier)
                .Include(i => i.InvoiceDetails)
                .ThenInclude(d => d.Service)
                .Include(i => i.PaymentTransactions)
                .ThenInclude(t => t.Method)
                .FirstOrDefaultAsync(i => i.InvoiceId == id);

            if (invoice == null)
            {
                return Json(new { success = false, message = "Không tìm thấy hóa đơn." });
            }

            var duration = (invoice.CheckOutTime ?? DateTime.Now) - invoice.CheckInTime;
            string durationText = $"{(int)duration.TotalHours} giờ {duration.Minutes} phút";

            var details = new
            {
                invoiceId = invoice.InvoiceId,
                roomName = invoice.Room.RoomName,
                roomTypeName = invoice.Room.RoomType.TypeName,
                pricePerHour = invoice.Room.RoomType.PricePerHour,
                checkInTime = invoice.CheckInTime.ToString("dd/MM/yyyy HH:mm"),
                checkOutTime = invoice.CheckOutTime?.ToString("dd/MM/yyyy HH:mm") ?? "Chưa checkout",
                durationText = durationText,
                customerName = invoice.Booking?.Customer?.FullName ?? "Khách vãng lai",
                customerPhone = invoice.Booking?.Customer?.Phone ?? "N/A",
                customerTier = invoice.Booking?.Customer?.Tier?.TierName ?? "Thường",
                discountPercent = invoice.Booking?.Customer?.Tier?.DiscountPercent ?? 0,
                receptionistName = invoice.Receptionist?.FullName ?? "N/A",
                roomTotal = invoice.RoomTotal ?? 0,
                serviceTotal = invoice.ServiceTotal ?? 0,
                discountAmount = invoice.DiscountAmount ?? 0,
                grandTotal = invoice.GrandTotal ?? 0,
                status = invoice.Status,
                items = invoice.InvoiceDetails.Select(d => new
                {
                    serviceName = d.Service.ServiceName,
                    quantity = d.Quantity,
                    unitPrice = d.UnitPrice,
                    total = d.Quantity * d.UnitPrice,
                    unit = d.Service.Unit
                }).ToList(),
                payments = invoice.PaymentTransactions.Select(t => new
                {
                    methodName = t.Method.MethodName,
                    amount = t.Amount,
                    date = t.TransactionDate?.ToString("dd/MM/yyyy HH:mm") ?? "",
                    refCode = t.ReferenceCode ?? ""
                }).ToList()
            };

            return Json(new { success = true, data = details });
        }

        [HttpGet]
        public async Task<IActionResult> RevenueReport()
        {
            // Total Room vs Service Revenue
            decimal totalRoom = await _context.Invoices
                .Where(i => i.Status == "Paid")
                .SumAsync(i => i.RoomTotal ?? 0);

            decimal totalService = await _context.Invoices
                .Where(i => i.Status == "Paid")
                .SumAsync(i => i.ServiceTotal ?? 0);

            decimal totalRevenue = totalRoom + totalService;

            // Group by Room Type
            var roomTypeRevenue = await _context.Invoices
                .Where(i => i.Status == "Paid")
                .Include(i => i.Room).ThenInclude(r => r.RoomType)
                .GroupBy(i => i.Room.RoomType.TypeName)
                .Select(g => new { TypeName = g.Key, Amount = g.Sum(i => i.RoomTotal ?? 0) })
                .ToListAsync();

            // Group by Service Category
            var categoryRevenue = await _context.InvoiceDetails
                .Include(id => id.Invoice)
                .Include(id => id.Service).ThenInclude(s => s.Category)
                .Where(id => id.Invoice.Status == "Paid")
                .GroupBy(id => id.Service.Category.CategoryName)
                .Select(g => new { CategoryName = g.Key, Amount = g.Sum(id => id.Quantity * id.UnitPrice) })
                .ToListAsync();

            var viewModel = new FinancialDashboardViewModel
            {
                TotalRevenue = totalRevenue,
                TotalRoomRevenue = totalRoom,
                TotalServiceRevenue = totalService,
                RoomTypeLabels = roomTypeRevenue.Select(r => r.TypeName).ToList(),
                RoomTypeRevenues = roomTypeRevenue.Select(r => r.Amount).ToList(),
                CategoryLabels = categoryRevenue.Select(c => c.CategoryName).ToList(),
                CategoryRevenues = categoryRevenue.Select(c => c.Amount).ToList()
            };

            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> ProfitReport()
        {
            var now = DateTime.Now;
            var profitItems = new List<MonthlyProfitReportItem>();

            // Generate monthly profit list for the past 12 months
            for (int i = 11; i >= 0; i--)
            {
                var targetMonth = now.AddMonths(-i);
                var monthStart = new DateTime(targetMonth.Year, targetMonth.Month, 1);
                var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

                decimal revenue = await _context.Invoices
                    .Where(i => i.Status == "Paid" && i.CheckOutTime >= monthStart && i.CheckOutTime <= monthEnd)
                    .SumAsync(i => i.GrandTotal ?? 0);

                decimal expenses = await _context.Expenses
                    .Where(e => e.ExpenseDate >= monthStart && e.ExpenseDate <= monthEnd)
                    .SumAsync(e => e.Amount);

                decimal poAmt = await _context.PurchaseOrders
                    .Where(po => po.OrderDate >= monthStart && po.OrderDate <= monthEnd)
                    .SumAsync(po => po.TotalAmount ?? 0);

                decimal totalExpenses = expenses + poAmt;
                decimal netProfit = revenue - totalExpenses;
                double margin = revenue > 0 ? (double)(netProfit / revenue) * 100 : 0;

                profitItems.Add(new MonthlyProfitReportItem
                {
                    MonthLabel = $"Tháng {targetMonth.Month}/{targetMonth.Year}",
                    Revenue = revenue,
                    Expenses = totalExpenses,
                    NetProfit = netProfit,
                    Margin = margin
                });
            }

            // Overall summary stats
            decimal totalRevenue = profitItems.Sum(x => x.Revenue);
            decimal totalExpensesAll = profitItems.Sum(x => x.Expenses);
            decimal netProfitAll = totalRevenue - totalExpensesAll;
            double profitMarginAll = totalRevenue > 0 ? (double)(netProfitAll / totalRevenue) * 100 : 0;

            var viewModel = new FinancialDashboardViewModel
            {
                TotalRevenue = totalRevenue,
                TotalExpenses = totalExpensesAll,
                NetProfit = netProfitAll,
                ProfitMargin = profitMarginAll,
                ProfitItems = profitItems
            };

            return View(viewModel);
        }
    }
}
