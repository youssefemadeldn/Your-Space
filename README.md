# Your Space

> A personal relationship & event-planning tool: track the people in your life, group them into circles, plan events, build guest lists, and never forget who invited you to what.

![Monorepo](https://img.shields.io/badge/repo-monorepo-blue)
![Backend](https://img.shields.io/badge/backend-.NET%2010%20%2F%20ASP.NET%20Core-512BD4)
![Mobile](https://img.shields.io/badge/mobile-Flutter%203.44.8-02569B)
![App version](https://img.shields.io/badge/app-v5.0.1%2B10-brightgreen)
![Database](https://img.shields.io/badge/database-PostgreSQL-336791)
![License](https://img.shields.io/badge/license-unlicensed-lightgrey)

## Table of Contents

- [Screens](#screens)
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

## Screens

> These are captures from the **design prototype** (`Your-Space-Mobile/doc/design/*.dc.html`), not the live running app — see [Known limitations / TODO](#known-limitations--todo) for real-device screenshots. Full set of frames (loading/empty/wizard-step variants included) lives in [`Your-Space-Mobile/doc/design/screenshots/`](Your-Space-Mobile/doc/design/screenshots/); a `design-conformance-fixes.md` drift log tracks where the code has since diverged from these mocks.

<!-- SCREENS_GALLERY_PLACEHOLDER -->
<table>
<tr>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/01-login.png" width="180" alt="Login"><br>
<sub>Login</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/02-register.png" width="180" alt="Register (with gender field)"><br>
<sub>Register</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/03-confirm-email-otp.png" width="180" alt="Confirm email (OTP)"><br>
<sub>Confirm email (OTP)</sub>
</td>
</tr>
<tr>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/04-forgot-password.png" width="180" alt="Forgot password"><br>
<sub>Forgot password</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/05-reset-password.png" width="180" alt="Reset password"><br>
<sub>Reset password</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/06-change-password.png" width="180" alt="Change password (authenticated)"><br>
<sub>Change password</sub>
</td>
</tr>
<tr>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/07-home.png" width="180" alt="Home"><br>
<sub>Home</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/08-groups-list.png" width="180" alt="Groups — list"><br>
<sub>Groups — list</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/09-create-group.png" width="180" alt="Create group (bottom sheet)"><br>
<sub>Create group</sub>
</td>
</tr>
<tr>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/10-people-list.png" width="180" alt="People — list"><br>
<sub>People — list</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/11-add-person-wizard.png" width="180" alt="Add person — 4-step wizard"><br>
<sub>Add person (wizard)</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/12-person-details.png" width="180" alt="Person details & occasion history"><br>
<sub>Person details & history</sub>
</td>
</tr>
<tr>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/13-add-occasion.png" width="180" alt="Add occasion (reciprocity)"><br>
<sub>Add occasion</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/14-events-list.png" width="180" alt="Events — list"><br>
<sub>Events — list</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/15-create-event.png" width="180" alt="Create event"><br>
<sub>Create event</sub>
</td>
</tr>
<tr>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/16-event-details.png" width="180" alt="Event details (progress dashboard)"><br>
<sub>Event details</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/17-event-guests.png" width="180" alt="Event guests — filter & status"><br>
<sub>Event guests</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/18-add-guests-people.png" width="180" alt="Add guests — People tab"><br>
<sub>Add guests — People tab</sub>
</td>
</tr>
<tr>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/19-add-guests-group.png" width="180" alt="Add guests — By group tab"><br>
<sub>Add guests — By group tab</sub>
</td>
<td align="center" width="200">
<img src="Your-Space-Mobile/doc/design/screenshots/20-reciprocity-suggestions.png" width="180" alt="Reciprocity suggestions"><br>
<sub>Reciprocity suggestions</sub>
</td>
</tr>
</table>

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
├── .vscode/                    # Repo-root run configuration (launch.json, settings.json)
├── doc/                        # Repo-wide docs — see "Documentation & handoffs" below
│   ├── context/                   dated point-in-time engineering audits (stale on specifics)
│   ├── handoffs/                  dated cross-project handoff notes
│   ├── release-notes/             one folder per shipped version, through v5.0.1+10
│   └── reports/                   one-off audits (e.g. account-deletion)
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
    │   └── features/                 auth, onboarding, home, groups, people, classification,
    │                                 events, settings (feature-first, Clean Architecture)
    ├── test/                        mirrors lib/ structure
    ├── assets/translations/          en.json, ar.json (easy_localization)
    ├── doc/handoffs/                 dated engineering handoff notes
    ├── doc/design/                    exported design prototypes (Auth Flow, Core Screens,
    │                                   Event Screens `.dc.html`) + design-conformance-fixes.md
    │                                   drift log between the prototypes and shipped code
    ├── .fvmrc                        pins Flutter 3.44.8
    └── CLAUDE.md + .claude/rules/     mobile-specific standards (authoritative for this folder)
```

## Tech stack at a glance

| Layer | Stack | Version source |
|---|---|---|
| Backend runtime | ASP.NET Core / .NET **10.0** | `*.csproj` (`TargetFramework`) |
| Backend database | PostgreSQL via Npgsql EF Core provider **10.0.3** | `YourSpace.Data.csproj` |
| Backend auth | ASP.NET Core Identity + JWT Bearer | `YourSpace.WebAPI/Extensions/IdentityServiceExtension.cs` |
| Backend file storage | Cloudflare R2 (S3-compatible), lazily-built client, separate buckets for avatars vs. person photos | `YourSpace.Services/Services/StorageService/R2StorageService.cs`, `appsettings.json` `R2` section |
| Mobile framework | Flutter **3.44.8** (pinned via FVM), Dart `^3.12.2` | `.fvmrc`, `pubspec.yaml` |
| Mobile state management | `flutter_bloc` (Cubit) **^9.1.1** | `pubspec.yaml` |
| Mobile DI | `get_it` + `injectable` | `pubspec.yaml` |
| Cross-cutting | Bilingual (English/Arabic, RTL-aware) end to end | both `CLAUDE.md` files, Architecture rule 8 (backend) |

Full dependency lists with every package and version live in each project's own README — [Backend tech stack](Your-Space-Backend/README.md#tech-stack) / [Mobile tech stack](Your-Space-Mobile/README.md#tech-stack).

## Product features

The full-stack feature set, as actually implemented (backend controllers + mobile screens/cubits — not aspirational):

- **Authentication** — register, login, JWT access + rotating refresh tokens, email confirmation via OTP, forgot/reset password, change password. Mobile handles token refresh transparently (`AuthInterceptor`); backend enforces per-IP rate limiting on all auth endpoints.
- **Onboarding** — first-run onboarding carousel before the app lands on Home.
- **Home dashboard** — at-a-glance stats screen (`HomeStatsCubit`) showing Groups/People/Events counts with an empty state and quick-nav cards into each section.
- **Groups & sub-groups** — CRUD for contact circles, plus nested sub-groups within a group (`groups/{id}/subgroups`), searchable and paginated.
- **People** — CRUD for personal contacts, each assigned to a Group, via a multi-step person wizard (basic identity → classification & location → relationships → notes). Includes server-side person search, inline "+ Add new" creation of a Group/Sub-group/Governorate/City/Neighborhood directly from the wizard's picker steps without leaving the flow, and multiple profile photos per person (`persons/{id}/images`).
- **Person relationships** — link people to one another with a typed relationship (`persons/{id}/relationships`), editable inline in the wizard.
- **Location reference data** — a Governorate → City → Neighborhood hierarchy (`governorates`, `governorates/{id}/cities`, `cities/{id}/neighborhoods`), used to tag a person's location and to slice guest lists by area.
- **Events** — CRUD for occasions being planned, with a live guest-count breakdown (not invited / invited / skipped).
- **Guest-List / Invitation Planner** — bulk-add to an Event by People, Group, Sub-group, Governorate, City, or Neighborhood; per-guest status transitions (invite / skip / revert); and a progress summary per event.
- **Reciprocity** — a per-person log of past occasions where *they* invited the user, plus a "reciprocity suggestions" endpoint/screen surfacing contacts who've invited the user before but haven't been added to the current event yet.
- **User settings & profile** — profile edit (name, avatar), and account deletion, on both sides. The backend also exposes per-user preference flags (e.g. toggling reciprocity suggestions) via `usersettings`, but the mobile Settings screen does not yet surface a toggle for it — that endpoint currently has no mobile UI.
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

The mobile app's `ApiConstants.baseUrl` (`Your-Space-Mobile/lib/core/constants/api_constants.dart`) must point at a reachable instance of the backend. The switch machinery for this is a compile-time `--dart-define=ENVIRONMENT=dev|prod` flag, but as of this writing `_devBaseUrl` and `_prodBaseUrl` are set to the identical shared dev deployment URL — there is no separate prod endpoint configured yet, so today the flag has no observable effect; update both constants (or point one at a locally-run API) as needed. There is no orchestration tool (Docker Compose, etc.) wiring the two together in this repo — each project is started independently.

## Architecture

Each project owns its own architecture, enforced independently and never blended (per the root `CLAUDE.md`):

- **Backend** — strict layered architecture (`WebAPI → Services → Repository → Data`), physically split into separate class-library projects, with `NetArchTest` assertions enforcing the layer direction and DTO purity in CI-less local test runs. See [Backend architecture](Your-Space-Backend/README.md#architecture-overview).
- **Mobile** — Clean Architecture, feature-first (`presentation → domain → data` per feature, `lib/core/` for shared infrastructure), with features never importing from other features. See [Mobile architecture](Your-Space-Mobile/README.md#architecture-overview).

The two communicate over a single contract: a versioned (`/api/v1/...`) JSON REST API with a uniform `{ success, message, errorCode, data, statusCode, timestamp, errors }` response envelope, produced by the backend's `ServiceResult<T>` and consumed by the mobile app's `unwrapServiceResult`/`ApiManager`.

## API surface

Base path: `/api/v{version}/...` (currently v1), Bearer JWT auth, EN/AR via `Accept-Language`. Endpoint groups: `auth`, `groups` (+ nested `groups/{id}/subgroups`), `persons` (+ nested `persons/{id}/images`, `persons/{id}/relationships`, `persons/{id}/occasion-history`), `events` (+ nested `events/{id}/guests`), `governorates` (+ nested `governorates/{id}/cities` and `cities/{id}/neighborhoods`), `usersettings`. Full endpoint-by-endpoint tables (methods, routes, DTOs): [Backend API overview](Your-Space-Backend/README.md#api-overview).

## Environment & secrets

Neither project commits real secrets. The backend uses `dotnet user-secrets` locally and environment variables/a secrets manager in deployed environments (`appsettings*.json` holds shape only) — this now also covers the `R2` section (Cloudflare account id, access/secret key, bucket names) used for avatar and person-photo storage, blank by default so the client builds lazily without failing auth when unset. The mobile app has no secrets to configure at build time — it only switches a compile-time `ENVIRONMENT` define between `dev`/`prod` base URLs, and acquires session tokens at runtime via login. Full key-by-key tables: [Backend env vars](Your-Space-Backend/README.md#environment-variables-reference) / [Mobile env vars](Your-Space-Mobile/README.md#environment-variables-reference).

## Testing

| Project | Framework | What's covered |
|---|---|---|
| Backend | xUnit + `NetArchTest` | Unit tests per service method, `WebApplicationFactory` integration tests per controller, architecture/layering assertions |
| Mobile | `flutter_test` + `mocktail` | 53 test files mirroring `lib/`: router, storage, widgets, and per-feature repository/cubit/screen tests |

Run each project's suite from inside its own folder — `dotnet test` (backend) / `flutter test` (mobile). File counts above are `find … -name` counts as of this writing (97 files under `Your-Space-Backend/YourSpace.WebAPI.Tests/`, 53 `*_test.dart` under `Your-Space-Mobile/test/`) and drift over time — treat them as indicative. Details: [Backend testing](Your-Space-Backend/README.md#testing) / [Mobile testing](Your-Space-Mobile/README.md#testing).

## CI/CD

> ⚠️ Not detected anywhere in this repo. No `.github/workflows/`, `azure-pipelines.yml`, `codemagic.yaml`, or similar pipeline configuration exists for either project. Builds, tests, and deploys are currently run manually. The backend ships a ready-to-use multi-stage `Dockerfile` for PaaS hosting (Coolify/Render/Railway-style), but nothing triggers it automatically.

## Documentation & handoffs

The repo-root `doc/` folder collects docs that span both projects:

- **`doc/context/`** — two point-in-time, deeply-verified engineering audits (`project-status.md`, `next-feature-status.md`), useful for historical context on *why* things are shaped the way they are, but **dated 2026-07-27/28 and already stale on specific claims** (e.g. they describe the mobile app as having no feature code yet, which is no longer true — `lib/features/` is now fully built out per [Mobile features](Your-Space-Mobile/README.md#features)).
- **`doc/handoffs/`** — dated cross-project handoff notes (`001-post-launch-feedback/`, `001-sprint-branches-merge/`), written when a body of work changed hands.
- **`doc/release-notes/`** — one numbered folder per shipped mobile version, `001_v1.0.0+4` through `007_v5.0.1+10`, each holding the Play Store release note (EN + AR) for that version.
- **`doc/reports/`** — one-off audits (currently `account-deletion-audit-2026-09-01.md`).

Each project *also* keeps its own dated handoff notes under `Your-Space-Backend/doc/handoffs/` and `Your-Space-Mobile/doc/handoffs/`, written at the time a feature landed. Treat anything time-sensitive in any `doc/` folder as a historical snapshot, not current state — the two project READMEs and the code itself are the source of truth.

## Contributing

Governed by the root `CLAUDE.md`:

- Each project's own `CLAUDE.md` (plus its `.claude/rules/`, `.claude/templates/`) is the authority for everything inside its folder — never apply the backend's architecture rules/naming/anti-patterns to the mobile app or vice versa, even where a section name matches (e.g. both have a "Testing discipline" section that means something different in each).
- A task that spans both projects (e.g. a new backend endpoint plus the mobile screen that calls it) should keep each half strictly inside its own project's conventions rather than blending them into one style.
- Commit convention observed in history: scoped conventional-commit prefixes — `feat:`, `fix:`, `chore:`, `docs:`, `test:` — optionally suffixed with a project scope (e.g. `fix(backend):`, `feat(backend):`, `test(backend):`); plain imperative messages appear occasionally otherwise.
- Adding a new project (e.g. a web frontend): give it its own top-level folder with its own `CLAUDE.md` + `.claude/rules/` + `.claude/templates/`, and add a row to the table in the root `CLAUDE.md`.

## Known limitations / TODO

- No automated CI/CD pipeline for either project.
- No `LICENSE` file anywhere in the repo — see [License](#license).
- No orchestration (Docker Compose, etc.) to run backend + database + mobile together with one command — each is started independently today.
- See each project's own README for project-specific gaps ([Backend](Your-Space-Backend/README.md#known-limitations--todo) / [Mobile](Your-Space-Mobile/README.md#known-limitations--todo)).

## License

> No license file detected — treat as unlicensed/proprietary.
