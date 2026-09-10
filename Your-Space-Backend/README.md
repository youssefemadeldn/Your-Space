# YourSpace API

> ASP.NET Core backend for **Your Space** — a personal relationship & event-planning tool for tracking people, groups, and invitation-worthy occasions.

![.NET](https://img.shields.io/badge/.NET-10.0-512BD4)
![EF Core](https://img.shields.io/badge/EF%20Core-10.0.10-512BD4)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Npgsql%2010.0.3-336791)
![Tests](https://img.shields.io/badge/tests-xUnit%20%2B%20NetArchTest-25A162)
![License](https://img.shields.io/badge/license-unlicensed-lightgrey)

## Table of Contents

- [What this is](#what-this-is)
- [Tech stack](#tech-stack)
- [Architecture overview](#architecture-overview)
- [Features](#features)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Environment setup](#environment-setup)
  - [Installation](#installation)
  - [Run](#run)
  - [Build](#build)
- [Project structure](#project-structure)
- [API overview](#api-overview)
- [State/response pattern](#stateresponse-pattern)
- [Dependency injection](#dependency-injection)
- [Environment variables reference](#environment-variables-reference)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Contributing](#contributing)
- [Known limitations / TODO](#known-limitations--todo)
- [License](#license)

## What this is

YourSpace API is the backend for an app that helps a person keep track of the people in their life (contacts, grouped into circles), the events they plan, who they've invited to what, and a "reciprocity" history of who has invited *them* to things — so social obligations don't get forgotten. It exposes a versioned, JWT-authenticated REST API, fully localized in English and Arabic, consumed today by a companion Flutter mobile app.

## Tech stack

**Runtime & framework**
- .NET **10.0** (`net10.0`), ASP.NET Core Web API, nullable reference types + implicit usings enabled solution-wide

**Data / persistence**
- EF Core **10.0.10** with **Npgsql.EntityFrameworkCore.PostgreSQL 10.0.3** (PostgreSQL)
- Generic Repository + Unit of Work + Specification pattern (`YourSpace.Repository`)
- Redis via `Microsoft.Extensions.Caching.StackExchangeRedis` **10.0.10** + `StackExchange.Redis` connection multiplexer

**Auth**
- ASP.NET Core Identity (`Microsoft.AspNetCore.Identity.EntityFrameworkCore` **10.0.10**) backing JWT issuance
- `Microsoft.AspNetCore.Authentication.JwtBearer` **10.0.10**, `System.IdentityModel.Tokens.Jwt` **8.21.0**
- Custom refresh-token rotation + revocation (hashed tokens, IP tracking)

**Validation / mapping**
- `FluentValidation.AspNetCore` **11.3.1** (global auto-validation, one validator class per mutating DTO)
- `AutoMapper` **16.2.0**

**API surface**
- `Asp.Versioning.Mvc` / `.ApiExplorer` **10.0.0** (URL-segment versioning, `v{version:apiVersion}`)
- `NSwag.AspNetCore` **14.7.1** (OpenAPI/Swagger UI, JWT bearer security scheme wired in)
- `Microsoft.AspNetCore.OpenApi` **10.0.10**

**Cross-cutting**
- `Serilog.AspNetCore` **10.0.0** (structured console logging)
- Built-in `Microsoft.AspNetCore.RateLimiting` (fixed-window, per-IP: global + a stricter auth-endpoint policy)
- `Microsoft.Extensions.Localization` / `Microsoft.AspNetCore.Localization` — English/Arabic resource-based localization
- `MailKit` **4.17.0** (SMTP email — confirmation/reset codes)
- `Bogus` **35.6.5** (dev-only realistic fake seed data)
- `Polly` **8.7.0** (resilience, referenced at the WebAPI layer)

**Testing**
- `xunit` **2.9.3**, `Moq` **4.20.72**, `FluentAssertions` **7.2.2**, `Bogus`
- `Microsoft.AspNetCore.Mvc.Testing` **10.0.10** (`WebApplicationFactory` integration tests)
- `Microsoft.EntityFrameworkCore.Sqlite` **10.0.10** (fast in-memory-style integration DB)
- `Testcontainers` / `Testcontainers.Redis` **4.13.0** (real-dependency tests)
- `NetArchTest.Rules` **1.3.2** (architecture/layering assertions as unit tests)

**DevOps**
- Multi-stage `Dockerfile` (SDK 10.0 build stage → ASP.NET 10.0 runtime stage), listens on port `8080` for PaaS-style hosts (Coolify/Render/Railway)
- No CI/CD pipeline is configured in this repository — see [CI/CD](#cicd)

## Architecture overview

Strict **layered architecture**, enforced not just by convention but physically — each layer is its own class-library project, and cross-layer references are checked by `NetArchTest` assertions in the test suite (`WebAPI.Tests/Architecture/ArchitectureLayeringTests.cs`), not just written down as a rule:

```
WebAPI  →  Services  →  Repository  →  Data
```

A project may only reference the layer directly below it — `Services` never references `WebAPI`, `Repository` never references `Services`, and controllers never touch the `DbContext` directly (only services do). DTOs under `Services/**/Dtos/` never reference EF Core or entity types — mapping between entities and DTOs happens once, at the service boundary, via AutoMapper.

Every request that mutates state and needs validation goes through a global FluentValidation pipeline; every unexpected failure funnels through exactly one error boundary (`ExceptionMiddleware`); every service method returns one uniform envelope (`ServiceResult<T>`), which a single `ResultActionResult` wrapper turns into the HTTP response. See [State/response pattern](#stateresponse-pattern).

```
Your-Space-Backend/
├── YourSpace.Data/            # EF Core entities, configurations, DbContext, migrations
│   ├── Entities/               # POCO entity classes (scalar constraints only)
│   ├── Configurations/         # IEntityTypeConfiguration<T> — keys, indexes, relationships
│   ├── Contexts/                # YourSpaceDbContext (DbSet<T> properties only)
│   ├── Enums/                   # Domain enums (serialized as strings at the API boundary)
│   └── Migrations/              # EF Core migrations (never hand-edited post-deploy)
├── YourSpace.Repository/       # Generic repository + UnitOfWork + Specification pattern
│   ├── Interfaces/               # IGenericRepository<,>, IUnitOfWork
│   ├── Repositories/             # GenericRepository<,>, UnitOfWork
│   └── Specifications/           # One <Feature>Specifications/<Entity>WithSpecs per query shape
├── YourSpace.Services/         # Business logic, DTOs, validators, localization resources
│   ├── Services/<Feature>Service/    # I<Feature>Service + <Feature>Service + Dtos/
│   ├── Validators/                    # FluentValidation validators, one per mutating DTO
│   ├── Helper/                        # ServiceResult, PaginatedResultDto, LocalizedTextResolver
│   └── Resources/                     # SharedResource.{en,ar}.resx — every user-facing string
├── YourSpace.WebAPI/           # Controllers, middleware, DI wiring, Program.cs
│   ├── Controllers/               # Thin controllers — parse input, call one service method
│   ├── Middleware/                 # ExceptionMiddleware (the one error boundary)
│   ├── Extensions/                 # AddIdentityService, AddRateLimiting, AddSwaggerDocumentation, ...
│   └── Helpers/                    # ServiceRegistration (DI), ResultActionResult, MockDataSeeder
├── YourSpace.WebAPI.Tests/     # Unit / Integration / Architecture / Common test projects
└── doc/handoffs/               # Dated engineering handoff notes per feature milestone
```

## Features

Derived from the actual controllers, services, and entities in `YourSpace.WebAPI/Controllers` and `YourSpace.Data/Entities`:

- **Authentication & account management** (`AuthController`) — register, login, JWT access + rotating refresh tokens, logout/revoke, change password, "me" profile
- **Email confirmation & password reset via OTP** (`OtpService`, `EmailConfirmationCode`, `PasswordResetCode`) — 6-digit codes looked up by `(UserId, not-yet-consumed)` then hash-compared, never indexed by hash directly (avoids low-entropy collisions)
- **People** (`PersonsController`) — CRUD for personal contacts, each belonging to one Group, owned by one user, paginated + searchable
- **Groups** (`GroupsController`) — CRUD for contact circles that People belong to
- **Events** (`EventsController`) — CRUD for occasions the user is planning, with live guest-count breakdowns (not invited / invited / skipped)
- **Event Guest-List / Invitation Planner** (`EventGuestsController`) — bulk-add People or a whole Group to an Event, per-guest status transitions (invite / skip / revert), progress summary, and reciprocity suggestions (people who've invited *you* before but haven't been added yet)
- **Reciprocity history** (`PersonOccasionHistoryController`) — per-Person log of past occasions where they invited the user, and how
- **User settings** (`UserSettingsController`) — per-user preference flags (e.g. toggling reciprocity suggestions)
- **Role-based access control** — `User` / `StandardAdmin` / `SuperAdmin` hierarchy (`RoleNames`), with `AdminOnly`/`SuperAdminOnly` authorization policies and a bootstrap `IdentitySeeder` for the roles + first SuperAdmin
- **Bilingual (EN/AR) content everywhere** — every user-facing entity field has an `Ar` counterpart resolved to a single field per response; every `ServiceResult`/validation message comes from `IStringLocalizer<SharedResource>`
- **Dev-only realistic mock data** (`MockDataSeeder`, gated behind `IsDevelopment()`) — every entity ships with `Bogus`-generated sample rows plus deliberate edge cases

## Getting started

### Prerequisites

- **.NET SDK 10.0.202+** (`net10.0` target framework across all projects)
- **PostgreSQL** — local instance for development (Npgsql provider)
- **Redis** — local instance for development (distributed cache + connection multiplexer)

### Environment setup

Real secrets never live in `appsettings.json`/`appsettings.<Environment>.json` — those files hold shape only (see [Environment variables reference](#environment-variables-reference)). Locally, use `dotnet user-secrets`:

```bash
dotnet user-secrets init --project YourSpace.WebAPI
dotnet user-secrets set "ConnectionStrings:YourSpaceDB" "Host=localhost;Port=5432;Database=yourspace;Username=postgres;Password=<local-only>" --project YourSpace.WebAPI
dotnet user-secrets set "Jwt:Key" "<dev-only-signing-key>" --project YourSpace.WebAPI
```

In deployed environments, values come from environment variables or a secrets manager. `ConnectionStrings:YourSpaceDB` can alternatively be supplied via a `DATABASE_URL` env var in `postgres://user:pass@host:port/db` form (Railway/Render/Coolify convention) — see `YourSpace.WebAPI/Helpers/ConnectionStringResolver.cs`.

### Installation

```bash
dotnet restore
dotnet build
```

### Run

```bash
# Development (applies pending EF Core migrations + dev mock data automatically)
dotnet run --project YourSpace.WebAPI

# Watch mode
dotnet watch --project YourSpace.WebAPI run

# Against a specific environment
ASPNETCORE_ENVIRONMENT=Production dotnet run --project YourSpace.WebAPI
```

Swagger UI is only enabled in `Development` (`app.UseOpenApi()` / `app.UseSwaggerUi()`). Two environments are configured: `Development` (verbose HTTP logging, Swagger UI, auto-migrate + mock seed) and `Production` (HSTS, no Swagger, generic error detail).

**EF Core migrations** (Data project owns the model; WebAPI is the startup project):

```bash
dotnet ef migrations add <MigrationName> --project YourSpace.Data --startup-project YourSpace.WebAPI
dotnet ef database update --project YourSpace.Data --startup-project YourSpace.WebAPI
```

`Production` never auto-migrates on boot — `dotnet ef database update` is always run as an explicit, reviewed deploy step.

### Build

```bash
dotnet publish YourSpace.WebAPI -c Release -o ./publish
```

Or via the provided multi-stage `Dockerfile` (SDK 10.0 build → ASP.NET 10.0 runtime, listens on `:8080`):

```bash
docker build -t yourspace-api .
docker run -p 8080:8080 --env-file .env yourspace-api
```

## Project structure

See [Architecture overview](#architecture-overview) above for the annotated tree — the same layered structure doubles as the project's physical layout.

## API overview

- **Base URL:** `https://<host>/api/v{version}` — currently `v1.0` for every endpoint, via `Asp.Versioning` URL-segment versioning
- **Auth:** Bearer JWT (`Authorization: Bearer <token>`) issued by `POST /api/v1/auth/login`, refreshed via `POST /api/v1/auth/refresh-token`; wired through NSwag's Swagger UI security scheme for interactive testing
- **Response envelope:** every endpoint returns the same JSON shape (`ServiceResult`) — see [State/response pattern](#stateresponse-pattern)
- **Localization:** every response respects `Accept-Language: en` / `ar` (default `en`)
- **Rate limiting:** global per-IP fixed-window limit on all endpoints, plus a stricter per-IP window specifically on auth endpoints (register/login/OTP/reset flows)

**Endpoint groups:**

| Group | Base route | Notes |
|---|---|---|
| Auth | `/api/v1/auth` | register, login, refresh/revoke token, confirm-email, resend-confirmation, forgot/reset password, change-password, `me` |
| Groups | `/api/v1/groups` | CRUD, paginated + searchable, owner-scoped |
| Persons | `/api/v1/persons` | CRUD, filter by group, paginated + searchable, owner-scoped |
| Events | `/api/v1/events` | CRUD, paginated + searchable, owner-scoped, includes guest-count summary |
| Event Guests | `/api/v1/events/{eventId}/guests` | bulk-add (by person list or whole group), status transitions, progress, reciprocity suggestions |
| Person Occasion History | `/api/v1/persons/{personId}/occasion-history` | CRUD reciprocity log entries |
| User Settings | `/api/v1/usersettings` | get/update per-user preference flags |

## State/response pattern

Every service method returns `ServiceResult<T>` / `ServiceResult` (`YourSpace.Services/Helper/ServiceResult.cs`):

```csharp
public class ServiceResult<T>
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public string? ErrorCode { get; set; }   // stable, non-localized — clients branch on this, never on Message
    public T? Data { get; set; }
    public int StatusCode { get; set; }
    public DateTime Timestamp { get; set; }
    public Dictionary<string, string[]>? Errors { get; set; }
}
```

Controllers stay thin — they call one service method and wrap the result in the single `ResultActionResult<T>` (`YourSpace.WebAPI/Helpers/ResultActionResult.cs`), e.g. `EventsController.cs`. Expected failures (not found, conflict) are guard clauses returning a specific `ServiceResult` factory method; unexpected exceptions bubble to `ExceptionMiddleware` (`YourSpace.WebAPI/Middleware/ExceptionMiddleware.cs`), the one place that decides dev-vs-prod error detail.

## Dependency injection

All application service registrations live in one place: `ServiceRegistration.AddApplicationServices()` (`YourSpace.WebAPI/Helpers/ServiceRegistration.cs`), grouped by feature area (repository/UoW, AutoMapper, FluentValidation, Auth services, feature services, API versioning, authorization policies). Identity/JWT wiring lives separately in `Extensions/IdentityServiceExtension.cs`.

To register a new feature service: add `services.AddScoped<IYourFeatureService, YourFeatureService>();` under the relevant comment group in `ServiceRegistration.cs`. Lifetime conventions (see backend `CLAUDE.md` for the full table):

| Class type | Lifetime |
|---|---|
| `GenericRepository<,>`, `UnitOfWork` | Scoped |
| Feature services (`I<Feature>Service`) | Scoped |
| Stateless helpers with no per-request state (`TokenService`) | Singleton |
| `IHostedService` background jobs | Framework-managed singleton, resolves its own scope per cycle |
| Cross-cutting infra (`IConnectionMultiplexer`) | Singleton |

## Environment variables reference

Keys only — real values are never committed (see [Environment setup](#environment-setup)). Source: `YourSpace.WebAPI/appsettings.json`.

| Key | Purpose | Required? |
|---|---|---|
| `ConnectionStrings:YourSpaceDB` | PostgreSQL connection string (or supply via `DATABASE_URL` env var) | Yes |
| `Jwt:Issuer` | JWT issuer claim | Yes (has a default: `YourSpace`) |
| `Jwt:Audience` | JWT audience claim | Yes (has a default: `YourSpaceClients`) |
| `Jwt:Key` | JWT signing key — app throws on startup if unset | Yes, secret |
| `Jwt:AccessTokenExpirationMinutes` | Access token lifetime | No (default `15`) |
| `Jwt:RefreshTokenExpirationDays` | Refresh token lifetime | No (default `7`) |
| `Email:SmtpHost` / `SmtpPort` / `SmtpUsername` / `SmtpPassword` | SMTP server for confirmation/reset emails | Yes (for email flows), password is secret |
| `Email:SenderEmail` / `SenderName` | From-address for outgoing email | Yes |
| `Email:EnableSsl` | Toggle SMTP SSL | No (default `true`) |
| `SuperAdmin:Email` / `Password` / `FirstName` / `LastName` | Bootstrap SuperAdmin account created by `IdentitySeeder` | Yes, password is secret |
| `Redis:ConnectionString` | Redis connection string (cache + connection multiplexer) | Yes |
| `AllowedOrigins` | CORS allow-list (array of origins) | Yes for browser clients |
| `RateLimiting:GlobalPermitLimit` / `GlobalWindowSeconds` | Global per-IP rate limit | No (defaults `100`/`60`) |
| `RateLimiting:AuthPermitLimit` / `AuthWindowSeconds` | Stricter per-IP limit on auth endpoints | No (defaults `5`/`60`) |
| `Serilog:*` | Structured logging sinks/levels | No (has defaults) |

## Testing

Test taxonomy lives entirely under `YourSpace.WebAPI.Tests/`:

| Category | Path | What it covers |
|---|---|---|
| Unit | `Unit/Services/<Feature>Service/` | One file per service method (`<Service>_<Method>Tests.cs`) — Auth, Otp, Event, EventGuest, Group, Person, PersonOccasionHistory, UserSettings services all covered |
| Integration (Controllers) | `Integration/Controllers/` | `WebApplicationFactory`-driven HTTP tests per controller |
| Architecture | `Architecture/ArchitectureLayeringTests.cs` | `NetArchTest` assertions enforcing the layer-direction and DTO-purity rules described above |
| Common | `Common/` | Shared `TestWebApplicationFactory`, mock factories (localizer, mapper, `UserManager`), fakes (`FakeEmailSender`) |

```bash
dotnet test
dotnet test --filter FullyQualifiedName~YourSpace.WebAPI.Tests.Architecture
```

## CI/CD

> ⚠️ Not detected in this repo. No `.github/workflows/`, `azure-pipelines.yml`, `.gitlab-ci.yml`, or similar pipeline configuration exists. Builds, tests, and deploys are currently run manually (the `Dockerfile` is ready for a PaaS host such as Coolify/Render/Railway, but no automated pipeline triggers it).

## Contributing

Not formally documented in this repo. Based on observed git history:

- Commit messages follow a loose `feat: <description>` convention for feature work, with plain imperative descriptions for other changes (see `git log`).
- Engineering context per milestone is captured as dated handoff notes under `doc/handoffs/<NNN-feature-name>/`.
- Suggested default (not enforced): branch per feature, PRs reviewed against the architecture rules and pre-ship checklist in `CLAUDE.md` before merging.

## Known limitations / TODO

- No automated CI/CD pipeline (see [CI/CD](#cicd)).
- No `LICENSE` file — see [License](#license).
- No `SignalR` hubs are wired up yet (`Hubs/` is a documented convention in `CLAUDE.md` but has no real-time feature using it today).
- No explicit `TODO`/`FIXME`/`NotImplementedException` markers were found in the current codebase — outstanding work is instead tracked narratively in `doc/handoffs/`.

## License

> No license file detected — treat as unlicensed/proprietary.
