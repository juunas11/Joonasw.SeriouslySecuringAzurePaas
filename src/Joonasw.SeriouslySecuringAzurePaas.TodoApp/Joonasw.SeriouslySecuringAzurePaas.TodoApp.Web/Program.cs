using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.UI;

namespace Joonasw.SeriouslySecuringAzurePaas.TodoApp.Web;
public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add services to the container.
        builder.Services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
            .AddMicrosoftIdentityWebApp(
                msIdOptions =>
                {
                    builder.Configuration.GetSection("EntraId").Bind(msIdOptions);
                },
                cookieOptions =>
                {
                    // Shorten the cookie lifetime for increased security.
                    // _Don't do this in an actual app._
                    // This sucks for UX.
                    cookieOptions.ExpireTimeSpan = TimeSpan.FromMinutes(1);
                    cookieOptions.SlidingExpiration = false;

                    // Only top-level navigation requests can set cookies.
                    cookieOptions.Cookie.SameSite = SameSiteMode.Strict;
                    // Always over HTTPS.
                    cookieOptions.Cookie.SecurePolicy = CookieSecurePolicy.Always;
                    // Don't allow Javascript to access the cookie.
                    cookieOptions.Cookie.HttpOnly = true;
                },
                openIdConnectScheme: OpenIdConnectDefaults.AuthenticationScheme,
                cookieScheme: CookieAuthenticationDefaults.AuthenticationScheme);

        builder.Services.AddAuthorization(options =>
        {
            // By default, all incoming requests will be authorized according to the default policy.
            options.FallbackPolicy = options.DefaultPolicy;
        });
        builder.Services.AddRazorPages()
            .AddMicrosoftIdentityUI();

        var app = builder.Build();

        // Configure the HTTP request pipeline.
        if (!app.Environment.IsDevelopment())
        {
            app.UseExceptionHandler("/Error");
            // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
            app.UseHsts();
        }

        app.UseHttpsRedirection();
        app.UseStaticFiles();

        app.UseRouting();

        app.UseAuthentication();
        app.UseAuthorization();

        app.MapRazorPages();
        app.MapControllers();

        app.Run();
    }
}
