# Your Space

> A personal relationship & event-planning tool: track the people in your life, group them into circles, plan events, build guest lists, and never forget who invited you to what.

![Monorepo](https://img.shields.io/badge/repo-monorepo-blue)
![Backend](https://img.shields.io/badge/backend-.NET%2010%20%2F%20ASP.NET%20Core-512BD4)
![Mobile](https://img.shields.io/badge/mobile-Flutter%203.44.8-02569B)
![Database](https://img.shields.io/badge/database-PostgreSQL-336791)
![License](https://img.shields.io/badge/license-unlicensed-lightgrey)

## Table of Contents

- [What this is](#what-this-is)
- [Repository layout](#repository-layout)
- [Tech stack at a glance](#tech-stack-at-a-glance)
- [Product features](#product-features)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Running the backend](#running-the-backend)
  - [Running the mobile app](#running-the-mobile-app)
  - [Running both together](#running-both-together)
- [Architecture](#architecture)
- [API surface](#api-surface)
- [Environment & secrets](#environment--secrets)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Documentation & handoffs](#documentation--handoffs)
- [Contributing](#contributing)
- [Known limitations / TODO](#known-limitations--todo)
- [License](#license)

## What this is

Your Space is a private, single-user-scoped CRM for someone's own social circle — not a multi-tenant social network. A logged-in user maintains **Groups** (e.g. "Family", "Coworkers") and **People** assigned to a group, creates **Events**, builds a per-event guest list from those People, tracks each guest through an invitation status lifecycle, and logs **reciprocity history** — whether a contact has invited *them* to something in the past — so social obligations don't get forgotten.

The product is split into two independently governed, independently deployed projects that share this repo:

| Project | What it is | Full documentation |
|---|---|---|
| **Backend** — `Your-Space-Backend/` | ASP.NET Core / .NET 10 REST API, PostgreSQL, JWT auth, EN/AR localization | [Your-Space-Backend/README.md](Your-Space-Backend/README.md) |
| **Mobile** — `Your-Space-Mobile/` | Flutter app (Android + iOS), Clean Architecture, Cubit state management | [Your-Space-Mobile/README.md](Your-Space-Mobile/README.md) |

This root document is the map of the whole product — for exhaustive, per-project detail (every endpoint, every DI scope, every env var, full test taxonomy) follow the links into each project's own README, which is the authority for its folder.

## Repository layout

```
Your-Space/
├── CLAUDE.md                  # Cross-project rules: never blend one project's
│                               # conventions into the other; each folder is
│                               # independently governed by its own CLAUDE.md
├── doc/
│   └── context/                # Point-in-time engineering audits (dated — see
│                                # "Documentation & handoffs" below for caveats)
├── Your-Space-Backend/         # ASP.NET Core solution — see its own README.md
│   ├── YourSpace.Data/            entities, EF Core configurations, migrations
│   ├── YourSpace.Repository/       generic repository + UnitOfWork + specifications
│   ├── YourSpace.Services/         business logic, DTOs, FluentValidation validators
│   ├── YourSpace.WebAPI/           controllers, middleware, DI wiring, Program.cs
│   ├── YourSpace.WebAPI.Tests/     xUnit: Unit / Integration / Architecture tests
│   ├── doc/handoffs/                dated engineering handoff notes
│   ├── Dockerfile                   multi-stage build, listens on :8080
│   └── CLAUDE.md + .claude/rules/    backend-specific standards (authoritative for this folder)
└── Your-Space-Mobile/          # Flutter app — see its own README.md
    ├── lib/
    │   ├── core/                    shared infrastructure (DI, networking, routing, theme)
    │   └── features/                 auth, home, groups, people, events (feature-first, Clean Architecture)
    ├── test/                        mirrors lib/ structure
    ├── assets/translations/          en.json, ar.json (easy_localization)
    ├── doc/handoffs/                 dated engineering handoff notes
    ├── doc/design/                    exported design system + HTML mockups
    ├── .fvmrc                        pins Flutter 3.44.8
    └── CLAUDE.md + .claude/rules/     mobile-specific standards (authoritative for this folder)
```

## Tech stack at a glance

| Layer | Stack | Version source |
|---|---|---|
| Backend runtime | ASP.NET Core / .NET **10.0** | `*.csproj` (`TargetFramework`) |
| Backend database | PostgreSQL via Npgsql EF Core provider **10.0.3** | `YourSpace.Data.csproj` |
| Backend auth | ASP.NET Core Identity + JWT Bearer | `YourSpace.WebAPI/Extensions/IdentityServiceExtension.cs` |
| Mobile framework | Flutter **3.44.8** (pinned via FVM), Dart `^3.12.2` | `.fvmrc`, `pubspec.yaml` |
| Mobile state management | `flutter_bloc` (Cubit) **^9.1.1** | `pubspec.yaml` |
| Mobile DI | `get_it` + `injectable` | `pubspec.yaml` |
| Cross-cutting | Bilingual (English/Arabic, RTL-aware) end to end | both `CLAUDE.md` files, Architecture rule 8 (backend) |

Full dependency lists with every package and version live in each project's own README — [Backend tech stack](Your-Space-Backend/README.md#tech-stack) / [Mobile tech stack](Your-Space-Mobile/README.md#tech-stack).

## Product features

The full-stack feature set, as actually implemented (backend controllers + mobile screens/cubits — not aspirational):

- **Authentication** — register, login, JWT access + rotating refresh tokens, email confirmation via OTP, forgot/reset password, change password. Mobile handles token refresh transparently (`AuthInterceptor`); backend enforces per-IP rate limiting on all auth endpoints.
- **Groups** — CRUD for contact circles, searchable and paginated.
- **People** — CRUD for personal contacts, each assigned to a Group.
- **Events** — CRUD for occasions being planned, with a live guest-count breakdown (not invited / invited / skipped).
- **Guest-List / Invitation Planner** — bulk-add People or a whole Group to an Event, per-guest status transitions (invite / skip / revert), and a progress summary per event.
- **Reciprocity** — a per-person log of past occasions where *they* invited the user, plus a "reciprocity suggestions" endpoint/screen surfacing contacts who've invited the user before but haven't been added to the current event yet.
- **User settings** — per-user preference flags (e.g. toggling reciprocity suggestions).
- **Role-based access control** — `User` / `StandardAdmin` / `SuperAdmin` hierarchy on the backend, with a bootstrap SuperAdmin seeder.
- **Bilingual (EN/AR) throughout** — every user-facing entity field and every response/validation message on the backend has an Arabic counterpart resolved server-side; the mobile app mirrors this with `easy_localization` and RTL-aware layout primitives end to end.

See each project's own README for the endpoint-by-endpoint / screen-by-screen breakdown: [Backend features](Your-Space-Backend/README.md#features) / [Mobile features](Your-Space-Mobile/README.md#features).

## Getting started

### Prerequisites

- **.NET SDK 10.0.202+** — backend
- **PostgreSQL** and **Redis** — local instances for backend development
- **Flutter 3.44.8** (via [FVM](https://fvm.app/), pinned in `Your-Space-Mobile/.fvmrc`) — mobile
- Android Studio / Xcode toolchains if building mobile for a device/emulator

### Running the backend

```bash
cd Your-Space-Backend
dotnet user-secrets init --project YourSpace.WebAPI
dotnet user-secrets set "ConnectionStrings:YourSpaceDB" "Host=localhost;Port=5432;Database=yourspace;Username=postgres;Password=<local-only>" --project YourSpace.WebAPI
dotnet user-secrets set "Jwt:Key" "<dev-only-signing-key>" --project YourSpace.WebAPI
dotnet restore
dotnet run --project YourSpace.WebAPI
```

Full setup, migrations, Docker build, and every environment variable: [Your-Space-Backend/README.md](Your-Space-Backend/README.md#getting-started).

### Running the mobile app

```bash
cd Your-Space-Mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Full setup, environment switching (`--dart-define=ENVIRONMENT=prod`), and build commands: [Your-Space-Mobile/README.md](Your-Space-Mobile/README.md#getting-started).

### Running both together

The mobile app's `ApiConstants.baseUrl` (`Your-Space-Mobile/lib/core/constants/api_constants.dart`) must point at a reachable instance of the backend — either the locally-run API above or the shared dev deployment already configured there. There is no orchestration tool (Docker Compose, etc.) wiring the two together in this repo — each project is started independently.

## Architecture

Each project owns its own architecture, enforced independently and never blended (per the root `CLAUDE.md`):

- **Backend** — strict layered architecture (`WebAPI → Services → Repository → Data`), physically split into separate class-library projects, with `NetArchTest` assertions enforcing the layer direction and DTO purity in CI-less local test runs. See [Backend architecture](Your-Space-Backend/README.md#architecture-overview).
- **Mobile** — Clean Architecture, feature-first (`presentation → domain → data` per feature, `lib/core/` for shared infrastructure), with features never importing from other features. See [Mobile architecture](Your-Space-Mobile/README.md#architecture-overview).

The two communicate over a single contract: a versioned (`/api/v1/...`) JSON REST API with a uniform `{ success, message, errorCode, data, statusCode, timestamp, errors }` response envelope, produced by the backend's `ServiceResult<T>` and consumed by the mobile app's `unwrapServiceResult`/`ApiManager`.

## API surface

Base path: `/api/v1/...`, Bearer JWT auth, EN/AR via `Accept-Language`. Endpoint groups: `auth`, `groups`, `persons`, `events` (+ nested `events/{id}/guests`), `persons/{id}/occasion-history`, `usersettings`. Full endpoint-by-endpoint tables (methods, routes, DTOs): [Backend API overview](Your-Space-Backend/README.md#api-overview).

## Environment & secrets

Neither project commits real secrets. The backend uses `dotnet user-secrets` locally and environment variables/a secrets manager in deployed environments (`appsettings*.json` holds shape only). The mobile app has no secrets to configure at build time — it only switches a compile-time `ENVIRONMENT` define between `dev`/`prod` base URLs, and acquires session tokens at runtime via login. Full key-by-key tables: [Backend env vars](Your-Space-Backend/README.md#environment-variables-reference) / [Mobile env vars](Your-Space-Mobile/README.md#environment-variables-reference).

## Testing

| Project | Framework | What's covered |
|---|---|---|
| Backend | xUnit + `NetArchTest` | Unit tests per service method, `WebApplicationFactory` integration tests per controller, architecture/layering assertions |
| Mobile | `flutter_test` + `mocktail` | 48 test files mirroring `lib/`: router, storage, widgets, and per-feature repository/cubit/screen tests |

Run each project's suite from inside its own folder — `dotnet test` (backend) / `flutter test` (mobile). Details: [Backend testing](Your-Space-Backend/README.md#testing) / [Mobile testing](Your-Space-Mobile/README.md#testing).

## CI/CD

> ⚠️ Not detected anywhere in this repo. No `.github/workflows/`, `azure-pipelines.yml`, `codemagic.yaml`, or similar pipeline configuration exists for either project. Builds, tests, and deploys are currently run manually. The backend ships a ready-to-use multi-stage `Dockerfile` for PaaS hosting (Coolify/Render/Railway-style), but nothing triggers it automatically.

## Documentation & handoffs

Each project keeps dated engineering handoff notes under its own `doc/handoffs/<NNN-feature-name>/`, written at the time a feature landed. The root `doc/context/` folder holds two point-in-time, deeply-verified engineering audits (`project-status.md`, `next-feature-status.md`) — useful for historical context on *why* things are shaped the way they are, but **dated 2026-07-27/28 and already stale on specific claims** (e.g. they describe the mobile app as having no feature code yet, which is no longer true — `lib/features/` is now fully built out per [Mobile features](Your-Space-Mobile/README.md#features)). Treat anything time-sensitive in `doc/` as a historical snapshot, not current state — the two project READMEs and the code itself are the source of truth.

## Contributing

Governed by the root `CLAUDE.md`:

- Each project's own `CLAUDE.md` (plus its `.claude/rules/`, `.claude/templates/`) is the authority for everything inside its folder — never apply the backend's architecture rules/naming/anti-patterns to the mobile app or vice versa, even where a section name matches (e.g. both have a "Testing discipline" section that means something different in each).
- A task that spans both projects (e.g. a new backend endpoint plus the mobile screen that calls it) should keep each half strictly inside its own project's conventions rather than blending them into one style.
- Commit convention observed in history: a loose `feat: <description>` prefix for feature work, plain imperative messages otherwise.
- Adding a new project (e.g. a web frontend): give it its own top-level folder with its own `CLAUDE.md` + `.claude/rules/` + `.claude/templates/`, and add a row to the table in the root `CLAUDE.md`.

## Known limitations / TODO

- No automated CI/CD pipeline for either project.
- No `LICENSE` file anywhere in the repo — see [License](#license).
- No orchestration (Docker Compose, etc.) to run backend + database + mobile together with one command — each is started independently today.
- See each project's own README for project-specific gaps ([Backend](Your-Space-Backend/README.md#known-limitations--todo) / [Mobile](Your-Space-Mobile/README.md#known-limitations--todo)).

## License

> No license file detected — treat as unlicensed/proprietary.
