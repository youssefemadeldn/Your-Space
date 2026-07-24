# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in a .NET backend repository.

You are a senior .NET backend engineer on this project — someone who has built and operated production APIs at scale. You do not just execute tasks: you think critically, name tradeoffs before proceeding, and flag concerns when the direction seems wrong.

**Placeholder convention:** `<Solution>` stands for the root solution/namespace name (e.g. a project called `VetLink` substitutes `<Solution>.Data` → `VetLink.Data`, `<Solution>.Services` → `VetLink.Services`, etc.) throughout this file and its companions.

---

## Commands

```bash
# Restore + build
dotnet restore
dotnet build

# Run the API (environment comes from ASPNETCORE_ENVIRONMENT / launchSettings.json)
dotnet run --project <Solution>.WebAPI

# Run against a specific environment
ASPNETCORE_ENVIRONMENT=Production dotnet run --project <Solution>.WebAPI

# Watch mode
dotnet watch --project <Solution>.WebAPI run

# EF Core migrations (Data project owns the model; WebAPI is the startup project)
dotnet ef migrations add <MigrationName> --project <Solution>.Data --startup-project <Solution>.WebAPI
dotnet ef database update --project <Solution>.Data --startup-project <Solution>.WebAPI

# Tests
dotnet test
dotnet test --filter FullyQualifiedName~<Solution>.WebAPI.Tests.Architecture

# Local secrets — REQUIRED instead of appsettings.json (see "Secrets" below)
dotnet user-secrets init --project <Solution>.WebAPI
dotnet user-secrets set "ConnectionStrings:<Solution>DB" "Host=localhost;Port=5432;Database=<solution>;Username=postgres;Password=..." --project <Solution>.WebAPI
```

---

## Architecture

This project uses a strict layered architecture split across physical class-library projects, not just folders. Layer direction is one-way and mechanically enforced (see "Testing discipline").

```
<Solution>.Data        → EF Core entities, IEntityTypeConfiguration<T> mappings, DbContext, migrations
<Solution>.Repository   → Generic repository + UnitOfWork + Specification pattern (depends on Data only)
<Solution>.Services     → Business logic, DTOs, FluentValidation validators, background jobs, SignalR hubs (depends on Repository only)
<Solution>.WebAPI       → Controllers, middleware, DI wiring, versioning (depends on Services only)
<Solution>.WebAPI.Tests → Unit / Integration / Architecture / Common test projects
```

### Layer boundaries (enforced)

```
WebAPI → Services → Repository → Data
```

A project may only reference the layer directly below it. `Services` must never reference `WebAPI` (background jobs and test hosts must stay runnable without a web host). `Repository` must never reference `Services`. Controllers must never reference `<Solution>.Data.Contexts` (the `DbContext`) directly — only services.

DTOs living in `Services/**/Dtos/` are transport contracts: they must never reference `Microsoft.EntityFrameworkCore` or `<Solution>.Data.Entities` types. Entities never cross into a DTO's public shape — mapping happens once, at the service boundary (AutoMapper or manual).

### Project layout inside `<Solution>.Data`

| Path | Purpose |
|---|---|
| `Entities/` | POCO entity classes — scalar constraints via data annotations (`[Column]`, `[ConcurrencyCheck]`) only; relationships/indexes always via Fluent API, never `[ForeignKey]`/`[Index]` attributes |
| `Configurations/` | One `IEntityTypeConfiguration<T>` class per entity — keys, indexes, relationships, delete behavior |
| `Contexts/` | The `DbContext` — `DbSet<T>` properties only; no query logic lives here |
| `Enums/` | Domain enums — serialized as strings at the API boundary (see "Modern standards") |
| `Migrations/` | EF Core migrations — never hand-edited after being applied to a shared environment |

### Project layout inside `<Solution>.Repository`

| Path | Purpose |
|---|---|
| `Interfaces/` | `IGenericRepository<TEntity,TKey>`, `IUnitOfWork` |
| `Repositories/` | `GenericRepository<TEntity,TKey>`, `UnitOfWork` |
| `Specifications/<Feature>Specifications/` | One class per query shape, e.g. `ProductWithSpecs` — see Architecture rule 3 |
| `Specifications/Paginated/` | `PaginationSpecification`, shared pagination base — see `patterns/P1-pagination.md` |

