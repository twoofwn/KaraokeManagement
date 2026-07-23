using KaraokeManagement.Helpers;
using KaraokeManagement.Models;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.CustomerServices
{
    public class CustomerService
    {
        private readonly KaraokeManagementDbContext _context;
        public CustomerService(KaraokeManagementDbContext context) { _context = context; }

        public async Task<Customer> GetCustomerProfileAsync(int customerId)
        {
            return await _context.Customers.Include(c => c.Tier).FirstOrDefaultAsync(c => c.CustomerId == customerId);
        }

        public async Task<(bool Success, string Message)> UpdateProfileAsync(int customerId, string fullName, string phone)
        {
            var customer = await _context.Customers.FindAsync(customerId);
            if (customer == null) return (false, "Không tìm thấy khách hàng.");

            bool isPhoneDup = await _context.Customers.AnyAsync(c => c.Phone == phone && c.CustomerId != customerId);
            if (isPhoneDup) return (false, "Số điện thoại này đã được sử dụng bởi tài khoản khác.");

            customer.FullName = fullName.Trim();
            customer.Phone = phone.Trim();
            _context.Customers.Update(customer);
            await _context.SaveChangesAsync();

            return (true, "Cập nhật thông tin cá nhân thành công!");
        }

        public async Task<(bool Success, string Message)> ChangePasswordAsync(int customerId, string oldPassword, string newPassword)
        {
            var customer = await _context.Customers.FindAsync(customerId);
            if (customer == null) return (false, "Không tìm thấy khách hàng.");

            if (!Helpers.PasswordHelper.VerifyPassword(oldPassword, customer.PasswordHash))
                return (false, "Mật khẩu cũ không chính xác.");

            customer.PasswordHash = Helpers.PasswordHelper.HashPassword(newPassword);
            _context.Customers.Update(customer);
            await _context.SaveChangesAsync();

            return (true, "Đổi mật khẩu thành công!");
        }
    }
}
