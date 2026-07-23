using KaraokeManagement.Models;
using Microsoft.EntityFrameworkCore;

namespace KaraokeManagement.Services.CustomerServices
{
    public class FeedbackService
    {
        private readonly KaraokeManagementDbContext _context;
        public FeedbackService(KaraokeManagementDbContext context)
        {
            _context = context;
        }

        public async Task<(bool Success, string Message)> SendBookingReportAsync(int customerId, int bookingId, string message)
        {
            var booking = await _context.Bookings.FirstOrDefaultAsync(b => b.BookingId == bookingId && b.CustomerId == customerId);
            if (booking == null) return (false, "Lỗi xác thực.");
            if (booking.Status != "CheckedIn") return (false, "Chỉ có thể gửi báo cáo khi phòng đang được sử dụng.");
            if (string.IsNullOrWhiteSpace(message)) return (false, "Vui lòng nhập nội dung báo cáo.");

            _context.NotificationLogs.Add(new NotificationLog
            {
                BookingId = bookingId,
                CustomerId = customerId,
                Channel = "Web",
                Recipient = "Receptionist",
                MessageContent = message.Trim(),
                SentStatus = "Sent",
                SentAt = DateTime.Now
            });
            await _context.SaveChangesAsync();
            return (true, "Báo cáo sự cố đã được gửi thành công!");
        }

        public async Task<(bool Success, string Message)> SubmitReviewAsync(int customerId, int bookingId, int invoiceId, int rating, string comment)
        {
            var booking = await _context.Bookings.Include(b => b.Invoices).FirstOrDefaultAsync(b => b.BookingId == bookingId && b.CustomerId == customerId);
            if (booking == null) return (false, "Lỗi xác thực.");
            if (booking.Status != "Completed") return (false, "Chỉ có thể đánh giá sau khi hoàn thành phòng hát.");
            if (!booking.Invoices.Any(i => i.InvoiceId == invoiceId)) return (false, "Không tìm thấy hóa đơn liên kết.");
            if (await _context.CustomerReviews.AnyAsync(r => r.BookingId == bookingId)) return (false, "Bạn đã đánh giá cho lượt hát này rồi.");
            if (rating < 1 || rating > 5) return (false, "Vui lòng chọn số sao từ 1 đến 5.");

            _context.CustomerReviews.Add(new CustomerReview { Rating = rating, Comment = comment?.Trim(), CreatedAt = DateTime.Now, BookingId = bookingId });
            await _context.SaveChangesAsync();
            return (true, "Cảm ơn bạn đã đánh giá!");
        }

        public async Task<CustomerReview> GetReviewByBookingIdAsync(int bookingId) { return await _context.CustomerReviews.FirstOrDefaultAsync(r => r.BookingId == bookingId); }


        public async Task<List<NotificationLog>> GetReportsByBookingIdAsync(int bookingId, int customerId) { return await _context.NotificationLogs.Where(n => n.BookingId == bookingId && n.CustomerId == customerId).OrderByDescending(n => n.SentAt).ToListAsync(); }
    }
}
