using Microsoft.AspNetCore.Mvc;

namespace KaraokeManagement.Controllers
{
    public class ManagerController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult StockIn()
        {

            return View();
        }

        public IActionResult Inventory()
        {
            return View();
        }

        public IActionResult ImportHistory()
        {
            return View();
        }

        public IActionResult Expenses()
        {
            return View();
        }

        public IActionResult Invoices()
        {
            return View();
        }
    }
}
