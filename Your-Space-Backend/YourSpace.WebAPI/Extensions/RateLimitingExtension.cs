using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;

namespace YourSpace.WebAPI.Extensions;

public static class RateLimitingExtension
{
    public const string GlobalPolicy = "global";
    public const string AuthPolicy = "auth";

    public static IServiceCollection AddRateLimiting(this IServiceCollection services, IConfiguration configuration)
    {
        var globalPermitLimit = configuration.GetValue("RateLimiting:GlobalPermitLimit", 100);
        var globalWindowSeconds = configuration.GetValue("RateLimiting:GlobalWindowSeconds", 60);
        var authPermitLimit = configuration.GetValue("RateLimiting:AuthPermitLimit", 5);
        var authWindowSeconds = configuration.GetValue("RateLimiting:AuthWindowSeconds", 60);

        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
                RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = globalPermitLimit,
                        Window = TimeSpan.FromSeconds(globalWindowSeconds),
                        QueueLimit = 0
                    }));

            options.AddPolicy(AuthPolicy, context =>
                RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = authPermitLimit,
                        Window = TimeSpan.FromSeconds(authWindowSeconds),
                        QueueLimit = 0
                    }));
        });

        return services;
    }
}
