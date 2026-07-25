using System.Linq;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using YourSpace.Data.Contexts;
using YourSpace.Services.Services.EmailService;
using YourSpace.WebAPI.Tests.Common.Fakes;

namespace YourSpace.WebAPI.Tests.Common;

// SQLite in-memory keeps the connection (and the schema) alive for the factory's lifetime —
// closing it would drop the database, so the connection is only disposed with the factory.
public class TestWebApplicationFactory : WebApplicationFactory<Program>
{
    private readonly SqliteConnection _connection = new("DataSource=:memory:");
    public FakeEmailSender EmailSender { get; } = new();

    public TestWebApplicationFactory()
    {
        // Program.cs reads these via ConnectionStringResolver/AddIdentityService synchronously,
        // line-by-line, while WebApplicationBuilder is still being assembled — well before any
        // ConfigureAppConfiguration/ConfigureServices override from this factory is applied. Environment
        // variables are the one configuration source guaranteed to already be in place by then, since
        // WebApplication.CreateBuilder() wires up the environment-variable provider immediately.
        Environment.SetEnvironmentVariable("ConnectionStrings__YourSpaceDB", "Host=localhost;Database=unused;Username=unused;Password=unused");
        Environment.SetEnvironmentVariable("Jwt__Key", "integration-test-signing-key-at-least-32-characters-long");
        Environment.SetEnvironmentVariable("Jwt__Issuer", "YourSpaceTests");
        Environment.SetEnvironmentVariable("Jwt__Audience", "YourSpaceTestsClients");
        // A multi-step test flow (register → login → refresh → replay → refresh again) legitimately
        // makes more than the production AuthPermitLimit's worth of calls to auth-policy endpoints —
        // rate limiting itself isn't what these tests verify, so it's loosened rather than the test
        // flow being artificially shortened to dodge it.
        Environment.SetEnvironmentVariable("RateLimiting__AuthPermitLimit", "1000");
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("IntegrationTest");

        builder.ConfigureServices(services =>
        {
            _connection.Open();

            // Program.cs's own startup (Database.Migrate() / IdentitySeeder.SeedAsync) runs as soon as
            // the host is built, before test code gets a chance to run — so the schema has to exist
            // *before* builder.Build() executes. EnsureCreated() here, straight off the connection
            // rather than through DI, guarantees that ordering.
            using (var schemaContext = new YourSpaceDbContext(
                       new DbContextOptionsBuilder<YourSpaceDbContext>().UseSqlite(_connection).Options))
            {
                schemaContext.Database.EnsureCreated();
            }

            // Modern EF Core registers the Npgsql configuration via a TryAddEnumerable
            // IDbContextOptionsConfiguration<TContext> entry, not just DbContextOptions<TContext> —
            // removing only the latter leaves Npgsql's configuration delegate in place, so both
            // providers end up applied to the same options and EF Core refuses to pick one.
            services.RemoveAll<DbContextOptions<YourSpaceDbContext>>();
            services.RemoveAll(typeof(IDbContextOptionsConfiguration<YourSpaceDbContext>));

            services.AddDbContext<YourSpaceDbContext>(options => options.UseSqlite(_connection));

            var emailSender = services.SingleOrDefault(d => d.ServiceType == typeof(IEmailSender));
            if (emailSender is not null)
            {
                services.Remove(emailSender);
            }

            services.AddSingleton<IEmailSender>(EmailSender);
        });
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing)
        {
            _connection.Dispose();
        }
    }
}
