using Azure.Core;
using Azure.Identity;
using Joonasw.SeriouslySecuringAzurePaas.TodoApp.Data;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.UI;
using OwaspHeaders.Core.Extensions;
using OwaspHeaders.Core.Models;

namespace Joonasw.SeriouslySecuringAzurePaas.TodoApp.Web;
public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        TelemetryClient? telemetryClient = null;
        var appInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
        if (!string.IsNullOrEmpty(appInsightsConnectionString))
        {
            var telemetryConfiguration = TelemetryConfiguration.CreateDefault();
            telemetryConfiguration.ConnectionString = appInsightsConnectionString;
            telemetryClient = new TelemetryClient(telemetryConfiguration);
        }

        try
        {
            // TODO: Add other security headers (A+ on Mozilla Observatory)
            builder.Services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
                .AddMicrosoftIdentityWebApp(
                    msIdOptions =>
                    {
                        builder.Configuration.GetSection("EntraId").Bind(msIdOptions);

                        msIdOptions.CorrelationCookie.SecurePolicy = CookieSecurePolicy.Always;
                    },
                    cookieOptions =>
                    {
                        // Shorten the cookie lifetime for increased security.
                        // _Don't do this in an actual app._
                        // This sucks for UX.
                        cookieOptions.ExpireTimeSpan = TimeSpan.FromMinutes(1);
                        cookieOptions.SlidingExpiration = false;

                        // Cookies is added only with requests from the same domain
                        // or from top level navigations from other sites.
                        // Setting this to Strict causes Entra ID authentication loops.
                        cookieOptions.Cookie.SameSite = SameSiteMode.Lax;
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

            builder.Services.AddDbContext<TodoContext>(options =>
            {
                options.UseSqlServer(builder.Configuration.GetConnectionString("Sql"));
            });

            // Data protection is used to encrypt the session cookie.
            // We configure it to use Azure Blob Storage for key storage
            // and Azure Key Vault for encrypting the keys.
            // This way you can only get the keys if you have access
            // to both the storage account and the key vault.
            var dataProtectionStorabeBlobUri = builder.Configuration["DataProtection:StorageBlobUri"];
            var dataProtectionManagedHsmKeyUri = builder.Configuration["DataProtection:ManagedHsmKeyUri"];
            if (!string.IsNullOrEmpty(dataProtectionStorabeBlobUri)
                && !string.IsNullOrEmpty(dataProtectionManagedHsmKeyUri))
            {
                TokenCredential tokenCredential = builder.Environment.IsDevelopment()
                    ? new AzureCliCredential(new AzureCliCredentialOptions
                    {
                        TenantId = builder.Configuration["DataProtection:EntraTenantId"]
                    })
                    : new ManagedIdentityCredential();
                builder.Services.AddDataProtection()
                    .PersistKeysToAzureBlobStorage(new Uri(builder.Configuration["DataProtection:StorageBlobUri"]!), tokenCredential)
                    .ProtectKeysWithAzureKeyVault(new Uri(builder.Configuration["DataProtection:ManagedHsmKeyUri"]!), tokenCredential);
            }

            builder.Services.AddApplicationInsightsTelemetry();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (!app.Environment.IsDevelopment())
            {
                app.UseExceptionHandler("/Error");
            }

            app.Use(async (context, next) =>
            {
                // Disable all of those features in the client
                // These are all non-experimental ones from MDN: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy
                context.Response.Headers.Append("Permissions-Policy", "camera=(), display-capture=(), fullscreen=(), geolocation=(), microphone=(), publickey-credentials-get=(), screen-wake-lock=(), web-share=()");

                await next(context);
            });
            app.UseSecureHeadersMiddleware(BuildSecurityHeadersConfig(app.Environment));

            app.UseHttpsRedirection();

            app.UseStaticFiles();

            app.UseRouting();

            app.UseAuthentication();
            app.UseAuthorization();

            app.MapRazorPages();
            app.MapControllers();

            app.Run();
        }
        catch (Exception e)
        {
            telemetryClient?.TrackException(e);
            telemetryClient?.Flush();
            throw;
        }
    }

    private static SecureHeadersMiddlewareConfiguration BuildSecurityHeadersConfig(
        IWebHostEnvironment env)
    {
        var builder = SecureHeadersMiddlewareBuilder.CreateBuilder();

        if (!env.IsDevelopment())
        {
            // We don't want HSTS for localhost
            // I've also chosen not to include subdomains (though you should definitely consider doing it)
            builder.UseHsts(includeSubDomains: false);
        }

        builder
            .UseXFrameOptions()
            .UseContentTypeOptions()
            .UseContentDefaultSecurityPolicy()
            .UsePermittedCrossDomainPolicies()
            .UseReferrerPolicy()
            .UseCacheControl(noCache: true, noStore: true)
            .RemovePoweredByHeader()
            .UseXssProtection()
            .UseCrossOriginResourcePolicy();

        return builder.Build();
    }
}
