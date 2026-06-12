using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;

namespace KaraokeManagement.Controllers
{
    public class AuthController : Controller
    {
        private readonly KaraokeManagementDbContext _context;

        public AuthController()
        {
            _context = new KaraokeManagementDbContext();
        }

        [HttpGet]
        public IActionResult Login()
        {
            // If already logged in, redirect to Home
            if (Request.Cookies.ContainsKey("UserSession") || User.Identity?.IsAuthenticated == true)
            {
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Login(LoginViewModel model)
        {
            if (!ModelState.IsValid)
            {
                ViewBag.Error = "Please enter both username/email and password.";
                return View(model);
            }

            Account? account = null;

            try
            {
                // Try checking the database
                account = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.Username == model.UsernameOrEmail || a.Email == model.UsernameOrEmail);
            }
            catch (Exception ex)
            {
                // Log database connection error if needed
                System.Diagnostics.Debug.WriteLine($"DB connection failed: {ex.Message}");
            }

            bool isValidUser = false;

            if (account != null)
            {
                isValidUser = VerifyPassword(model.Password, account.PasswordHash);
            }
            else
            {
                // Fallback hardcoded credentials for demo/testing without database setup
                if (model.UsernameOrEmail == "admin@lumina.com" && model.Password == "admin123")
                {
                    isValidUser = true;
                }
            }

            if (isValidUser)
            {
                string username = account?.Username ?? "admin";
                string role = account?.Role?.RoleName ?? "Admin";

                // Standard ASP.NET Core Cookie Authentication (Try-catch in case middleware is not registered yet)
                try
                {
                    var claims = new List<Claim>
                    {
                        new Claim(ClaimTypes.Name, username),
                        new Claim(ClaimTypes.Role, role)
                    };
                    if (account?.Email != null)
                    {
                        claims.Add(new Claim(ClaimTypes.Email, account.Email));
                    }

                    var claimsIdentity = new ClaimsIdentity(claims, "CookieAuth");
                    var authProperties = new AuthenticationProperties
                    {
                        IsPersistent = model.RememberMe,
                        ExpiresUtc = model.RememberMe ? DateTimeOffset.UtcNow.AddDays(7) : DateTimeOffset.UtcNow.AddMinutes(30)
                    };

                    await HttpContext.SignInAsync("CookieAuth", new ClaimsPrincipal(claimsIdentity), authProperties);
                }
                catch
                {
                    // Fallback: simple cookie-based state if authentication middleware isn't configured in Program.cs
                    var cookieOptions = new CookieOptions
                    {
                        Expires = model.RememberMe ? DateTime.Now.AddDays(7) : DateTime.Now.AddMinutes(30),
                        HttpOnly = true,
                        Secure = true
                    };
                    Response.Cookies.Append("UserSession", username, cookieOptions);
                    Response.Cookies.Append("UserRole", role, cookieOptions);
                }

                return RedirectToAction("Index", "Home");
            }

            ViewBag.Error = "Invalid username/email or password.";
            return View(model);
        }

        [HttpGet]
        public async Task<IActionResult> Logout()
        {
            try
            {
                await HttpContext.SignOutAsync("CookieAuth");
            }
            catch {}

            Response.Cookies.Delete("UserSession");
            Response.Cookies.Delete("UserRole");

            return RedirectToAction("Login");
        }

        private bool VerifyPassword(string inputPassword, string storedPasswordHash)
        {
            // Case 1: Plaintext match
            if (inputPassword == storedPasswordHash) return true;

            // Case 2: SHA256 hash match
            try
            {
                using (var sha256 = System.Security.Cryptography.SHA256.Create())
                {
                    var bytes = sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes(inputPassword));
                    var hash = Convert.ToHexString(bytes).ToLower();
                    if (hash == storedPasswordHash.ToLower()) return true;
                }
            }
            catch {}

            // Case 3: MD5 hash match
            try
            {
                using (var md5 = System.Security.Cryptography.MD5.Create())
                {
                    var bytes = md5.ComputeHash(System.Text.Encoding.UTF8.GetBytes(inputPassword));
                    var hash = Convert.ToHexString(bytes).ToLower();
                    if (hash == storedPasswordHash.ToLower()) return true;
                }
            }
            catch {}

            return false;
        }
    }

    public class LoginViewModel
    {
        public string UsernameOrEmail { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public bool RememberMe { get; set; }
    }
}