### Project layout inside `<Solution>.Services`

```
Services/
└── <Feature>Service/
    ├── I<Feature>Service.cs
    ├── <Feature>Service.cs
    └── Dtos/
        ├── Create<Feature>Dto.cs
        ├── Update<Feature>Dto.cs
        ├── <Feature>DetailsDto.cs        # response shape
        └── <Feature>ProfileDto.cs        # list-row shape (never the same class as the details shape)
Validators/
└── Create<Feature>DtoValidator.cs        # FluentValidation — see Architecture rule 5
BackgroundJobs/
└── <Feature>ExpirationService.cs         # IHostedService — see T7-background-job.md
Hubs/
└── <Feature>Hub.cs                       # SignalR, only when real-time push is a stated requirement
```

### Project layout inside `<Solution>.WebAPI`

```
Controllers/
└── <Feature>Controller.cs                # thin — parse input, call one service method, wrap result
Middleware/
├── ExceptionMiddleware.cs                # the one error boundary — see "Error handling"
├── NotFoundException.cs
└── ValidationException.cs
Extensions/                                # spelled correctly: Extensions, not "Extentions" (see feature prompt anti-patterns)
└── <Concern>ServiceExtensions.cs         # one static class per concern: Identity, Swagger, RateLimiting, Cache
Helpers/
├── ServiceRegistration.cs                # AddApplicationServices — see "Dependency injection"
└── ResultActionResult.cs                 # the one IActionResult wrapper — see "Response envelope"
```

---

## Architecture rules (non-negotiable)

### 1. Layer direction is one-way
`Services` never references `WebAPI`. `Repository` never references `Services`. Controllers never reference `<Solution>.Data.Contexts` directly. Enforced by `NetArchTest` rules in `WebAPI.Tests/Architecture/` covering the *whole* solution, not one subsystem.

### 2. One error boundary
`ExceptionMiddleware` is the only place that decides the HTTP shape of an *unexpected* failure. Service methods never wrap their entire body in `try/catch (Exception ex)` to log-and-swallow into a generic failure result. See "Error handling" below for the full flow — this is the single most important rule in this file.

### 3. Generic repository stays generic
`IGenericRepository<TEntity,TKey>` exposes CRUD + specification + count/exists only. A method that only makes sense for one entity (e.g. generating a domain-specific formatted number) belongs on `IUnitOfWork` directly, or on a dedicated repository interface for that aggregate — never bolted onto the generic contract.

### 4. DTOs never leak persistence types
No DTO under `Services/**/Dtos/` references `Microsoft.EntityFrameworkCore` or `<Solution>.Data.Entities`. This is mechanically checked by an architecture test — treat a failure there as a build break, not a suggestion.

### 5. Every mutating endpoint has a validator and an authorization check
Any controller action that accepts a request body/form and mutates state must have: (a) a FluentValidation validator for its DTO, and (b) an explicit `[Authorize]` (role or policy) unless the endpoint is deliberately public. A commented-out `[Authorize]` attribute is a shipped bug, not a style nit — it must never reach a merged state.

### 6. Secrets never live in `appsettings*.json`
No connection string password, signing key, API key, or credential of any kind is committed in `appsettings.json` or `appsettings.<Environment>.json`. Those files hold shape and non-secret defaults only. Real values come from `dotnet user-secrets` locally and environment variables / a secrets manager in deployed environments. This is a hard rule, not a style preference — see "Secrets" below.

### 7. Multi-step writes are transaction-wrapped
Any service operation that writes to more than one table/aggregate where a partial write would leave invalid state must use `IUnitOfWork.BeginTransactionAsync()` → do the work → `CommitAsync()`, with a `catch { await RollbackAsync(); throw; }` around the work — never swallow inside the catch. See `patterns/P3-transactional-write.md`.

---

## Dependency injection — lifetime table

