using System;
using System.Text.RegularExpressions;

namespace KaraokeManagement.Helpers
{
    public static class ValidationHelper
    {
        private static readonly Regex VietnamPhoneRegex = new Regex(@"^(0)[0-9]{9}$", RegexOptions.Compiled);
        public static bool IsValidPhoneNumber(string? phoneNumber, bool allowGuestDefault = true)
        {
            if (string.IsNullOrWhiteSpace(phoneNumber))
            {
                return false;
            }

            var cleanPhone = phoneNumber.Replace(" ", "")
                                        .Replace("-", "")
                                        .Replace("(", "")
                                        .Replace(")", "");

            if (allowGuestDefault && cleanPhone == "0000000000")
            {
                return true;
            }

            return VietnamPhoneRegex.IsMatch(cleanPhone);
        }

        public static bool IsValidPhoneNumberCustomer(string phoneNumber)
        {
            if (string.IsNullOrWhiteSpace(phoneNumber))
            {
                return false;
            }

            var cleanPhone = phoneNumber.Replace(" ", "")
                                        .Replace("-", "")
                                        .Replace("(", "")
                                        .Replace(")", "");

            return VietnamPhoneRegex.IsMatch(cleanPhone);
        }
    }
}
