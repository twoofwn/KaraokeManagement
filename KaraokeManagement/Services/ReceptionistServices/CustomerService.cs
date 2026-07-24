using KaraokeManagement.Controllers;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;


namespace KaraokeManagement.Services.ReceptionistServices;
public class CustomerService
{
    private readonly KaraokeManagementDbContext _context;
    public CustomerService(KaraokeManagementDbContext context) => _context = context;

    public async Task<object> GetCustomerByPhoneAsync(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone) || !KaraokeManagement.Helpers.ValidationHelper.IsValidPhoneNumber(phone, allowGuestDefault: true))
            return new { found = false };

        var customer = await _context.Customers.Include(c => c.Tier).FirstOrDefaultAsync(c => c.Phone == phone);
        if (customer == null) return new { found = false };

        return new { found = true, customerId = customer.CustomerId, fullName = customer.FullName, phone = customer.Phone, points = customer.LoyaltyPoints ?? 0, tierName = customer.Tier?.TierName ?? "THƯỜNG" };
    }

    public async Task<(bool success, string message, object? data)> CreateCustomerAsync(CreateCustomerRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.FullName)) return (false, "Họ và tên là bắt buộc.", null);
        if (!KaraokeManagement.Helpers.ValidationHelper.IsValidPhoneNumber(request.Phone, allowGuestDefault: false)) return (false, "Số điện thoại không hợp lệ.", null);
        if (await _context.Customers.AnyAsync(c => c.Phone == request.Phone)) return (false, "Số điện thoại đã tồn tại.", null);

        var defaultTier = await _context.MembershipTiers.OrderBy(t => t.MinPoints).FirstOrDefaultAsync();
        var customer = new Customer { Phone = request.Phone, FullName = request.FullName, Email = request.Email, LoyaltyPoints = 0, TierId = defaultTier?.TierId, CreatedAt = DateTime.Now };

        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();

        return (true, string.Empty, new { customerId = customer.CustomerId, fullName = customer.FullName, phone = customer.Phone, points = 0, tierName = defaultTier?.TierName ?? "THƯỜNG" });
    }
}