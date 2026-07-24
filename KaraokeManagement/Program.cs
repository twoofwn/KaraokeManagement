using KaraokeManagement.Models;
using KaraokeManagement.Services;
using KaraokeManagement.Services.ManagerServices;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();
builder.Services.AddRazorPages();
builder.Services.AddDbContext<KaraokeManagementDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("MyCnn")));
builder.Services.AddScoped<KaraokeManagement.Services.IScheduleService, KaraokeManagement.Services.ScheduleService>();
builder.Services.AddScoped<EmailService>();
builder.Services.AddScoped<PricePolicyService>();

// Auth
builder.Services.AddScoped<KaraokeManagement.Services.AuthService.AuthService>();

// Receptionist
builder.Services.AddScoped<KaraokeManagement.Services.ReceptionistServices.DashboardService>();
builder.Services.AddScoped<KaraokeManagement.Services.ReceptionistServices.OrderService>();
builder.Services.AddScoped<KaraokeManagement.Services.ReceptionistServices.RoomBookingService>();
builder.Services.AddScoped<KaraokeManagement.Services.ReceptionistServices.PaymentService>();
builder.Services.AddScoped<KaraokeManagement.Services.ReceptionistServices.CustomerService>();
builder.Services.AddScoped<KaraokeManagement.Services.ReceptionistServices.InvoiceService>();
builder.Services.AddScoped<KaraokeManagement.Services.ReceptionistServices.ReceptionistBookingService>();

//Customer Service
builder.Services.AddScoped<KaraokeManagement.Services.CustomerServices.CustomerService>();
builder.Services.AddScoped<KaraokeManagement.Services.CustomerServices.RoomService>();
builder.Services.AddScoped<KaraokeManagement.Services.CustomerServices.BookingService>();
builder.Services.AddScoped<KaraokeManagement.Services.CustomerServices.ServiceItemService>();
builder.Services.AddScoped<KaraokeManagement.Services.CustomerServices.FeedbackService>();

//Manager Service
builder.Services.AddScoped<KaraokeManagement.Services.ManagerServices.DashboardService>();
builder.Services.AddScoped<KaraokeManagement.Services.ManagerServices.InventoryService>();
builder.Services.AddScoped<KaraokeManagement.Services.ManagerServices.ExpenseService>();
builder.Services.AddScoped<KaraokeManagement.Services.ManagerServices.InvoiceService>();
builder.Services.AddScoped<KaraokeManagement.Services.ManagerServices.PricingService>();

//HRM
builder.Services.AddScoped<KaraokeManagement.Services.HRMServices.HRMService>();

//Staff Services
builder.Services.AddScoped<KaraokeManagement.Services.StaffServices.StaffService>();

builder.Services.AddAuthentication("CookieAuth")
    .AddCookie("CookieAuth", options =>
    {
        options.LoginPath = "/Auth/Login";
        options.AccessDeniedPath = "/Auth/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromDays(7);
    });

var app = builder.Build();



// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();
app.UseStatusCodePagesWithReExecute("/Error/{0}");
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");
app.MapRazorPages();

app.Run();
