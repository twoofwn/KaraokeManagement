namespace KaraokeManagement.Services.AuthService;

using KaraokeManagement.Helpers;
using KaraokeManagement.Models;
using KaraokeManagement.Services;
using KaraokeManagement.ViewModel;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

public class AuthService
{
    private readonly KaraokeManagementDbContext _context;
    private readonly EmailService _emailService;

    public AuthService(KaraokeManagementDbContext context, EmailService emailService)
    {
        _context = context;
        _emailService = emailService;
    }

    // Dang nhap staff
    public async Task<(bool success, string error, ClaimsPrincipal? principal, string role)> AuthenticateStaffAsync(LoginViewModel model)
    {
        Account? account = null;
        try
        {
            account = await _context.Accounts
                .Include(a => a.Role)
                .FirstOrDefaultAsync(a => a.Username == model.UsernameOrEmail || a.Email == model.UsernameOrEmail);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"DB connection failed: {ex.Message}");
        }

        bool isValidUser = false;
        if (account != null)
        {
            if (!account.IsActive)
                return (false, "Tài khoản của bạn đã bị khóa hoặc ngừng hoạt động. Vui lòng liên hệ Admin qua số điện thoại 0868754128", null, string.Empty);

            isValidUser = PasswordHelper.VerifyPassword(model.Password, account.PasswordHash);
            if (isValidUser && !PasswordHelper.IsBCryptHash(account.PasswordHash))
            {
                try
                {
                    account.PasswordHash = PasswordHelper.HashPassword(model.Password);
                    _context.Accounts.Update(account);
                    await _context.SaveChangesAsync();
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Failed to auto-upgrade password hash: {ex.Message}");
                }
            }
        }

