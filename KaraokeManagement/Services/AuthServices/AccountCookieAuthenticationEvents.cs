using System.Security.Claims;
using KaraokeManagement.Models;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.AuthService;

public sealed class AccountCookieAuthenticationEvents : CookieAuthenticationEvents
{
    private readonly KaraokeManagementDbContext _context;

    public AccountCookieAuthenticationEvents(KaraokeManagementDbContext context)
    {
        _context = context;
    }

    public override async Task ValidatePrincipal(CookieValidatePrincipalContext context)
    {
        var principal = context.Principal;
        if (principal?.Identity?.IsAuthenticated != true)
        {
            return;
        }

        // Customer currently has no IsActive column. This validation applies
        // to staff accounts stored in the Account table.
        if (principal.IsInRole("Customer"))
        {
            return;
        }

        var accountIdValue = principal.FindFirstValue(ClaimTypes.NameIdentifier);
        var isValidAccountId = int.TryParse(accountIdValue, out var accountId);
        var isActiveAccount = isValidAccountId &&
            await _context.Accounts
                .AsNoTracking()
                .AnyAsync(a => a.AccountId == accountId && a.IsActive);

        if (isActiveAccount)
        {
            return;
        }

        context.RejectPrincipal();
        await context.HttpContext.SignOutAsync(context.Scheme.Name);
    }
}
