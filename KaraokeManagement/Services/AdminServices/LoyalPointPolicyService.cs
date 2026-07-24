using System.Data;
using KaraokeManagement.Models;
using KaraokeManagement.ViewModel;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.AdminServices;

public class LoyalPointPolicyService
{
    private readonly KaraokeManagementDbContext _context;

    public LoyalPointPolicyService(KaraokeManagementDbContext context)
    {
        _context = context;
    }

    public async Task<LoyalPointPolicyManagementViewModel> GetManagementViewModelAsync(
        LoyalPointPolicyCreateViewModel? newPolicy = null)
    {
        var policies = await _context.LoyalPointPolicies
            .AsNoTracking()
            .OrderByDescending(p => p.IsActive)
            .ThenByDescending(p => p.PolicyId)
            .ToListAsync();

        return new LoyalPointPolicyManagementViewModel
        {
            NewPolicy = newPolicy ?? new LoyalPointPolicyCreateViewModel(),
            Policies = policies
        };
    }

    public async Task<(bool Success, string Message)> CreateAsync(
        LoyalPointPolicyCreateViewModel model)
    {
        if (model.AmountPerPoint <= 0)
        {
            return (false, "Số tiền quy đổi cho một điểm phải lớn hơn 0.");
        }

        await using var transaction = await _context.Database.BeginTransactionAsync(
            IsolationLevel.Serializable);

        if (await _context.LoyalPointPolicies
            .AnyAsync(p => p.AmountPerPoint == model.AmountPerPoint))
        {
            return (false, "Mức quy đổi này đã tồn tại.");
        }

        var hasActivePolicy = await _context.LoyalPointPolicies
            .AnyAsync(p => p.IsActive);

        var policy = new LoyalPointPolicy
        {
            AmountPerPoint = model.AmountPerPoint,
            Description = string.IsNullOrWhiteSpace(model.Description)
                ? null
                : model.Description.Trim(),
            IsActive = !hasActivePolicy
        };

        _context.LoyalPointPolicies.Add(policy);
        await _context.SaveChangesAsync();
        await transaction.CommitAsync();

        var message = policy.IsActive
            ? "Đã tạo và tự động áp dụng mức quy đổi đầu tiên."
            : "Đã tạo mức quy đổi mới. Hãy chọn mức này trong danh sách nếu muốn áp dụng.";

        return (true, message);
    }

    public async Task<(bool Success, string Message)> ActivateAsync(int policyId)
    {
        await using var transaction = await _context.Database.BeginTransactionAsync(
            IsolationLevel.Serializable);

        var selectedPolicy = await _context.LoyalPointPolicies
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.PolicyId == policyId);

        if (selectedPolicy == null)
        {
            return (false, "Không tìm thấy mức quy đổi đã chọn.");
        }

        if (selectedPolicy.IsActive)
        {
            return (true, $"Mức {selectedPolicy.AmountPerPoint:N0} VNĐ = 1 điểm đang được áp dụng.");
        }

        // Execute in two ordered statements so the filtered unique index never
        // observes two active policies, even temporarily.
        await _context.LoyalPointPolicies
            .Where(p => p.IsActive)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(p => p.IsActive, false));

        await _context.LoyalPointPolicies
            .Where(p => p.PolicyId == policyId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(p => p.IsActive, true));

        await transaction.CommitAsync();

        return (true, $"Đã áp dụng mức {selectedPolicy.AmountPerPoint:N0} VNĐ = 1 điểm.");
    }
}