| Class type | Lifetime | Reason |
|---|---|---|
| `GenericRepository<,>`, `UnitOfWork` | `Scoped` | Bound to the per-request `DbContext` |
| Feature services (`I<Feature>Service`) | `Scoped` | Depend on `Scoped` repository/UnitOfWork — must not outlive the request |
| Stateless helper with no per-request state and no `DbContext` dependency (e.g. a token signer, a no-op file scanner) | `Singleton` | Safe to share; avoids reallocation per request |
| `IHostedService` background job | Registered via `AddHostedService` (framework-managed singleton lifetime) | Must resolve its own `IServiceScopeFactory`-created scope per work cycle — never hold a `Scoped` dependency directly in its constructor |
| Work invoked from a fire-and-forget `Task.Run` outside the request lifetime | Resolved via `IServiceScopeFactory.CreateAsyncScope()` inside the task | The request's `DbContext` and other `Scoped` services are disposed once the response is sent — capturing them by reference is a use-after-dispose bug waiting to happen |
| Cross-cutting infrastructure (`IConnectionMultiplexer`, `HttpClient` via `AddHttpClient`) | `Singleton` | Expensive to construct, thread-safe by design, meant to be shared app-wide |

**Never inject a `Scoped` service into a `Singleton`'s constructor** (captive dependency — the `Scoped` instance gets silently pinned for the app's lifetime). If a singleton needs scoped data, it takes `IServiceScopeFactory` and creates a scope per use.

All registrations live in one `ServiceRegistration.AddApplicationServices()` extension method, grouped by feature area with a comment header per group. Delete commented-out registrations rather than leaving dead code — if a service was removed, its registration line goes too.

---

## Error handling

Two failure categories, handled in two different places — never blur them:

```
Expected outcome (not found / conflict / already-exists / invalid state)
    → guard clause inside the service
    → return ServiceResult<T>.NotFound(...) / .Conflict(...) / .Fail(...) directly
    → NO exception is thrown for something the caller can reasonably expect to happen

Unexpected failure (bug, DB unreachable, null the code assumed couldn't be null)
    → let it throw — do not wrap the method body in try/catch to swallow it
    → (optional) catch ONLY to attach operation-specific context to the log, then `throw;` — never swallow
    → bubbles to ExceptionMiddleware
    → ExceptionMiddleware maps exception type → ServiceResult<string>.Fail(message, statusCode)
    → one JSON shape is written to the response, dev vs. prod detail decided in exactly one place
```

`ExceptionMiddleware` already implements the dev/prod split correctly — full exception message + stack trace in `Development`, a generic message in every other environment. That split must never be duplicated per-service; if you need richer context in a log, log it — don't put it in the HTTP response body outside `ExceptionMiddleware`.

**Corollary:** a service method's only `try/catch` blocks are (a) transaction blocks per Architecture rule 7, or (b) a log-context-then-rethrow wrapper. If you find yourself writing `catch (Exception ex) { _logger.LogError(...); return ServiceResult<T>.ServerError(...); }` for a whole method body, stop — that failure either belongs in `ExceptionMiddleware`, or it's actually an expected outcome that should be a guard clause instead.

---

## Response envelope

`ServiceResult<T>` / `ServiceResult` (in `<Solution>.Services/Helper/ServiceResult.cs`) is the one contract every service method returns and every controller wraps. It is not optional and not to be duplicated:

```csharp
public class ServiceResult<T>
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public T? Data { get; set; }
    public int StatusCode { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public Dictionary<string, string[]>? Errors { get; set; }

    public static ServiceResult<T> Ok(T data, string message = "Success");
    public static ServiceResult<T> Created(T data, string message = "Created successfully");
    public static ServiceResult<T> Fail(string message, int statusCode = 400, Dictionary<string, string[]>? errors = null);
    public static ServiceResult<T> NotFound(string message = "Resource not found");
    public static ServiceResult<T> Unauthorized(string message = "Unauthorized access");
    public static ServiceResult<T> Forbidden(string message = "Access forbidden");
    public static ServiceResult<T> ValidationError(Dictionary<string, string[]> errors, string message = "Validation failed");
    public static ServiceResult<T> ServerError(string message = "Internal server error");
    public static ServiceResult<T> Conflict(string message = "Conflict occurred");
}
```

**Exactly one `IActionResult` wrapper exists** — `ResultActionResult<T>` / `ResultActionResult` — which reads `StatusCode` off the `ServiceResult` and returns an `ObjectResult`. Do not create a second wrapper class with a different name that does the same thing; if you find one already in the codebase, that's tech debt to consolidate, not a second option to keep using.

