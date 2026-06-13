using Microsoft.AspNetCore.Mvc;

namespace KaraokeManagement.Controllers
{
    public class AdminController : Controller
    {
        public IActionResult Index() => View();

        [HttpGet]
        public IActionResult Create()
        {
            ViewBag.IsEdit = false;
            return View("Form");
        }

        [HttpGet]
        public IActionResult Edit(int id)
        {
            ViewBag.IsEdit = true;
            ViewBag.EditId = id;
            return View("Form");
        }
    }
}
