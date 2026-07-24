using System.Text.Json;
using YourSpace.Services.Helper;

namespace YourSpace.WebAPI.Middleware;

public class ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger, IHostEnvironment env)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (NotFoundException ex)
        {
            logger.LogWarning(ex, "Resource not found: {Message}", ex.Message);
            await WriteResponseAsync(context, ServiceResult.NotFound(ex.Message));
        }
        catch (ValidationException ex)
        {
            logger.LogWarning("Validation failed: {Message}", ex.Message);
            await WriteResponseAsync(context, ServiceResult.ValidationError(ex.Errors, ex.Message));
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled exception occurred");
            var message = env.IsDevelopment() ? ex.ToString() : "An unexpected error occurred";
            await WriteResponseAsync(context, ServiceResult.ServerError(message));
        }
    }

    private static async Task WriteResponseAsync(HttpContext context, ServiceResult result)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = result.StatusCode;
        await context.Response.WriteAsync(JsonSerializer.Serialize(result, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        }));
    }
}
