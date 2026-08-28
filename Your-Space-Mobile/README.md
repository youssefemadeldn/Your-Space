# Your Space (Mobile)

> Flutter companion app for **Your Space** — a personal relationship & event-planning tool for tracking people, groups, and invitation-worthy occasions.

![Flutter](https://img.shields.io/badge/Flutter-3.44.8-02569B)
![Dart SDK](https://img.shields.io/badge/Dart%20SDK-%5E3.12.2-0175C2)
![State management](https://img.shields.io/badge/state-flutter__bloc%20(Cubit)-purple)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-3DDC84)
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
- [State management pattern](#state-management-pattern)
- [Dependency injection](#dependency-injection)
- [Environment variables reference](#environment-variables-reference)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Contributing](#contributing)
- [Known limitations / TODO](#known-limitations--todo)
- [License](#license)

## What this is

Your Space (mobile) is the client for an app that helps a person keep track of the people in their life (contacts grouped into circles), the events they plan, who's been invited to what, and a "reciprocity" history of who has invited *them* to things — so social obligations don't get forgotten. It's a Flutter app for Android and iOS, fully bilingual (English/Arabic, including RTL layout), talking to the companion `YourSpace API` .NET backend over a JWT-authenticated REST API.

## Tech stack

**Framework**
- Flutter **3.44.8** (pinned via FVM, `.fvmrc`), Dart SDK `^3.12.2`
- Material Design throughout (no Cupertino/platform-adaptive UI)

**State management**
- `flutter_bloc` **^9.1.1** — Cubit by default, one cubit per concern (action vs. list split for features with both mutations and reads)
- `equatable` **^2.1.0** for state value-equality

**Networking**
- `dio` **^5.11.0** + `pretty_dio_logger` **^1.4.0** (debug-only request/response logging)
- `dartz` **^0.10.1** (`Either<Failure, T>` functional error handling)
- `connectivity_plus` **^7.3.1**

**Dependency injection**
- `get_it` **^9.2.1** + `injectable` **^3.0.0** (codegen via `injectable_generator` **^3.1.1** / `build_runner` **^2.15.1**)

**Routing**
- `go_router` **^17.3.0** (declarative, Navigator 2.0, typed route-args classes)

**Storage**
- `flutter_secure_storage` **^10.3.1** (tokens/session)
- `shared_preferences` **^2.5.5**

**UI / UX utilities**
- `flutter_screenutil` **^5.9.3** (390×844 design canvas, proportional scaling)
- `flutter_svg` **^2.3.0**, `cached_network_image` **^3.4.1**, `shimmer` **^3.0.0**
- `google_fonts` **^8.2.0**
- `easy_localization` **^3.0.8** (English/Arabic, RTL-aware) + `intl` **^0.20.2**
- `url_launcher` **^6.3.2**

**App identity**
- `flutter_launcher_icons` **^0.14.4** (adaptive Android icon + iOS icon generation)
- Application ID / bundle identifier: `com.yourspace.app` (Android `build.gradle.kts`, iOS `project.pbxproj`)

**Testing**
- `flutter_test` (SDK), `mocktail` **^1.0.5** for mocking
- `bloc_test` is deliberately **not** used — its `test`/`test_api` version pin conflicts with `injectable_generator ^3.1.1` on this project's Dart SDK; cubit tests instead assert state sequences via `expectLater(cubit.stream, emitsInOrder([...]))`

**DevOps**
- FVM (`.fvmrc`) pins the Flutter SDK version for reproducible builds across machines
- No CI/CD pipeline is configured in this repository — see [CI/CD](#cicd)

## Architecture overview

**Clean Architecture, feature-first.** All infrastructure lives in `lib/core/`; all product code lives in `lib/features/<feature_name>/`, each split into `data/` → `domain/` → `presentation/`. Dependency direction is one-way and never crosses features directly:

```
Presentation → Domain → Data
Feature      → Core
```

Features never import from other features — cross-feature navigation goes through typed args classes in `lib/core/router/args/`, kept in core specifically so no feature has to import another feature's presentation layer. Within a feature: data sources return `Either<Failure, T>` (no `try/catch` outside the one error boundary, `ApiManager`), repository implementations map data-layer response models to pure domain entities via `.toEntity()`, and cubits talk only to repositories (or use cases, added only when logic is shared across 2+ cubits or is non-trivial).

```
Your-Space-Mobile/
├── lib/
│   ├── core/                    # Shared infrastructure — imported by every feature
│   │   ├── constants/             # AppConstants, ApiConstants (env-aware base URL)
│   │   ├── di/                     # injection_container.dart (getIt), register_module.dart
│   │   ├── entities/                # Cross-feature shared entities (Group, Person, PaginatedResult, InviteMethod)
│   │   ├── helpers/                  # DialogHelper, SnackBarHelper, BottomSheetHelper, DateFormatterHelper
│   │   ├── network/                   # ApiManager, Failure hierarchy, AuthInterceptor, DioFactory, api_envelope
│   │   ├── router/                     # AppRouter (GoRouter), AppRoutes, args/ (typed navigation args)
│   │   ├── storage/                     # SecureStorageHelper (tokens/session)
│   │   ├── theme/                        # AppColors, AppTextStyles, AppTheme
│   │   └── widgets/                       # Shared design-system widgets (AppButton, AppInput, AppCard, ...)
│   ├── features/
│   │   ├── auth/                  # Register, login, confirm email (OTP), forgot/reset/change password
│   │   ├── home/                  # Dashboard / stats landing screen
│   │   ├── groups/                # Contact-circle CRUD
│   │   ├── people/                # Contact CRUD + reciprocity occasion history
│   │   └── events/                # Event CRUD, guest-list/invitation planner, reciprocity suggestions
│   └── dev/                      # widget_gallery_main.dart — manual QA entry point for lib/core/widgets/
├── test/                        # Mirrors lib/ structure — core/ and features/<feature>/{data,presentation}
├── assets/
│   └── translations/             # en.json, ar.json (easy_localization)
├── doc/
│   ├── design/                    # Exported design system (tokens, HTML mockups per flow)
│   └── handoffs/                  # Dated engineering handoff notes per feature milestone
├── android/ / ios/               # Platform projects (applicationId / bundle id: com.yourspace.app)
└── .fvmrc                        # Pins Flutter 3.44.8
```

## Features

Derived from the actual feature folders and screens under `lib/features/`:

- **Authentication** (`features/auth`) — register, login, email confirmation via OTP, forgot/reset password, change password; session/token refresh handled transparently by `AuthInterceptor`
- **Home dashboard** (`features/home`) — at-a-glance stats screen (`HomeStatsCubit`)
- **Groups** (`features/groups`) — create/update contact circles, searchable paginated list (`GroupsListCubit` + `GroupActionCubit` action/list split)
- **People** (`features/people`) — contact CRUD, person details, and reciprocity occasion history (`AddOccasionCubit`) — logging past occasions where a contact invited the user
- **Events** (`features/events`) — event CRUD (`EventFormCubit`, `EventsListCubit`), event details with live guest-count breakdown, and the **Guest-List / Invitation Planner**: bulk-add people or a whole group to an event (`AddGuestsListCubit`/`AddGuestsActionCubit`), per-guest status transitions (`EventGuestActionCubit`), and reciprocity suggestions (`ReciprocitySuggestionsCubit`) — people who've invited the user before but haven't been added to this event yet
- **Bilingual UI (EN/AR) with RTL support** — `easy_localization` with `assets/translations/{en,ar}.json`; every directional style uses direction-aware primitives (`EdgeInsetsDirectional`, `AlignmentDirectional`)
- **Custom design-system widget library** (`lib/core/widgets/`) — `AppButton`, `AppInput`, `AppPasswordInput`, `AppOtpInput`, `AppCard`, `AppChip`, `AppSelect`, `AppSwitch`, `AppTabs`, `AppAvatar`, `AppBadge`, `AppBottomNav`, `AppAppBar`, `AppListTile`, `AppProfileRow`, `InviteMethodChipGroup` — previewable via the standalone `lib/dev/widget_gallery_main.dart` entry point

## Getting started

### Prerequisites

- **Flutter 3.44.8** — this exact version is pinned via [FVM](https://fvm.app/) (`.fvmrc`); running `fvm install` then `fvm flutter ...` (or `fvm use` to activate it for plain `flutter` commands) keeps you on the same SDK as the rest of the team
- **Dart SDK** `^3.12.2` (bundled with the pinned Flutter version)
- Android Studio / Xcode for platform toolchains (Android SDK, CocoaPods for iOS)
- A running instance of the [YourSpace API backend](../Your-Space-Backend/README.md) (or access to the shared dev deployment already configured in `ApiConstants`)

### Environment setup

No `.env` files and no third-party env package — environment switching is compile-time via `--dart-define`:

```bash
# Dev (default)
flutter run

# Prod
flutter run --dart-define=ENVIRONMENT=prod
```

`ApiConstants.baseUrl` (`lib/core/constants/api_constants.dart`) resolves the base URL at compile time from the `ENVIRONMENT` define. In **VS Code**, add `--dart-define=ENVIRONMENT=prod` to `args` in `launch.json` to switch without touching code.

No secrets are stored client-side beyond the session tokens `AuthInterceptor`/`SecureStorageHelper` manage at runtime (`flutter_secure_storage`) — there is no build-time API key or credential to configure.

### Installation

```bash
flutter pub get

# Generate the DI container (required after any @injectable/@lazySingleton change,
# and on first clone since injection_container.config.dart is generated)
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
# Default (dev environment), auto-selects a connected device/emulator
flutter run

# Explicit device
flutter run -d <device_id>

# Prod environment
flutter run --dart-define=ENVIRONMENT=prod

# Widget gallery (manual QA for lib/core/widgets/)
flutter run -t lib/dev/widget_gallery_main.dart
```

List available emulators/devices with `flutter emulators` / `flutter devices`. During active development on DI-annotated classes, keep codegen live:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Build

```bash
# Android APK (prod)
flutter build apk --dart-define=ENVIRONMENT=prod

# Android App Bundle (prod, for Play Store)
flutter build appbundle --dart-define=ENVIRONMENT=prod

# iOS (prod)
flutter build ios --dart-define=ENVIRONMENT=prod
```

## Project structure

See [Architecture overview](#architecture-overview) above for the full annotated tree.

## API overview

- **Base URL:** configured per-environment in `ApiConstants.baseUrl` (`lib/core/constants/api_constants.dart`), currently pointing at a shared dev/prod deployment of the YourSpace API
- **Auth:** Bearer JWT, attached automatically by `AuthInterceptor` (`lib/core/network/interceptors/auth_interceptor.dart`) — data sources never touch a token directly. On a 401 (except from the refresh call itself), the interceptor silently refreshes via a dedicated interceptor-free "bare" `Dio`, sharing one in-flight refresh across concurrent 401s, retries the original request once, and only falls back to `SecureStorageHelper.clearSession()` + redirect to `/login` if refresh itself fails
- **Response envelope:** the backend wraps responses as `{ "success": true, "data": {...} }`; `unwrapServiceResult` (`lib/core/network/api_envelope.dart`) extracts `data` before a model's `fromJson` ever sees it. Void endpoints (logout, delete) bypass it with `fromJson: (_) => unit`
- **Error mapping:** every `DioException` is converted to a typed `Failure` (`NetworkFailure`, `UnauthorizedFailure`, `ValidationFailure`, `ServerFailure`, `UnexpectedFailure`) by `ApiManager` — features never see a raw exception. A backend `errorCode` (when present) is captured onto `Failure.errorCode` for **behavior** branching (navigation, forced logout); display text always comes from `failureToMessage()`
- **Consumed endpoint groups** (matching the backend's `/api/v1/...` surface): `auth`, `groups`, `persons`, `events` (+ nested `events/{id}/guests`), `persons/{id}/occasion-history`

## State management pattern

Cubit-first (`flutter_bloc`). Every state file is a `sealed class` base with `final class` variants extending `Equatable`, giving exhaustive `switch` handling in `BlocBuilder`:

```dart
sealed class GroupsListState extends Equatable { ... }
final class GroupsListInitial extends GroupsListState { ... }
final class GroupsListLoading extends GroupsListState { ... }
final class GroupsListSuccess extends GroupsListState { ... }
final class GroupsListError extends GroupsListState { ... }
```

See `lib/features/groups/presentation/cubit/groups_list_cubit/` for a complete, representative example, including debounced search and paginated `loadMore()`.

Features with both mutations and reads use **separate cubits** to prevent state collisions — e.g. Groups splits into `GroupsListCubit` (`BlocBuilder`) and `GroupActionCubit` (`BlocConsumer`, whose success listener triggers `GroupsListCubit.load()`/`refresh()`). `BlocProvider`/`MultiBlocProvider` is always created in the `GoRoute` builder inside `AppRouter` (`lib/core/router/app_router.dart`) — never inside a screen widget.

## Dependency injection

`get_it` + `injectable`, initialized once in `lib/core/di/injection_container.dart` via `@InjectableInit()` and `configureDependencies()`, called from `main()` before `runApp`. Cross-cutting infrastructure that needs manual construction (not annotation-scannable) is provided by the `@module` class in `lib/core/di/register_module.dart` — `FlutterSecureStorage`, the navigator `GlobalKey`, `GoRouter`, `Dio` (via `DioFactory`), and `SharedPreferences` (`@preResolve`).

To register a new class: annotate it (`@injectable` for cubits/use cases, `@lazySingleton` for data sources, `@LazySingleton(as: Repo)` for repository implementations bound to their abstract contract), then regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Verify the new registration appears in the generated `lib/core/di/injection_container.config.dart`.

| Class type | Scope |
|---|---|
| Remote data source | `@lazySingleton` |
| Repository impl | `@LazySingleton(as: <Feature>Repository)` |
| Use case | `@injectable` (added only when shared by 2+ cubits or non-trivial logic) |
| Cubit | `@injectable` (factory — fresh instance per route) |
| `DialogHelper`, `SnackBarHelper` | `@lazySingleton` |

## Environment variables reference

This app has no `.env` file — configuration is compile-time `--dart-define` flags plus constants checked into source (see [Environment setup](#environment-setup)).

| Key | Purpose | Required? |
|---|---|---|
| `ENVIRONMENT` (`--dart-define`) | Selects `dev` vs `prod` base URL in `ApiConstants.baseUrl` | No (defaults to `dev`) |

No API keys, tokens, or credentials are configured at build time — session tokens are acquired at runtime through the login flow and stored via `flutter_secure_storage`.

## Testing

Tests mirror the `lib/` structure under `test/`: `core/` (router, storage, widgets) and `features/<feature>/` (`data/repositories/`, `presentation/cubit/`, `presentation/pages/`) — 48 test files across `auth`, `events`, `groups`, `home`, and `people`.

```bash
flutter test

# Single file
flutter test test/features/groups/presentation/cubit/groups_list_cubit_test.dart
```

Cubit tests use `mocktail` for mocking repositories and assert state sequences with `expectLater(cubit.stream, emitsInOrder([...]))` rather than `bloc_test` (see [Tech stack](#tech-stack) for why).

## CI/CD

> ⚠️ Not detected in this repo. No `.github/workflows/`, `codemagic.yaml`, `bitrise.yml`, or similar pipeline configuration exists. Builds and releases are currently run manually via the `flutter build`/`fvm flutter build` commands above.

## Contributing

Not formally documented in this repo. Based on observed project conventions:

- Follow the layered `data/domain/presentation` structure and the five non-negotiable rules in `CLAUDE.md` (auth invisible to data layer, no try/catch outside `ApiManager`, domain never sees response models, use cases only when warranted, action/query cubit split) for any new feature work.
- Engineering context per milestone is captured as dated handoff notes under `doc/handoffs/<NNN-feature-name>/`.
- Suggested default (not enforced): branch per feature, run `flutter analyze` and `flutter test` before opening a PR, review against the pre-ship checklist in `.claude/rules/flutter_feature_prompt.md`.

## Known limitations / TODO

- No automated CI/CD pipeline (see [CI/CD](#cicd)).
- No `LICENSE` file — see [License](#license).
- `lib/dev/widget_gallery_main.dart` is an intentionally temporary manual-QA entry point — its own header comment notes it should be deleted once the shared widget library has been visually verified.
- No explicit `TODO`/`FIXME`/`UnimplementedError` markers were found in `lib/` — outstanding work is instead tracked narratively in `doc/handoffs/` and `doc/design/uploads/next-feature-status.md`.

## License

> No license file detected — treat as unlicensed/proprietary.
