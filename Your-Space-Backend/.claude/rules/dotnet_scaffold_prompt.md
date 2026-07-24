> Scaffold the complete foundational layer for a new empty .NET backend solution
  before any feature code is written — covering the project split, data access,
  error handling, DI, validation, logging, auth, and configuration.

**Current state:** the solution is a clean `dotnet new` — no feature code exists yet.
The goal is a professional, scalable foundation that makes every future feature
consistent, easy to maintain, and hard to break. Do not generate any feature
entities, services, or controllers — only the infrastructure layer.

`<Solution>` stands for the root name throughout (e.g. `VetLink` → `VetLink.Data`, `VetLink.Services`, …).

---

**Package context (ignore versions — use latest stable compatible with the target framework):**
- ORM & database: `Microsoft.EntityFrameworkCore`, `Npgsql.EntityFrameworkCore.PostgreSQL`, `Microsoft.EntityFrameworkCore.Tools`
- Auth: `Microsoft.AspNetCore.Identity.EntityFrameworkCore`, `Microsoft.AspNetCore.Authentication.JwtBearer`, `System.IdentityModel.Tokens.Jwt`
- Validation: `FluentValidation.AspNetCore`
- Mapping: `AutoMapper.Extensions.Microsoft.DependencyInjection`
- Logging: `Serilog.AspNetCore`
- API surface: `Microsoft.AspNetCore.Mvc.Versioning`, `Microsoft.AspNetCore.Mvc.Versioning.ApiExplorer`, `Microsoft.AspNetCore.OpenApi`, `NSwag.AspNetCore`
- Caching/resilience: `Microsoft.Extensions.Caching.StackExchangeRedis`, `Polly`
- Testing: `xunit`, `Moq`, `FluentAssertions`, `Bogus`, `Microsoft.AspNetCore.Mvc.Testing`, `Microsoft.EntityFrameworkCore.Sqlite`, `Testcontainers` (+ the module for any real external dependency, e.g. `Testcontainers.Redis`), `NetArchTest.Rules`
- Only add anything beyond this list when a concrete, active feature needs it (see CLAUDE.md "Dependencies rule") — never speculatively.

---

**Target framework & nullability:**
- Latest stable LTS/STS .NET release available; `ImplicitUsings` and `Nullable` both `enable` on every project.

---

**Solution & Project Structure:**

```
<Solution>.slnx (or .sln)
├── <Solution>.Data/            # Microsoft.NET.Sdk
├── <Solution>.Repository/       # Microsoft.NET.Sdk — references Data
├── <Solution>.Services/         # Microsoft.NET.Sdk — references Repository
├── <Solution>.WebAPI/           # Microsoft.NET.Sdk.Web — references Services
└── <Solution>.WebAPI.Tests/     # Microsoft.NET.Sdk — references all four
```

Project reference direction must match CLAUDE.md's "Architecture rules #1" exactly — `Repository` references only `Data`; `Services` references only `Repository`; `WebAPI` references only `Services`. No project references "up" the chain. `WebAPI.Tests` is the only project allowed to reference all four (it needs `Data` directly for `Testcontainers`/in-memory fixtures, and `WebAPI` for `WebApplicationFactory` integration tests).

---

**Environment & connection string strategy:**