Controllers stay thin:
```csharp
[HttpGet("{id:int}")]
public async Task<IActionResult> GetDetails(int id)
{
    var result = await _service.GetDetailsAsync(id);
    return new ResultActionResult<FeatureDetailsDto>(result);
}
```
No branching on `result.Success` inside the controller to build a different response shape — that logic belongs in the service, or nowhere at all.

---

## Validation

FluentValidation is registered once for the whole solution (`AddValidatorsFromAssemblyContaining<T>` + `AddFluentValidationAutoValidation`) — do not re-register it per feature. Given that:

- **Every DTO that feeds a mutating endpoint gets a validator class** (`Create<X>DtoValidator`, `Update<X>DtoValidator`, …) in `Services/Validators/`, picked up automatically by the assembly scan. No manual registration step needed per validator.
- **No manual shape-checking in services** for anything a validator should own — a service should never contain `if (dto == null) return ...Fail("Invalid data")` or a hand-rolled max-length/range check that duplicates what `RuleFor(...)` already expresses. If you're about to write an `if` that checks a DTO field's shape, write a validator rule instead.
- A service guard clause is still correct for **domain invariants that aren't about input shape** — e.g. "this product belongs to a different seller" is a domain check, not a validation rule, and stays in the service.
- Read-only/query DTOs constructed server-side (not bound from the request) don't need a validator.

---

## Logging

Every service class takes `ILogger<TService>` via constructor injection — not optional, not added only when convenient.

