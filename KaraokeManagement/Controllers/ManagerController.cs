using KaraokeManagement.Models;
using KaraokeManagement.Services.ManagerServices;
using KaraokeManagement.ViewModel;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace KaraokeManagement.Controllers
{
    [Authorize(Roles = "Manager")]
    public class ManagerController : Controller
    {
        private readonly DashboardService _dashboardService;
        private readonly InventoryService _inventoryService;
        private readonly ExpenseService _expenseService;
        private readonly InvoiceService _invoiceManagerService;
        private readonly PricingService _pricingService;

        public ManagerController(
            DashboardService dashboardService,
            InventoryService inventoryService,
            ExpenseService expenseService,
            InvoiceService invoiceManagerService,
            PricingService pricingService)
        {
            _dashboardService = dashboardService;
            _inventoryService = inventoryService;
            _expenseService = expenseService;
            _invoiceManagerService = invoiceManagerService;
            _pricingService = pricingService;
        }

        private int GetCurrentManagerId()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return int.TryParse(userIdStr, out int userId) ? userId : 1;
        }

        #region Dashboard & Reporting
        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var viewModel = await _dashboardService.GetDashboardDataAsync();
            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> RevenueReport()
        {
            var viewModel = await _dashboardService.GetRevenueReportAsync();
            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> ProfitReport()
        {
            var viewModel = await _dashboardService.GetProfitReportAsync();
            return View(viewModel);
        }
        #endregion

        #region Inventory & Stock
        public async Task<IActionResult> StockIn()
        {
            ViewBag.Suppliers = await _inventoryService.GetAllSuppliersAsync();
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> SearchServices(string term)
        {
            var services = await _inventoryService.SearchServicesAsync(term);
            return Json(services);
        }

        [HttpPost]
        public async Task<IActionResult> SaveStockIn([FromBody] StockInRequestModel model)
        {
            if (model == null || !model.Items.Any())
                return Json(new { success = false, message = "Vui lòng thêm ít nhất 1 sản phẩm." });

            var result = await _inventoryService.SaveStockInAsync(model, GetCurrentManagerId());
            return Json(new { success = result.Success, message = result.Message });
        }

        [HttpPost]
        public async Task<IActionResult> UpdateStockIn([FromBody] UpdateStockInRequestModel model)
        {
            if (model == null || !model.Items.Any())
                return Json(new { success = false, message = "Vui lòng thêm ít nhất 1 sản phẩm." });

            var result = await _inventoryService.UpdateStockInAsync(model);
            return Json(new { success = result.Success, message = result.Message });
        }

        public async Task<IActionResult> Inventory()
        {
            var viewModel = await _inventoryService.GetInventoryAsync();
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddInventoryItem(string serviceName, int categoryId, decimal sellingPrice, string unit, int stockQuantity, decimal importPrice)
        {
            var result = await _inventoryService.AddInventoryItemAsync(serviceName, categoryId, sellingPrice, unit, stockQuantity, importPrice, GetCurrentManagerId());
            return Json(new { success = result.Success, message = result.Message });
        }

        [HttpGet]
        public async Task<IActionResult> ImportHistory(int? supplierId, string? timeFilter, int page = 1)
        {
            var viewModel = await _inventoryService.GetImportHistoryAsync(supplierId, timeFilter, page);
            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> ImportHistoryDetail(int id)
        {
            var viewModel = await _inventoryService.GetImportHistoryDetailAsync(id);
            if (viewModel == null) return RedirectToAction("ImportHistory");
            return View(viewModel);
        }
        #endregion

        #region Expenses
        [HttpGet]
        public async Task<IActionResult> Expenses()
        {
            var viewModel = await _expenseService.GetExpensesViewModelAsync();
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddExpense(int categoryId, string dateStr, decimal amount, string? note)
        {
            var result = await _expenseService.AddExpenseAsync(categoryId, dateStr, amount, note);
            return Json(new { success = result.Success, message = result.Message });
        }

        [HttpPost]
        public async Task<IActionResult> CreateCategory([FromBody] CreateCategoryModel payload)
        {
            var result = await _expenseService.CreateCategoryAsync(payload);
            if (!result.Success) return Json(new { success = false, message = result.Message });

            return Json(new { success = true, categoryId = result.CategoryId, categoryName = result.CategoryName });
        }
        #endregion

        #region Invoices
        [HttpGet]
        public async Task<IActionResult> Invoices(string? searchInvoiceId, DateTime? searchDate, int? roomId, DateTime? fromDate, DateTime? toDate, int page = 1)
        {
            var viewModel = await _invoiceManagerService.GetInvoicesAsync(searchInvoiceId, searchDate, roomId, fromDate, toDate, page);
            return View(viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> InvoiceDetails(int id)
        {
            var result = await _invoiceManagerService.GetInvoiceDetailAsync(id);
            if (!result.Success) return Json(new { success = false, message = result.Message });

            return Json(new { success = true, data = result.Data });
        }
        #endregion

        #region Dynamic Pricing Management
        [HttpGet]
        public async Task<IActionResult> DynamicPricing(string tab = "prices")
        {
            var viewModel = await _pricingService.GetDynamicPricingViewModelAsync(tab);
            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> CreateRoomPrice(int roomTypeId, TimeSpan startTime, TimeSpan endTime, decimal pricePerHour, DateTime? effectiveFrom, DateTime? effectiveTo)
        {
            await _pricingService.CreateRoomPriceAsync(roomTypeId, startTime, endTime, pricePerHour, effectiveFrom, effectiveTo);
            TempData["SuccessMessage"] = "Thêm khung giá phòng thành công!";
            return RedirectToAction(nameof(DynamicPricing), new { tab = "prices" });
        }

        [HttpPost]
        public async Task<IActionResult> EditRoomPrice(int priceId, int roomTypeId, TimeSpan startTime, TimeSpan endTime, decimal pricePerHour, DateTime? effectiveFrom, DateTime? effectiveTo)
        {
            await _pricingService.EditRoomPriceAsync(priceId, roomTypeId, startTime, endTime, pricePerHour, effectiveFrom, effectiveTo);
            TempData["SuccessMessage"] = "Cập nhật khung giá thành công!";
            return RedirectToAction(nameof(DynamicPricing), new { tab = "prices" });
        }

        [HttpPost]
        public async Task<IActionResult> DeleteRoomPrice(int priceId)
        {
            await _pricingService.DeleteRoomPriceAsync(priceId);
            TempData["SuccessMessage"] = "Xóa khung giá thành công!";
            return RedirectToAction(nameof(DynamicPricing), new { tab = "prices" });
        }

        [HttpPost]
        public async Task<IActionResult> CreatePricingPolicy(string policyName, string policyType, decimal value, bool isActive = true)
        {
            await _pricingService.CreatePricingPolicyAsync(policyName, policyType, value, isActive);
            TempData["SuccessMessage"] = "Thêm chính sách phụ thu thành công!";
            return RedirectToAction(nameof(DynamicPricing), new { tab = "policies" });
        }

        [HttpPost]
        public async Task<IActionResult> EditPricingPolicy(int policyId, string policyName, string policyType, decimal value, bool isActive)
        {
            await _pricingService.EditPricingPolicyAsync(policyId, policyName, policyType, value, isActive);
            TempData["SuccessMessage"] = "Cập nhật chính sách phụ thu thành công!";
            return RedirectToAction(nameof(DynamicPricing), new { tab = "policies" });
        }

        [HttpPost]
        public async Task<IActionResult> TogglePricingPolicy(int policyId)
        {
            await _pricingService.TogglePricingPolicyAsync(policyId);
            return RedirectToAction(nameof(DynamicPricing), new { tab = "policies" });
        }

        [HttpPost]
        public async Task<IActionResult> DeletePricingPolicy(int policyId)
        {
            await _pricingService.DeletePricingPolicyAsync(policyId);
            TempData["SuccessMessage"] = "Xóa chính sách phụ thu thành công!";
            return RedirectToAction(nameof(DynamicPricing), new { tab = "policies" });
        }

        [HttpPost]
        public async Task<IActionResult> CreateHoliday(string holidayName, DateTime holidayDate, decimal surchargePercent, bool isActive = true)
        {
            await _pricingService.CreateHolidayAsync(holidayName, holidayDate, surchargePercent, isActive);
            TempData["SuccessMessage"] = "Thêm ngày lễ thành công!";
            return RedirectToAction(nameof(DynamicPricing), new { tab = "holidays" });
        }

        [HttpPost]
        public async Task<IActionResult> EditHoliday(int holidayId, string holidayName, DateTime holidayDate, decimal surchargePercent, bool isActive)
        {
            await _pricingService.EditHolidayAsync(holidayId, holidayName, holidayDate, surchargePercent, isActive);
            TempData["SuccessMessage"] = "Cập nhật thông tin ngày lễ thành công!";
            return RedirectToAction(nameof(DynamicPricing), new { tab = "holidays" });
        }

        [HttpPost]
        public async Task<IActionResult> ToggleHoliday(int holidayId)
        {
            await _pricingService.ToggleHolidayAsync(holidayId);
            return RedirectToAction(nameof(DynamicPricing), new { tab = "holidays" });
        }

        [HttpPost]
        public async Task<IActionResult> DeleteHoliday(int holidayId)
        {
            await _pricingService.DeleteHolidayAsync(holidayId);
            TempData["SuccessMessage"] = "Xóa ngày lễ thành công!";
            return RedirectToAction(nameof(DynamicPricing), new { tab = "holidays" });
        }
        #endregion
    }
}