- `appsettings.json` and `appsettings.<Environment>.json` contain **shape only** — see CLAUDE.md "Secrets." Real connection strings, JWT keys, and third-party API keys come from `dotnet user-secrets` locally and environment variables in deployed environments.
- Resolve the connection string with a fallback chain: configured `ConnectionStrings:<Solution>DB` first, then a `DATABASE_URL`-style environment variable (common on PaaS hosts like Railway/Coolify/Render) parsed from URI form (`postgres://user:pass@host:port/db`) into the provider's keyword=value format if the configured value is absent. Mask the password before writing the resolved string to any startup log line.
- Two environments minimum: `Development` (local, verbose HTTP logging, Swagger UI enabled) and `Production` (HSTS, no Swagger UI, generic error messages via `ExceptionMiddleware`'s `IHostEnvironment` check).

---

**Phase 1 — Exploration (no code yet)**

1. Confirm the installed .NET SDK version and that the working directory is a clean `dotnet new` (only the default template files exist) before proceeding.
2. Confirm the target database engine and its EF Core provider package (default: PostgreSQL/Npgsql per the locked stack — confirm before assuming a different provider is wanted).
3. Confirm whether ASP.NET Core Identity is the intended auth store (default: yes, backing JWT issuance) or whether an external identity provider is in play — this changes the `Data` project's entity base classes and the `Contexts` setup.
4. Confirm whether SignalR real-time push is a stated requirement for the first release. If not, skip `Hubs/` and the `AllowCredentials()` CORS requirement it forces — add both later, together, only when a real-time feature is actually being built.

---

**Phase 2 — Plan**

Produce a complete file-by-file plan. For each file specify: full path, responsibility, dependencies on other foundation files, and DI lifetime (if registered) per CLAUDE.md's lifetime table.

**`<Solution>.Data`:**

- `Contexts/<Solution>DbContext.cs` — extends `IdentityDbContext<User>` (or `DbContext` if not using Identity). `DbSet<T>` properties only. Applies all `IEntityTypeConfiguration<T>` classes via `modelBuilder.ApplyConfigurationsFromAssembly(...)` in `OnModelCreating` — never registers entity mapping inline in the context.
- `Entities/` — empty until the first feature; document the convention here (scalar constraints via data annotations, relationships via Fluent API, `CreatedAt`/`UpdatedAt`/`DeletedAt` on any entity that needs audit/soft-delete, `[ConcurrencyCheck] RowVersion` on any entity written concurrently — see `patterns/P2-soft-delete-and-concurrency.md`).
- `Configurations/` — empty until the first feature; one class per entity.
- `Migrations/` — created by the first `dotnet ef migrations add InitialCreate` once at least the Identity tables exist.

**`<Solution>.Repository`:**

- `Interfaces/IGenericRepository.cs` — CRUD + specification + count/exists only (CLAUDE.md Architecture rule 3). Signature:
  ```csharp
  public interface IGenericRepository<TEntity, TKey> where TEntity : class
  {
      Task<TEntity?> GetByIdAsync(TKey id);
      Task<TEntity?> GetByIdWithSpecAsync(ISpecification<TEntity> spec);
      Task<IReadOnlyList<TEntity>> ListAllAsync();
      Task<IReadOnlyList<TEntity>> ListAllWithSpecAsync(ISpecification<TEntity> spec);
      Task<TEntity> AddAsync(TEntity entity);
      Task<List<TEntity>> AddRangeAsync(List<TEntity> entities);
      void Update(TEntity entity);
      void Delete(TEntity entity);
      Task<int> CountAsync();
      Task<int> CountWithSpecAsync(ISpecification<TEntity> spec);
      Task<bool> ExistsAsync(TKey id);
  }
  ```
- `Repositories/GenericRepository.cs` — implements the above against the `DbContext`; `ListAllAsync`/`ListAllWithSpecAsync` use `AsNoTracking()` for read paths.
- `Interfaces/IUnitOfWork.cs` / `Repositories/UnitOfWork.cs` — `Repository<TEntity,TKey>()` factory, `SaveChangesAsync`, `BeginTransactionAsync`/`CommitAsync`/`RollbackAsync` (commit catches, rolls back, and rethrows — never swallows), plus a home for the small number of genuinely cross-cutting atomic operations that don't fit a single entity's generic repository (e.g. an atomic counter decrement via `ExecuteUpdateAsync`).
- `Specifications/ISpecification.cs`, `BaseSpecification.cs`, `SpecificationEvaluator.cs` — the Ardalis-style specification base: criteria expression, includes, ordering, paging.
- `Specifications/Paginated/PaginationSpecification.cs` — see `patterns/P1-pagination.md`.

**`<Solution>.Services`:**

- `Helper/ServiceResult.cs` — the envelope from CLAUDE.md "Response envelope," written once here, never redefined per feature.
- `Validators/` — empty until the first feature's validators exist; the assembly-scan registration (`AddValidatorsFromAssemblyContaining<T>`) is wired in `ServiceRegistration` pointing at whichever validator type exists first — update the anchor type as needed, but the registration call itself is written once, here.

**`<Solution>.WebAPI`:**

- `Middleware/ExceptionMiddleware.cs`, `NotFoundException.cs`, `ValidationException.cs` — the one error boundary (CLAUDE.md "Error handling"). `ExceptionMiddleware` maps `ValidationException` → 422 with the errors dictionary, `NotFoundException` → 404, anything else → 500 with dev-only detail gated on `IHostEnvironment.IsDevelopment()`.
- `Helpers/ResultActionResult.cs` — the one `IActionResult` wrapper (generic and non-generic overloads), reading `StatusCode` off the `ServiceResult`.
- `Helpers/ServiceRegistration.cs` — `AddApplicationServices(this IServiceCollection)`: `IUnitOfWork`, `IGenericRepository<,>` (open generic registration), AutoMapper (`AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies())`), FluentValidation (auto-validation + client-side adapters), `AddSignalR()` only if Phase-1 confirmed real-time is in scope, API versioning, authorization policies.
- `Extensions/IdentityServiceExtension.cs` — `AddIdentityService(IConfiguration)`: Identity + JWT bearer options (issuer/audience/signing key sourced from configuration, never hardcoded), token validation parameters.
- `Extensions/RateLimitingExtension.cs` — `AddRateLimiting(...)` (spelled correctly — see feature prompt anti-patterns for why this matters).
- `Extensions/SwaggerServiceExtension.cs` — `AddSwaggerDocumentation()` via NSwag, versioned per the `IApiVersionDescriptionProvider`.
- `Program.cs` — see the required pipeline order below.
- `appsettings.json` — shape only (empty `ConnectionStrings`, `Token` issuer/audience with no key value, feature-flag-style settings sections with safe defaults). `appsettings.Development.json` may contain non-secret local defaults (e.g. a localhost connection string with a throwaway local password is acceptable for local-only Development config **if and only if** that password grants no access to anything beyond a disposable local dev database — when in doubt, use `user-secrets` even for Development).
- `.editorconfig` at the solution root — see "Baseline `.editorconfig`" below.

**`<Solution>.WebAPI.Tests`:**

- `Architecture/ArchitectureLayeringTests.cs` — seed with the whole-solution version of CLAUDE.md's Architecture rules 1 and 4 (see the exact `NetArchTest` shape in `templates/layers/T2-repository.md` and `T4-dto.md`'s "Notes" sections). This file is created during scaffolding precisely so every subsequent feature is checked against it automatically — do not defer it to "later."
- `Common/MockFactories/`, `Common/Extensions/` — empty until the first test needs a shared fixture; do not pre-build fixtures speculatively.

