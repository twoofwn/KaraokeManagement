using System.Net;
using System.Net.Mail;

namespace KaraokeManagement.Service
{
    public interface IEmailService
    {
        Task SendEmailAsync(string toEmail, string subject, string body);
    }

    namespace KaraokeManagement.Services
    {
        public class EmailService : IEmailService
        {
            private readonly IConfiguration _configuration;

            public EmailService(IConfiguration configuration)
            {
                _configuration = configuration;
            }

            public async Task SendEmailAsync(string toEmail, string subject, string body)
            {
                var smtpServer = _configuration["Smtp:Server"] ?? "smtp.gmail.com";
                var smtpPort = int.Parse(_configuration["Smtp:Port"] ?? "587");
                var senderEmail = _configuration["Smtp:SenderEmail"];
                var senderPassword = _configuration["Smtp:SenderPassword"]; 

                using var client = new SmtpClient(smtpServer, smtpPort)
                {
                    Credentials = new NetworkCredential(senderEmail, senderPassword),
                    EnableSsl = true
                };

                var mailMessage = new MailMessage
                {
                    From = new MailAddress(senderEmail!, "Minh Tuấn Karaoke"),
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                };
                mailMessage.To.Add(toEmail);

                await client.SendMailAsync(mailMessage);
            }
        }
    }
}
