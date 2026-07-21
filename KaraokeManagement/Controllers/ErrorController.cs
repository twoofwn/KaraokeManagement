using Microsoft.AspNetCore.Mvc;

namespace KaraokeManagement.Controllers
{
    public class ErrorController : Controller
    {
        [Route("Error/404")]
        public IActionResult Error404()
        {
            Response.StatusCode = 404;
            return View("404");
        }

        [Route("Error/403")]
        public IActionResult Error403()
        {
            Response.StatusCode = 403;
            return View("403");
        }
    }
}