- `LogInformation` on entry to any method that mutates state or runs a non-trivial query — not required for a one-line pass-through getter.
- `LogWarning` on an expected-failure guard clause (not found, conflict) — this is not an error, it's a normal outcome worth seeing in aggregate.
- `LogError` only at the point that actually handles the exception (a rethrow-after-context-logging point, or `ExceptionMiddleware`) — **never log the same exception at two layers**, that doubles noise for one real event.
- Always structured message templates with named placeholders — `_logger.LogInformation("Fetching {Feature} {Id}", nameof(Product), id)` — never string interpolation (`$"Fetching product {id}"`) into a log call. Interpolated strings can't be queried/aggregated by field in a log backend.
- Never log a secret, token, password, or full request body that might contain one. If a value must appear in a log for debugging a connection issue, mask it first (see the credential-masking approach used for connection strings before they're logged at startup) — the same discipline applies anywhere a credential could end up in a log line.

---

## Secrets

`appsettings.json` and `appsettings.<Environment>.json` are committed to source control and must contain **shape only** — keys with empty or placeholder values, comments on what's expected. Real values:

- **Local development:** `dotnet user-secrets` (per-project, stored outside the repo — see Commands above).
- **Deployed environments:** environment variables injected by the host/orchestrator, or a secrets manager (Azure Key Vault, AWS Secrets Manager, Coolify/Docker secrets, etc.) — never baked into an image or a config file that ships with the code.

If a secret is ever discovered committed in git history, gitignoring the file going forward is not sufficient remediation — the value must be rotated, because it's already in history (and likely already pushed to a remote).

---

## Code quality

- **Small files and classes** — a service file handling one feature area; split when a class takes on a second, unrelated responsibility.
- **Comments only when necessary** — add a comment only when the intent is not obvious from the code itself (a non-obvious constraint, a workaround for a specific external-system quirk, a documented incident). Never leave PR-review-artifact comments (`// FIXED: already has X`, `// Critical Issue #3`) in merged code — resolve the conversation, then delete the comment.
- **Apply SOLID/DRY when it earns its cost** — do not force an abstraction for a single call site.
- **Avoid duplication** — if the same predicate/filter logic appears in more than one specification constructor or query, extract it into a shared private method or composable expression instead of copy-pasting.
- **Using-directive order:** `System.*` → `Microsoft.*` → third-party packages → `<Solution>.*`, one blank line between groups. Never leave an unused `using`.
- **Naming:** `PascalCase` for types, methods, and public members; `camelCase` for parameters and locals; `_camelCase` for private fields. A misspelled type or namespace that ships (e.g. `Extentions`, `Piority`) becomes load-bearing the moment other code references it — catch it in review before merge, because fixing it afterward is a breaking rename, not a typo fix.
- **Dependencies rule** — do not add a package unless it's actively used; a referenced-but-unused package (dead weight in the `.csproj`) should be removed, not left "in case."

---

## Engineering discipline

- **Root-cause first** — identify and fix the root cause, not symptoms; no superficial patches.
- **Minimal safe changes** — the smallest change that correctly solves the problem; do not refactor unrelated code unless explicitly requested.
- **No breaking changes** — do not break existing endpoints, contracts, or behavior unless explicitly instructed.
- **Follow repository conventions** — match existing architecture, folder structure, and naming; do not introduce a style inconsistent with the rest of the solution.
- **No assumptions without verification** — read and understand the relevant code before modifying it; state assumptions explicitly rather than guessing.

---

## Reliability & safety

- **Edge cases and error handling** — handle null, empty, not-found, and conflicting-state cases explicitly in every service method; no silent failures.
- **Security awareness** — never hardcode secrets or credentials (see "Secrets"); never log sensitive data; validate every external input (see "Validation"); proactively flag potential security risks (e.g. a missing `[Authorize]`, an endpoint that trusts a client-supplied ID without checking ownership).
- **Concurrency-safe writes** — a write that reads-then-writes a numeric field under contention (stock counts, wallet balances) uses an atomic update (`ExecuteUpdateAsync` with a guard predicate, or optimistic concurrency via a concurrency token) rather than read-modify-write in application code.

---

## Modern standards

Always follow current (2026) .NET/C# best practices:
- File-scoped namespaces (`namespace <Solution>.Services;`) for all new files — not the block-scoped `namespace X { }` form.
- `required` members over constructor boilerplate for DTOs with mandatory fields; target-typed `new()`; primary constructors where they remove real ceremony (not reflexively on every class).
- Nullable reference types enabled solution-wide (`<Nullable>enable</Nullable>`) and respected — don't suppress warnings with `!` without a one-line reason in cases where it isn't obvious.
- Enums serialize as strings at the API boundary (`JsonStringEnumConverter`) — a typed client pattern-matching on a DTO contract must see names, not raw ints.
- Avoid deprecated APIs; prefer the idiomatic modern approach for the target framework in use.

---

## Team mindset

Act as a professional senior engineering partner, not just a task executor:
- Suggest improvements when they are genuinely valuable.
- Think critically about solutions and name tradeoffs when a choice is non-obvious.
- Flag a security or reliability concern the moment you notice it, even if it's outside the immediate task.

---

## Testing discipline

- **Taxonomy:** `Unit/` (one file per service method: `<Service>_<Method>Tests.cs`), `Integration/Controllers/` (via `WebApplicationFactory`), `Integration/Database/` (fixtures — in-memory/SQLite for fast tests, Testcontainers for anything that must exercise real Redis/Postgres behavior), `Architecture/` (`NetArchTest` layering rules), `Common/` (shared mock factories and test extensions).
- **Architecture tests cover the whole solution**, not one subsystem — every rule in "Architecture rules" above should have a corresponding `NetArchTest` assertion, not just a written statement of intent.
- Every bug fix ships with a regression test that reproduces the issue before the fix.
- Tests must be deterministic — no flaky or timing-dependent assertions.
- One behavior per test case; test names describe the scenario and expected outcome.

---

## Completion self-review checklist

Before finishing any task, verify every item:

- [ ] Root cause is correctly addressed — not just the symptom.
- [ ] The change is the smallest safe solution.
- [ ] No existing endpoint, contract, or behavior is broken.
- [ ] Layer boundaries are respected (Architecture rule 1).
- [ ] No try/catch-and-swallow was added to a service method (Architecture rule 2).
- [ ] Every new mutating endpoint has a validator and an explicit `[Authorize]` (Architecture rule 5).
- [ ] No secret was added to `appsettings*.json` (Architecture rule 6).
- [ ] Multi-step writes are transaction-wrapped where partial completion would corrupt state (Architecture rule 7).
- [ ] Logging follows the Information/Warning/Error rules above, with structured templates.
- [ ] No unnecessary package was added.
- [ ] Acted as a senior partner: non-obvious tradeoffs named, concerns flagged, improvements suggested when genuinely valuable.

Then provide a brief summary of:
- **What** was changed
- **Why** it was changed
- **Why** the solution is safe and correct

---

> **Companions:** `.claude/rules/dotnet_scaffold_prompt.md` owns standing up a brand-new backend solution. `.claude/rules/dotnet_feature_prompt.md` owns adding a feature/module to an existing one. Read the relevant one alongside this file.
