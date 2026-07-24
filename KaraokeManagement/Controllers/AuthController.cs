namespace KaraokeManagement.Controllers;

using KaraokeManagement.Services.AuthService;
using KaraokeManagement.ViewModel;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

public class AuthController : Controller
{
    private readonly AuthService _authService;

    public AuthController(AuthService authService)
    {
        _authService = authService;
    }

    // Nhan vien dang nhap
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult Login()
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            if (User.IsInRole("Admin")) return RedirectToAction("Index", "Admin");
            if (User.IsInRole("Manager")) return RedirectToAction("Index", "Manager");
            if (User.IsInRole("Receptionist")) return RedirectToAction("Index", "Receptionist");
        }
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Login(LoginViewModel model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Error = "Vui lòng nhập cả email và mật khẩu.";
            return View(model);
        }

        var result = await _authService.AuthenticateStaffAsync(model);
        if (result.success && result.principal != null)
        {
            var authProperties = new AuthenticationProperties
            {
                IsPersistent = model.RememberMe,
                ExpiresUtc = model.RememberMe ? DateTimeOffset.UtcNow.AddDays(7) : DateTimeOffset.UtcNow.AddMinutes(30)
            };

            await HttpContext.SignInAsync("CookieAuth", result.principal, authProperties);

            if (result.role == "Admin") return RedirectToAction("Index", "Admin");
            if (result.role == "Manager") return RedirectToAction("Index", "Manager");
            if (result.role == "Receptionist") return RedirectToAction("Index", "Receptionist");
            if (result.role == "Service Staff" || result.role.Contains("Phục vụ")) return RedirectToAction("Dashboard", "Staff");

            return RedirectToAction("Index", "Admin");
        }

        ViewBag.Error = result.error;
        return View(model);
    }


    // Customer dang nhap
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult CustomerLogin()
    {
        if (User.Identity?.IsAuthenticated == true && User.IsInRole("Customer"))
            return RedirectToAction("Index", "Customer");
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> CustomerLogin(string Email, string Password)
    {
        var result = await _authService.AuthenticateCustomerAsync(Email, Password);
        if (result.requireOtp)
        {
            ViewBag.Email = result.email;
            ViewBag.ActionType = "Register";
            ViewBag.Error = result.error;
            return View("VerifyOtp");
        }

        if (result.success && result.principal != null)
        {
            await HttpContext.SignInAsync("CookieAuth", result.principal);
            return RedirectToAction("Index", "Customer");
        }

        ViewBag.Error = result.error;
        return View();
    }

    // Dang ky
    [HttpGet]
    public IActionResult Register() => View();

    [HttpPost]
    public async Task<IActionResult> Register(RegisterViewModel model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Error = "Vui lòng nhập đầy đủ thông tin.";
            return View(model);
        }

        var result = await _authService.RegisterCustomerAsync(model);
        if (result.success)
        {
            ViewBag.Email = result.email;
            ViewBag.ActionType = "Register";
            return View("VerifyOtp");
        }

        ViewBag.Error = result.error;
        return View(model);
    }


    // Dang xuat
    [HttpGet]
    public async Task<IActionResult> Logout()
    {
        bool isCustomer = User.IsInRole("Customer");
        try { await HttpContext.SignOutAsync("CookieAuth"); } catch { }

        Response.Cookies.Delete("UserSession");
        Response.Cookies.Delete("UserRole");

        return isCustomer ? RedirectToAction("CustomerLogin") : RedirectToAction("Login");
    }


    // Quen mk
    [HttpGet]
    public IActionResult ForgotPassword() => View();

    [HttpPost]
    public async Task<IActionResult> ForgotPassword(string email)
    {
        var result = await _authService.SendForgotPasswordOtpAsync(email);
        if (result.success)
        {
            ViewBag.Email = email;
            ViewBag.ActionType = "ResetPassword";
            return View("VerifyOtp");
        }

        ViewBag.Error = result.error;
        return View();
    }
    
    // Xac minh otp
    [HttpPost]
    public async Task<IActionResult> VerifyOtp(string email, string otpCode, string actionType)
    {
        var result = await _authService.VerifyOtpAsync(email, otpCode, actionType);
        if (!result.success)
        {
            ViewBag.Error = result.error;
            ViewBag.Email = email;
            ViewBag.ActionType = actionType;
            return View();
        }

        if (result.nextStep == "CustomerLogin")
        {
            TempData["SuccessMessage"] = "Kích hoạt tài khoản thành công! Vui lòng đăng nhập.";
            return RedirectToAction("CustomerLogin");
        }
        else if (result.nextStep == "ResetPassword")
        {
            var model = new ResetPasswordViewModel { Email = email, Token = otpCode };
            return View("ResetPassword", model);
        }

        return RedirectToAction("Login");
    }

    // Gui lai OTP
    [HttpPost]
    public async Task<IActionResult> ResendOtp(string email, string actionType)
    {
        var result = await _authService.ResendOtpAsync(email);
        return Json(new { success = result.success, message = result.message });
    }


    // Reset pass
    [HttpGet]
    public IActionResult ResetPassword(string email, string token)
    {
        if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(token))
        {
            return RedirectToAction("Login");
        }
        var model = new ResetPasswordViewModel { Email = email, Token = token };
        return View(model);
    }

    [HttpPost]
    public async Task<IActionResult> ResetPassword(ResetPasswordViewModel model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Error = "Vui lòng nhập mật khẩu hợp lệ.";
            return View(model);
        }

        var result = await _authService.ResetPasswordAsync(model);
        if (result.success)
        {
            TempData["SuccessMessage"] = "Đặt lại mật khẩu thành công! Vui lòng đăng nhập bằng mật khẩu mới.";
            return RedirectToAction("Login");
        }

        ViewBag.Error = result.error;
        return View(model);
    }



    [HttpGet]
    public IActionResult AccessDenied() => View();
}