---

**Required `Program.cs` pipeline order**

Middleware order is load-bearing — reordering silently changes behavior:

```
builder.Services: Controllers (+ enum-as-string JSON converter) → DataProtection → CORS policy
                → DbContext → Redis multiplexer → Options bindings (typed settings classes)
                → AddApplicationServices() → HostedServices → AddIdentityService()
                → AddRateLimiting() → AddSwaggerDocumentation()
                → AddHttpLogging() (Development only)

app: (Development: UseOpenApi + UseSwaggerUi + UseHttpLogging)
   → UseHsts() → UseHttpsRedirection()
   → UseCors(...)                          # before authentication/authorization, always
   → UseExceptionHandler("/error") → UseMiddleware<ExceptionMiddleware>()
   → UseRateLimiter()
   → UseRequestLocalization(...)           # only if the API serves more than one culture
   → UseAuthentication() → UseAuthorization()
   → MapControllers() → MapHub<...>(...)   # only if SignalR is in scope
```

`UseCors` must run before `UseAuthentication`/`UseAuthorization` — a preflight request never carries credentials, so CORS has to be settled first. If any SignalR hub needs `AllowCredentials()`, the CORS policy cannot also use `AllowAnyOrigin()` — it must list explicit origins (wildcarded subdomains are fine via `SetIsOriginAllowedToAllowWildcardSubdomains()`).

---

**Baseline `.editorconfig`**

Create one at the solution root covering, at minimum: file-scoped namespaces preferred, `var` preference for apparent types, using-directive sort order matching CLAUDE.md's "Code quality" section, and standard C# naming rules (PascalCase types/members, camelCase parameters/locals, `_camelCase` private fields) set to at least `suggestion` severity so violations show up in the IDE without failing the build on day one. This is the mechanical enforcement layer CLAUDE.md's style rules currently only state in prose — without this file, style consistency depends entirely on manual review.

---

**Edge Cases — All Must Be Addressed in the Plan:**

1. **Connection string resolution order:** configured value first, `DATABASE_URL`-style env var fallback second, password masked before any log write. Name this explicitly for whichever hosting target is in play.
2. **DI captive dependency:** if the plan registers anything as `Singleton` that needs per-request data, it must resolve that data via `IServiceScopeFactory`, never take a `Scoped` constructor parameter directly.
3. **Migrations run against a startup project, not the class library:** `dotnet ef` commands need `--project <Solution>.Data --startup-project <Solution>.WebAPI` — state this in whatever README/setup notes come out of scaffolding, so it isn't rediscovered by trial and error.
4. **CORS + credentials interaction:** `AllowCredentials()` and `AllowAnyOrigin()` are mutually exclusive in ASP.NET Core — the plan must show explicit allowed origins (with wildcard-subdomain support if needed) the moment any SignalR hub is added.
5. **Exception middleware placement:** `UseExceptionHandler` and `UseMiddleware<ExceptionMiddleware>()` both present is intentional layering (the built-in handler as an outer safety net, the custom middleware for `ServiceResult`-shaped output) — the plan must not collapse these into one without checking what each currently guarantees.
6. **Rate limiting scope:** confirm which endpoints (all vs. auth-sensitive only, e.g. login/OTP) need rate limiting in the first pass — don't apply a single blanket policy without checking whether any endpoint (webhooks from a payment/notification provider, for instance) needs to be exempted.
7. **Retry strategy vs. manual transactions:** if `EnableRetryOnFailure` is ever added to the `DbContext` options, every `BeginTransactionAsync` call site in the codebase must be wrapped in `IExecutionStrategy.ExecuteAsync(...)` per EF Core's docs — Npgsql's (and SQL Server's) retrying execution strategy is incompatible with user-initiated transactions otherwise. Default to **not** enabling retry-on-failure until this is deliberately taken on solution-wide.
8. **Nullable reference types on entities:** EF Core sets non-nullable entity properties via reflection/materialization, bypassing constructor nullability checks — decide up front whether required scalar properties use `required` (C# 11+) or are left implicitly non-null-but-uninitialized, and apply the choice consistently rather than mixing both across entities.

---

⛔ Do not write any code yet. Produce the full file plan with responsibilities
   and wait for approval before writing a single line of C#.

---

> **Companion:** `dotnet_feature_prompt.md` owns everything inside a single feature/module once the foundation above exists. Read it alongside this file when building the first feature.
