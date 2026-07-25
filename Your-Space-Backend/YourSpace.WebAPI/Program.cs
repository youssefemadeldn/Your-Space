using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using Serilog;
using StackExchange.Redis;
using YourSpace.Data.Contexts;
using YourSpace.WebAPI.Extensions;
using YourSpace.WebAPI.Helpers;
using YourSpace.WebAPI.Middleware;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, config) => config.ReadFrom.Configuration(context.Configuration));

builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));

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

using (var seedScope = app.Services.CreateScope())
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