        if (isValidUser)
        {
            string username = account?.FullName ?? "Admin";
            string role = account?.Role?.RoleName ?? "Admin";
            string accountIdStr = account?.AccountId.ToString() ?? "0";

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, accountIdStr),
                new Claim("AccountId", accountIdStr),
                new Claim(ClaimTypes.Name, username),
                new Claim(ClaimTypes.Role, role)
            };
            if (account?.Email != null) claims.Add(new Claim(ClaimTypes.Email, account.Email));

            var claimsIdentity = new ClaimsIdentity(claims, "CookieAuth");
            return (true, string.Empty, new ClaimsPrincipal(claimsIdentity), role);
        }

        return (false, "Tên đăng nhập/Email hoặc mật khẩu không hợp lệ.", null, string.Empty);
    }

    // Dang nhap customer
    public async Task<(bool success, string error, ClaimsPrincipal? principal, bool requireOtp, string email)> AuthenticateCustomerAsync(string email, string password)
    {
        if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password))
            return (false, "Vui lòng nhập đầy đủ thông tin đăng nhập.", null, false, string.Empty);

        var customer = await _context.Customers.FirstOrDefaultAsync(c => c.Email == email);
        if (customer != null && PasswordHelper.VerifyPassword(password, customer.PasswordHash))
        {
            if (!customer.IsEmailVerified)
            {
                string newOtp = GenerateOtpCode();
                customer.OtpCode = newOtp;
                customer.OtpExpiry = DateTime.Now.AddMinutes(30);

                _context.Customers.Update(customer);
                await _context.SaveChangesAsync();

                string emailBody = $@"
                    <h2>Xác thực tài khoản - Minh Tuấn Karaoke</h2>
                    <p>Tài khoản của bạn chưa được kích hoạt. Mã OTP kích hoạt mới là: <b style='font-size: 20px; color: #4F46E5;'>{newOtp}</b></p>
                    <p>Mã này có hiệu lực trong 30 phút.</p>";

                await _emailService.SendEmailAsync(customer.Email!, "Mã OTP Kích hoạt tài khoản", emailBody);

                return (false, "Tài khoản của bạn chưa kích hoạt. Mã OTP mới đã được gửi tới email, vui lòng nhập để kích hoạt!", null, true, customer.Email!);
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, customer.CustomerId.ToString()),
                new Claim(ClaimTypes.Name, customer.FullName),
                new Claim(ClaimTypes.Role, "Customer")
            };
            if (!string.IsNullOrEmpty(customer.Email)) claims.Add(new Claim(ClaimTypes.Email, customer.Email));

            var claimsIdentity = new ClaimsIdentity(claims, "CookieAuth");
            return (true, string.Empty, new ClaimsPrincipal(claimsIdentity), false, string.Empty);
        }

        return (false, "Email hoặc mật khẩu không đúng.", null, false, string.Empty);
    }

    // Dang ky customer
    public async Task<(bool success, string error, string email)> RegisterCustomerAsync(RegisterViewModel model)
    {
        bool exists = await _context.Customers.AnyAsync(c => c.Phone == model.Phone || c.Email == model.Email);
        if (exists) return (false, "Số điện thoại hoặc Email đã được đăng ký.", string.Empty);

        string otp = GenerateOtpCode();
        var newCustomer = new Customer
        {
            TierId = 0,
            FullName = model.FullName,
            Phone = model.Phone,
            Email = model.Email,
            PasswordHash = PasswordHelper.HashPassword(model.Password),
            LoyaltyPoints = 0,
            CreatedAt = DateTime.Now,
            IsEmailVerified = false,
            OtpCode = otp,
            OtpExpiry = DateTime.Now.AddMinutes(30)
        };

        _context.Customers.Add(newCustomer);
        await _context.SaveChangesAsync();

        string emailBody = $@"
            <h2>Mã xác thực OTP - Minh Tuấn Karaoke</h2>
            <p>Chào <b>{model.FullName}</b>,</p>
            <p>Mã OTP đăng ký tài khoản của bạn là: <b style='font-size: 20px; color: #4F46E5;'>{otp}</b></p>
            <p>Mã này có hiệu lực trong 30 phút.</p>";

        await _emailService.SendEmailAsync(model.Email, "Mã OTP Kích hoạt tài khoản - Minh Tuấn Karaoke", emailBody);
        return (true, string.Empty, model.Email);
    }

    // Forgot pass
    public async Task<(bool success, string error)> SendForgotPasswordOtpAsync(string email)
    {
        if (string.IsNullOrEmpty(email)) return (false, "Vui lòng nhập Email.");

        var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Email == email);
        var customer = await _context.Customers.FirstOrDefaultAsync(c => c.Email == email);

        if (account == null && customer == null) return (false, "Email không tồn tại trong hệ thống.");

        string otp = GenerateOtpCode();
        DateTime expiry = DateTime.Now.AddMinutes(30);

        if (account != null)
        {
            account.OtpCode = otp;
            account.OtpExpiry = expiry;
            _context.Accounts.Update(account);
        }
        else if (customer != null)
        {
            customer.OtpCode = otp;
            customer.OtpExpiry = expiry;
            _context.Customers.Update(customer);
        }

        await _context.SaveChangesAsync();

        string emailBody = $@"
            <h2>Mã OTP Đặt lại mật khẩu - Minh Tuấn Karaoke</h2>
            <p>Mã OTP của bạn là: <b style='font-size: 20px; color: #4F46E5;'>{otp}</b></p>
            <p>Mã này có hiệu lực trong 30 phút.</p>";

        await _emailService.SendEmailAsync(email, "Mã OTP Đặt lại mật khẩu - Minh Tuấn Karaoke", emailBody);
        return (true, string.Empty);
    }

    // Xac minh OTP
    public async Task<(bool success, string error, string nextStep)> VerifyOtpAsync(string email, string otpCode, string actionType)
    {
        if (string.IsNullOrEmpty(otpCode)) return (false, "Vui lòng nhập mã OTP.", string.Empty);

        if (actionType == "Register")
        {
            var customer = await _context.Customers.FirstOrDefaultAsync(c => c.Email == email && c.OtpCode == otpCode);
            if (customer == null || customer.OtpExpiry < DateTime.Now)
                return (false, "Mã OTP không đúng hoặc đã hết hạn.", string.Empty);

            customer.IsEmailVerified = true;
            customer.OtpCode = null;
            customer.OtpExpiry = null;

            _context.Customers.Update(customer);
            await _context.SaveChangesAsync();
            return (true, string.Empty, "CustomerLogin");
        }
        else if (actionType == "ResetPassword")
        {
            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Email == email && a.OtpCode == otpCode);
            var customer = await _context.Customers.FirstOrDefaultAsync(c => c.Email == email && c.OtpCode == otpCode);

            bool isValid = (account != null && account.OtpExpiry >= DateTime.Now) ||
                           (customer != null && customer.OtpExpiry >= DateTime.Now);

            if (!isValid) return (false, "Mã OTP không đúng hoặc đã hết hạn.", string.Empty);

            return (true, string.Empty, "ResetPassword");
        }

        return (false, "Hành động không hợp lệ.", string.Empty);
    }

    // Gui lai OTP
    public async Task<(bool success, string message)> ResendOtpAsync(string email)
    {
        if (string.IsNullOrEmpty(email)) return (false, "Email không hợp lệ!");

        string newOtp = GenerateOtpCode();
        DateTime expiry = DateTime.Now.AddMinutes(30);

        var customer = await _context.Customers.FirstOrDefaultAsync(c => c.Email == email);
        if (customer != null)
        {
            customer.OtpCode = newOtp;
            customer.OtpExpiry = expiry;
            _context.Customers.Update(customer);
        }
        else
        {
            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Email == email);
            if (account != null)
            {
                account.OtpCode = newOtp;
                account.OtpExpiry = expiry;
                _context.Accounts.Update(account);
            }
            else
            {
                return (false, "Không tìm thấy thông tin tài khoản!");
            }
        }

        await _context.SaveChangesAsync();

        string emailBody = $@"
            <h2>Mã OTP mới - Minh Tuấn Karaoke</h2>
            <p>Mã xác thực OTP mới của bạn là: <b style='font-size: 20px; color: #4F46E5;'>{newOtp}</b></p>
            <p>Mã này có hiệu lực trong 30 phút.</p>";

        await _emailService.SendEmailAsync(email, "Mã OTP mới - Minh Tuấn Karaoke", emailBody);
        return (true, "Mã OTP mới đã được gửi vào Email của bạn!");
    }

    // Reset Password
    public async Task<(bool success, string error)> ResetPasswordAsync(ResetPasswordViewModel model)
    {
        if (string.IsNullOrEmpty(model.Email) || string.IsNullOrEmpty(model.NewPassword))
        {
            return (false, "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.");
        }

        try
        {
            string newHash = PasswordHelper.HashPassword(model.NewPassword);
            bool updated = false;

            // Check trong bang Account
            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Email == model.Email);
            if (account != null)
            {
                account.PasswordHash = newHash;
                _context.Accounts.Update(account);
                updated = true;
            }

            // Check trong bang customer
            if (!updated)
            {
                var customer = await _context.Customers.FirstOrDefaultAsync(c => c.Email == model.Email);
                if (customer != null)
                {
                    customer.PasswordHash = newHash;
                    _context.Customers.Update(customer);
                    updated = true;
                }
            }

            // Luu
            if (updated)
            {
                await _context.SaveChangesAsync();
                return (true, string.Empty);
            }

            return (false, "Không tìm thấy tài khoản tương ứng với Email này trong hệ thống.");
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Lỗi đặt lại mật khẩu: {ex.Message}");
            return (false, "Có lỗi xảy ra trong quá trình lưu mật khẩu mới. Vui lòng thử lại sau.");
        }
    }

    // Random OTP
    private string GenerateOtpCode()
    {
        return new Random().Next(100000, 999999).ToString();
    }
}