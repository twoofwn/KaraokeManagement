using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using KaraokeManagement.Models;

namespace KaraokeManagement.Pages.Staff.SwapRequests
{
    [Authorize]
    public class IndexModel : PageModel
    {
        private readonly KaraokeManagementDbContext _context;

        public IndexModel(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public List<ShiftSwapRequest> ReceivedRequests { get; set; } = new List<ShiftSwapRequest>();
        public List<ShiftSwapRequest> SentRequests { get; set; } = new List<ShiftSwapRequest>();
        public Account CurrentAccount { get; set; } = null!;

        public async Task<IActionResult> OnGetAsync()
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId))
            {
                return RedirectToAction("Login", "Auth");
            }

            CurrentAccount = await _context.Accounts
                .Include(a => a.Role)
                .FirstOrDefaultAsync(a => a.AccountId == accountId);

            if (CurrentAccount == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            ReceivedRequests = await _context.ShiftSwapRequests
                .Include(r => r.Requester).ThenInclude(a => a.Role)
                .Include(r => r.RequesterSchedule).ThenInclude(s => s.Shift)
                .Include(r => r.TargetSchedule).ThenInclude(s => s.Shift)
                .Where(r => r.TargetId == accountId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            SentRequests = await _context.ShiftSwapRequests
                .Include(r => r.Target).ThenInclude(a => a.Role)
                .Include(r => r.RequesterSchedule).ThenInclude(s => s.Shift)
                .Include(r => r.TargetSchedule).ThenInclude(s => s.Shift)
                .Where(r => r.RequesterId == accountId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return Page();
        }

        public async Task<IActionResult> OnPostAcceptAsync(int requestId)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId))
            {
                return RedirectToAction("Login", "Auth");
            }

            var request = await _context.ShiftSwapRequests
                .Include(r => r.RequesterSchedule)
                .Include(r => r.TargetSchedule)
                .FirstOrDefaultAsync(r => r.SwapRequestId == requestId);

            if (request == null)
            {
                TempData["ErrorMessage"] = "Yêu cầu đổi ca không tồn tại.";
                return RedirectToPage();
            }

            if (request.TargetId != accountId)
            {
                TempData["ErrorMessage"] = "Bạn không có quyền đồng ý yêu cầu này.";
                return RedirectToPage();
            }

            if (request.Status != "Pending")
            {
                TempData["ErrorMessage"] = "Yêu cầu này đã được xử lý trước đó.";
                return RedirectToPage();
            }

            if (request.RequesterSchedule == null || request.TargetSchedule == null)
            {
                TempData["ErrorMessage"] = "Lịch làm việc liên quan không còn tồn tại.";
                return RedirectToPage();
            }

            var reqSched = request.RequesterSchedule;
            var tarSched = request.TargetSchedule;

            // CRITICAL BUSINESS RULE (Schedule Overlap Check)
            bool targetHasOverlap = await _context.EmployeeSchedules.AnyAsync(s => 
                s.AccountId == accountId && 
                s.WorkDate == reqSched.WorkDate && 
                s.ShiftId == reqSched.ShiftId && 
                s.IsActive && 
                s.Status != "Off" &&
                s.ScheduleId != tarSched.ScheduleId);

            if (targetHasOverlap)
            {
                TempData["ErrorMessage"] = "Không thể đổi ca do bạn đã có lịch làm việc trong ca và ngày này.";
                return RedirectToPage();
            }

            // Database Transaction
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    // Swap AccountIds
                    int tempAccountId = reqSched.AccountId;
                    reqSched.AccountId = tarSched.AccountId;
                    tarSched.AccountId = tempAccountId;

                    // Update Request Status to Approved
                    request.Status = "Approved";

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    TempData["SuccessMessage"] = "Đồng ý đổi ca thành công! Lịch làm việc của bạn đã được cập nhật.";
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    TempData["ErrorMessage"] = "Đã xảy ra lỗi trong quá trình xử lý: " + ex.Message;
                }
            }

            return RedirectToPage();
        }

        public async Task<IActionResult> OnPostRejectAsync(int requestId)
        {
            string? idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idClaim, out int accountId))
            {
                return RedirectToAction("Login", "Auth");
            }

            var request = await _context.ShiftSwapRequests.FindAsync(requestId);

            if (request == null)
            {
                TempData["ErrorMessage"] = "Yêu cầu đổi ca không tồn tại.";
                return RedirectToPage();
            }

            if (request.TargetId != accountId)
            {
                TempData["ErrorMessage"] = "Bạn không có quyền từ chối yêu cầu này.";
                return RedirectToPage();
            }

            if (request.Status != "Pending")
            {
                TempData["ErrorMessage"] = "Yêu cầu này đã được xử lý trước đó.";
                return RedirectToPage();
            }

            request.Status = "Rejected";
            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = "Đã từ chối yêu cầu đổi ca thành công.";
            return RedirectToPage();
        }
    }
}
