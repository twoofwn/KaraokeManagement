using KaraokeManagement.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Helpers;

namespace KaraokeManagement.Controllers
{
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        public AdminController(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public IActionResult Index() => RedirectToAction("Dashboard");

        // ========== DASHBOARD ==========
        public IActionResult Dashboard()
        {
            ViewBag.TotalItems = _context.ServiceItems.Count();
            ViewBag.TotalCategories = _context.Categories.Count();
            ViewBag.TotalUsers = _context.Accounts.Count();
            ViewBag.TotalInvoices = _context.Invoices.Count();
            ViewBag.RecentItems = _context.ServiceItems.Include(s => s.Category)
                .OrderByDescending(s => s.ServiceId).Take(5).ToList();
            return View();
        }

        // ========== INVENTORY (ServiceItems) ==========
        public IActionResult Inventory()
        {
            var items = _context.ServiceItems.Include(s => s.Category).ToList();
            return View("Inventory", items);
        }

        [HttpGet]
        public IActionResult InventoryCreate()
        {
            LoadCategories();
            return View("InventoryForm", new ServiceItem());
        }

        [HttpPost]
        public IActionResult InventoryCreate(ServiceItem model)
        {
            ModelState.Remove("Category");
            if (!ModelState.IsValid) { LoadCategories(); return View("InventoryForm", model); }
            _context.ServiceItems.Add(model);
            _context.SaveChanges();
            return RedirectToAction("Inventory");
        }

        [HttpGet]
        public IActionResult InventoryEdit(int id)
        {
            var item = _context.ServiceItems.Find(id);
            if (item == null) return NotFound();
            LoadCategories(item.CategoryId);
            ViewBag.IsEdit = true;
            return View("InventoryForm", item);
        }

        [HttpPost]
        public IActionResult InventoryEdit(int id, ServiceItem model)
        {
            ModelState.Remove("Category");
            if (!ModelState.IsValid) { LoadCategories(model.CategoryId); ViewBag.IsEdit = true; return View("InventoryForm", model); }
            var existing = _context.ServiceItems.Find(id);
            if (existing == null) return NotFound();
            existing.ServiceName = model.ServiceName;
            existing.CategoryId = model.CategoryId;
            existing.SellingPrice = model.SellingPrice;
            existing.Unit = model.Unit;
            existing.StockQuantity = model.StockQuantity;
            _context.SaveChanges();
            return RedirectToAction("Inventory");
        }

        [HttpPost]
        public IActionResult InventoryDelete(int id)
        {
            var item = _context.ServiceItems.Find(id);
            if (item != null)
            {
                _context.ServiceItems.Remove(item);
                _context.SaveChanges();
            }
            return RedirectToAction("Inventory");
        }

        // ========== CATEGORIES ==========
        public IActionResult Categories()
        {
            var categories = _context.Categories.ToList();
            return View("Categories", categories);
        }

        [HttpGet]
        public IActionResult CategoryCreate()
        {
            return View("CategoryForm", new Category());
        }

        [HttpPost]
        public IActionResult CategoryCreate(Category model)
        {
            if (!ModelState.IsValid) return View("CategoryForm", model);
            _context.Categories.Add(model);
            _context.SaveChanges();
            return RedirectToAction("Categories");
        }

        [HttpGet]
        public IActionResult CategoryEdit(int id)
        {
            var category = _context.Categories.Find(id);
            if (category == null) return NotFound();
            ViewBag.IsEdit = true;
            return View("CategoryForm", category);
        }

        [HttpPost]
        public IActionResult CategoryEdit(int id, Category model)
        {
            if (!ModelState.IsValid) { ViewBag.IsEdit = true; return View("CategoryForm", model); }
            var existing = _context.Categories.Find(id);
            if (existing == null) return NotFound();
            existing.CategoryName = model.CategoryName;
            _context.SaveChanges();
            return RedirectToAction("Categories");
        }

        [HttpPost]
        public IActionResult CategoryDelete(int id)
        {
            var category = _context.Categories.Find(id);
            if (category != null)
            {
                _context.Categories.Remove(category);
                _context.SaveChanges();
            }
            return RedirectToAction("Categories");
        }

        // ========== USERS (Accounts) ==========
        public IActionResult Users()
        {
            var users = _context.Accounts.Include(a => a.Role).ToList();
            return View("Users", users);
        }

        [HttpGet]
        public IActionResult UserCreate()
        {
            LoadRoles();
            return View("UserForm", new Account());
        }

        [HttpPost]
        public IActionResult UserCreate(Account model, string Password)
        {
            ModelState.Remove("Role");
            ModelState.Remove("PasswordHash");
            if (string.IsNullOrWhiteSpace(Password))
                ModelState.AddModelError("Password", "Password is required.");
            if (!ModelState.IsValid) { LoadRoles(); return View("UserForm", model); }
            model.PasswordHash = PasswordHelper.HashPassword(Password);
            model.CreatedAt = DateTime.Now;
            _context.Accounts.Add(model);
            _context.SaveChanges();
            return RedirectToAction("Users");
        }

        [HttpGet]
        public IActionResult UserEdit(int id)
        {
            var account = _context.Accounts.Find(id);
            if (account == null) return NotFound();
            LoadRoles(account.RoleId);
            ViewBag.IsEdit = true;
            return View("UserForm", account);
        }

        [HttpPost]
        public IActionResult UserEdit(int id, Account model, string? Password)
        {
            ModelState.Remove("Role");
            ModelState.Remove("PasswordHash");
            if (!ModelState.IsValid) { LoadRoles(model.RoleId); ViewBag.IsEdit = true; return View("UserForm", model); }
            var existing = _context.Accounts.Find(id);
            if (existing == null) return NotFound();
            existing.FullName = model.FullName;
            existing.Username = model.Username;
            existing.Email = model.Email;
            existing.Phone = model.Phone;
            existing.RoleId = model.RoleId;
            if (!string.IsNullOrWhiteSpace(Password))
                existing.PasswordHash = PasswordHelper.HashPassword(Password);
            _context.SaveChanges();
            return RedirectToAction("Users");
        }

        [HttpPost]
        public IActionResult UserDelete(int id)
        {
            var account = _context.Accounts.Find(id);
            if (account != null)
            {
                _context.Accounts.Remove(account);
                _context.SaveChanges();
            }
            return RedirectToAction("Users");
        }

        // ========== HELPERS ==========
        private void LoadCategories(int? selectedId = null)
        {
            ViewBag.Categories = new SelectList(_context.Categories.ToList(), "CategoryId", "CategoryName", selectedId);
        }

        private void LoadRoles(int? selectedId = null)
        {
            ViewBag.Roles = new SelectList(_context.Roles.ToList(), "RoleId", "RoleName", selectedId);
        }

    }
}
