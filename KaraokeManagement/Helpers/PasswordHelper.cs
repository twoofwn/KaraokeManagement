using System;

namespace KaraokeManagement.Helpers
{
    public static class PasswordHelper
    {
        public static string HashPassword(string password)
        {
            if (string.IsNullOrEmpty(password))
            {
                return string.Empty;
            }
            return BCrypt.Net.BCrypt.HashPassword(password);
        }


        public static bool VerifyPassword(string inputPassword, string storedPasswordHash)
        {
            if (string.IsNullOrEmpty(inputPassword) || string.IsNullOrEmpty(storedPasswordHash))
            {
                return false;
            }

            if (IsBCryptHash(storedPasswordHash))
            {
                try
                {
                    return BCrypt.Net.BCrypt.Verify(inputPassword, storedPasswordHash);
                }
                catch
                {
                    return false;
                }
            }

            return inputPassword == storedPasswordHash;
        }

        public static bool IsBCryptHash(string hash)
        {
            if (string.IsNullOrEmpty(hash))
            {
                return false;
            }
            return hash.StartsWith("$2") && hash.Length == 60;
        }
    }
}
