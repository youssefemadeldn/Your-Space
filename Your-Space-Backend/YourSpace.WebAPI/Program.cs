using System.Text.Json.Serialization;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Serilog;
using StackExchange.Redis;
using YourSpace.Data.Contexts;
using YourSpace.Services.Helper;
using YourSpace.WebAPI.Extensions;
using YourSpace.WebAPI.Helpers;
using YourSpace.WebAPI.Middleware;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, config) => config.ReadFrom.Configuration(context.Configuration));

builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()))
    .ConfigureApiBehaviorOptions(options =>
    {
        // [ApiController]'s automatic model-state validation (which FluentValidation's
        // AddFluentValidationAutoValidation() populates) short-circuits the pipeline and returns its
        // own ProblemDetails shape by default — before ExceptionMiddleware/ServiceResult ever see the
        // request. Overriding the factory is the only way to keep every validation failure on the one
        // documented ServiceResult envelope instead of a second, undocumented response shape.
        options.InvalidModelStateResponseFactory = context =>
        {
            var errors = context.ModelState
                .Where(entry => entry.Value?.Errors.Count > 0)
                .ToDictionary(
                    entry => entry.Key,
                    entry => entry.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

            return new ResultActionResult(ServiceResult.ValidationError(errors));
        };
    });

builder.Services.AddDataProtection();

builder.Services.AddCors(options => options.AddPolicy("DefaultCors", policy =>
    policy.WithOrigins(builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? [])
          .AllowAnyHeader()
          .AllowAnyMethod()));

using var bootstrapLoggerFactory = LoggerFactory.Create(b => b.AddConsole());
var connectionString = ConnectionStringResolver.Resolve(
    builder.Configuration,
    bootstrapLoggerFactory.CreateLogger("Startup"));

builder.Services.AddDbContext<YourSpaceDbContext>(options => options.UseNpgsql(connectionString));
// EnableRetryOnFailure intentionally NOT enabled — if it ever is, every BeginTransactionAsync
// call site in UnitOfWork must be wrapped in Npgsql's IExecutionStrategy.ExecuteAsync.

builder.Services.AddSingleton<IConnectionMultiplexer>(_ =>
    ConnectionMultiplexer.Connect(builder.Configuration["Redis:ConnectionString"] ?? "localhost:6379"));
builder.Services.AddStackExchangeRedisCache(o =>
    o.Configuration = builder.Configuration["Redis:ConnectionString"] ?? "localhost:6379");

builder.Services.AddApplicationServices();
builder.Services.AddIdentityService(builder.Configuration);
builder.Services.AddEmailService(builder.Configuration);
builder.Services.AddRateLimiting(builder.Configuration);
builder.Services.AddSwaggerDocumentation();

if (builder.Environment.IsDevelopment())
{
    builder.Services.AddHttpLogging(o => { });
}

var app = builder.Build();

// Must run before anything that reads Request.Scheme or Connection.RemoteIpAddress (rate limiting's
// IP partitioning, RefreshToken.CreatedByIp/RevokedByIp, UseHttpsRedirection) — otherwise those all
// see the reverse proxy's address instead of the real client's. KnownNetworks/KnownProxies are
// cleared because a container's reverse proxy is rarely at a fixed, known IP; that also means this
// trusts X-Forwarded-For from whatever sits in front of the app, so it's only safe as long as that
// front door actually overwrites the header rather than passing an untrusted client value through —
// tighten to the real proxy's IP/network once a hosting target is chosen.
var forwardedHeadersOptions = new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
};
forwardedHeadersOptions.KnownIPNetworks.Clear();
forwardedHeadersOptions.KnownProxies.Clear();
app.UseForwardedHeaders(forwardedHeadersOptions);

if (app.Environment.IsDevelopment())
{
    using (var scope = app.Services.CreateScope())
    {
        scope.ServiceProvider.GetRequiredService<YourSpaceDbContext>().Database.Migrate();
    }

    app.UseOpenApi();
    app.UseSwaggerUi();
    app.UseHttpLogging();
}
else
{
    app.UseHsts();
}

// IdentitySeeder resolves IUnitOfWork, which is IAsyncDisposable-only (see UnitOfWork.DisposeAsync) —
// a synchronous `using` scope throws on dispose trying to dispose it synchronously.
await using (var seedScope = app.Services.CreateAsyncScope())
{
    await IdentitySeeder.SeedAsync(seedScope.ServiceProvider, app.Configuration, app.Logger);
}

app.UseHttpsRedirection();

app.UseCors("DefaultCors");

app.UseExceptionHandler("/error");
app.UseMiddleware<ExceptionMiddleware>();

app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.Map("/error", (HttpContext _) => Results.Problem());

app.Run();

// Exposes the implicit top-level Program class to WebApplicationFactory<Program> in tests.
public partial class Program;
