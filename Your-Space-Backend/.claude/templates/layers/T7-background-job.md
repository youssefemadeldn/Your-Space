---
name: T7-background-job
governed-by: CLAUDE.md "Dependency injection" (IHostedService row) · dotnet_feature_prompt.md §5 (hosted service vs. fire-and-forget)
---

# T7 — Background Job (`IHostedService`)

Use this for anything recurring, scheduled, or business-critical enough that silent loss would matter. For a genuinely best-effort, non-critical side effect, see the fire-and-forget snippet in the Notes instead — don't reach for a hosted service by default when that's all that's needed.

---

## `<Solution>.Services/BackgroundJobs/<Feature>ExpirationService.cs`

```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using <Solution>.Repository.Interfaces;

namespace <Solution>.Services.BackgroundJobs;

public class <Feature>ExpirationService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<<Feature>ExpirationService> _logger;
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);

    public <Feature>ExpirationService(IServiceScopeFactory scopeFactory, ILogger<<Feature>ExpirationService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);

        while (!stoppingToken.IsCancellationRequested && await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();

                // ... find and process expired/eligible rows via unitOfWork ...

                _logger.LogInformation("{Job} cycle completed", nameof(<Feature>ExpirationService));
            }
            catch (Exception ex)
            {
                // A hosted service's ExecuteAsync must never let an exception escape a cycle —
                // that would crash the whole host, not just this job. Log and continue to the next tick.
                _logger.LogError(ex, "{Job} cycle failed", nameof(<Feature>ExpirationService));
            }
        }
    }
}
```

## Registration — `Program.cs`

```csharp
builder.Services.AddHostedService<<Solution>.Services.BackgroundJobs.<Feature>ExpirationService>();
```

---

## Notes

- **`IServiceScopeFactory`, never a directly-injected `Scoped` dependency** — `BackgroundService` instances are constructed once for the app's lifetime; a `Scoped` repository/`DbContext` injected straight into the constructor would be captured once and reused forever, which is exactly the captive-dependency bug CLAUDE.md's DI table warns about. Create a fresh scope every cycle instead.
- **The per-cycle `try/catch` is the one legitimate exception to CLAUDE.md's "no whole-method try/catch"** — this loop has no HTTP request/`ExceptionMiddleware` to fall back on; an uncaught exception here kills the entire background host, not just one operation. Catch, log, and let the loop continue to its next tick.
- **Interval choice:** favor `PeriodicTimer` over `Task.Delay` in a loop — it doesn't drift when a cycle takes longer than the interval, and it responds to cancellation immediately rather than after the current delay finishes.

### Fire-and-forget alternative (for genuinely best-effort side effects only)

Only when losing the work silently is truly acceptable and gets logged — see `dotnet_feature_prompt.md` §5's decision table before reaching for this instead of the hosted service above.

```csharp
_ = Task.Run(async () =>
{
    try
    {
        await using var scope = _scopeFactory.CreateAsyncScope();
        var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();
        await emailService.SendEmailAsync(to, subject, body);
    }
    catch (Exception ex)
    {
        _logger.LogWarning(ex, "Best-effort notification failed for {Context}", context);
    }
});
```

The fresh scope matters here too, for the same reason: the request's own scope (and its `DbContext`) may already be disposed by the time this task actually runs.
