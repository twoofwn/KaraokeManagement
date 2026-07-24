using KaraokeManagement.Models;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.AdminServices;

public class AdminAccountService
{
    private readonly KaraokeManagementDbContext _context;

    public AdminAccountService(KaraokeManagementDbContext context)
    {
        _context = context;
    }

    public async Task<(bool Success, string Message)> SetStatusAsync(
        int currentAdminId,
        int targetAccountId,
        bool isActive)
    {
        if (currentAdminId == targetAccountId && !isActive)
        {
            return (false, "Bạn không thể khóa tài khoản đang đăng nhập.");
        }

        var account = await _context.Accounts
            .FirstOrDefaultAsync(a => a.AccountId == targetAccountId);

        if (account == null)
        {
            return (false, "Không tìm thấy tài khoản cần thay đổi.");
        }

        if (account.IsActive == isActive)
        {
            var currentStatus = isActive ? "đang hoạt động" : "đã bị khóa";
            return (true, $"Tài khoản \"{account.Username}\" {currentStatus}.");
        }

        account.IsActive = isActive;
        await _context.SaveChangesAsync();

        var actionText = isActive ? "kích hoạt" : "khóa";
        return (true, $"Đã {actionText} tài khoản \"{account.Username}\" thành công.");
    }
}
