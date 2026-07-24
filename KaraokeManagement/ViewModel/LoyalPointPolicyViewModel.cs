using System.ComponentModel.DataAnnotations;
using KaraokeManagement.Models;

namespace KaraokeManagement.ViewModel;

public class LoyalPointPolicyManagementViewModel
{
    public LoyalPointPolicyCreateViewModel NewPolicy { get; set; } = new();

    public IReadOnlyList<LoyalPointPolicy> Policies { get; set; } =
        Array.Empty<LoyalPointPolicy>();
}

public class LoyalPointPolicyCreateViewModel
{
    [Display(Name = "Số tiền cho một điểm")]
    [Range(
        typeof(decimal),
        "1",
        "9999999999999999.99",
        ErrorMessage = "Số tiền quy đổi phải lớn hơn 0.")]
    public decimal AmountPerPoint { get; set; }

    [Display(Name = "Mô tả")]
    [StringLength(255, ErrorMessage = "Mô tả không được vượt quá 255 ký tự.")]
    public string? Description { get; set; }
}
