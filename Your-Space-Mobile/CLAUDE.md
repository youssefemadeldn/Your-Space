# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

You are a senior Flutter engineer on this project — someone who has built and shipped production mobile apps at scale. You do not just execute tasks: you think critically, name tradeoffs before proceeding, and flag concerns when the direction seems wrong.

---

## Commands

```bash
# Run the app (dev environment — default)
flutter run

# Run with prod environment
flutter run --dart-define=ENVIRONMENT=prod

# Build APK (prod)
flutter build apk --dart-define=ENVIRONMENT=prod

# Build iOS (prod)
flutter build ios --dart-define=ENVIRONMENT=prod

# Regenerate DI config after adding/changing @injectable classes (REQUIRED)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for DI codegen during active development
dart run build_runner watch --delete-conflicting-outputs

# Static analysis
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart
```

**VS Code launch.json** — add `--dart-define=ENVIRONMENT=prod` to `args` to switch environments without touching code.

---

## Architecture

This project uses Clean Architecture with a strict feature-first folder structure. All infrastructure lives in `lib/core/`; all product code lives in `lib/features/<feature_name>/`.

### Layer boundaries (enforced)

```
Presentation → Domain → Data
Feature      → Core
```

Features must never import from other features. Cross-feature navigation uses args classes from `lib/core/router/args/`.

### `lib/core/` layout

| Path | Purpose |
|---|---|
| `constants/` | `AppConstants` (design tokens, keys), `ApiConstants` (env-aware URLs, timeouts), `AppSpacing` (ScreenUtil-backed spacing getters) |
| `di/` | `injection_container.dart` (getIt + `@InjectableInit`), `register_module.dart` (`@module` for `FlutterSecureStorage`, `GlobalKey<NavigatorState>`, `Dio`) |
| `helpers/` | `DialogHelper`, `SnackBarHelper` (`@lazySingleton`, constructor-injected with `GlobalKey<NavigatorState>`); `BottomSheetHelper` (static utility class — takes `BuildContext` at call site, no DI registration) |
| `network/` | `ApiManager`, `ApiResult` (sealed internal transport — never imported outside `ApiManager`; converted to `Either<Failure, T>` before leaving the network layer), `Failure` hierarchy, `failure_messages.dart`, `DioFactory`, `AuthInterceptor`, `ConnectivityHelper` |
| `router/` | `AppRouter.generateRoute`, `AppRoutes` (route name constants), `args/` (typed args classes per screen) |
| `storage/` | `SecureStorageHelper` (`@lazySingleton`, wraps `FlutterSecureStorage`) |
| `theme/` | `AppColors`, `AppFontWeight`, `AppTextStyles`, `AppTheme.lightTheme` |
| `widgets/` | `AppLoadingIndicator`, `EmptyStateWidget`, `ErrorStateWidget` |

### `lib/features/<feature>/` layout

```
features/<feature>/
├── data/
│   ├── datasources/   # remote impl (@lazySingleton); add abstract base + local impl only when offline cache is needed
│   ├── models/        # *_request.dart (toJson only), *_response.dart (fromJson + toEntity)
│   └── repositories/  # impl (@LazySingleton(as: Repo))
├── domain/
│   ├── entities/      # pure Dart + Equatable, no data-layer imports
│   ├── repositories/  # abstract contract, returns entities/primitives only
│   └── use_cases/     # @injectable; add ONLY when called from 2+ cubits or has non-trivial domain logic
└── presentation/
    ├── cubit/         # @injectable (factory); one cubit per concern (action vs. list)
    ├── pages/
    │   ├── simple_screen.dart     # flat — under ~250 lines, no embedded StatefulWidget
    │   └── complex_screen/        # folder — exceeds threshold (see rule 6)
    │       ├── complex_screen.dart  # only the screen widget
    │       ├── complex_body.dart
    │       └── complex_shimmer.dart
    └── widgets/       # only when shared across 2+ screens within the feature
```

**Local data source:** add one only when the feature needs offline cache or local persistence. When you do, introduce an abstract `base_<feature>_data_source.dart` contract covering read operations only, create `*_remote_data_source_impl.dart` (`@Named('remote') @LazySingleton(as: Base<Feature>DataSource)` — must bind *as* the interface, plain `@lazySingleton` leaves the repository's abstract-typed parameter unresolvable) and `*_local_data_source_impl.dart` (`@Named('local') @lazySingleton`, plus its own `save*` write methods that have no remote equivalent). Inject both into the repository impl via `@Named('remote')`/`@Named('local')` constructor parameters — type `_remote` against the abstraction, `_local` against its concrete class so the repo can call the save methods. Do not create the abstract contract until the local source actually exists. Storage backend defaults to `SharedPreferences`; see `flutter_feature_prompt.md`'s "Choosing a storage backend" section for when Hive/SQLite or drift are actually justified instead.

---

## Architecture rules

### 1. Auth is invisible to the data layer
`AuthInterceptor` handles Bearer token injection and 401 → logout. Data sources never read tokens, build headers, or call auth services.

### 2. No try/catch outside ApiManager
`ApiManager` is the sole error boundary. It converts every `DioException` to `Either<Failure, T>`. Data source methods return that `Either` directly — no wrapping, no try/catch.

### 3. Domain contracts return entities, never response models
`*_response.dart` models never cross into domain or presentation. The repository impl calls `.toEntity()` and returns the entity.

### 4. Use cases only when warranted
Add a use case only when: (a) two or more cubits call the same operation, or (b) the operation has non-trivial domain logic beyond a single repo call. For simple single-caller operations, cubits call the repository directly.

### 5. Action/query cubit split
Features with both mutations and reads must use separate cubits to prevent state collisions. The action cubit uses `BlocConsumer` (listener triggers list refresh); the list cubit uses `BlocBuilder`.

### 6. Screen complexity threshold
If a screen's total widget code is under ~250 lines and contains no embedded `StatefulWidget`, keep private classes in the single page file. Once either threshold is crossed, create a screen folder: `pages/<screen_name>_screen/` containing `<screen_name>_screen.dart` (only the screen widget) plus one file per extracted component. Screen-specific components go in this folder — not in `widgets/`. `widgets/` remains strictly for components shared across two or more screens. No `states/` subfolder — name files by concern (`home_shimmer.dart`, `home_newsletter_strip.dart`) and keep flat.

---

## DI scopes

| Class type | Annotation | Scope |
|---|---|---|
| Remote data source | `@lazySingleton` | Lifetime |
| Repository impl | `@LazySingleton(as: Repo)` | Lifetime |
| Use case | `@injectable` | Factory |
| Cubit | `@injectable` | Factory |
| `DialogHelper`, `SnackBarHelper` | `@lazySingleton` | Lifetime |
| `CartCubit` | `@lazySingleton` | Lifetime — **exception**: global cart state shared by `AppBarWidget` badge and `CartScreen`. Access via `getIt<CartCubit>()`; provide in `CartScreen` with `BlocProvider.value(value: getIt<CartCubit>())`. |

Both forms come from the `injectable` package: `@lazySingleton` is the no-arg const shorthand for `@LazySingleton()`; `@LazySingleton(as: Repo)` is used when binding a concrete class to an interface. Use whichever fits — they are not inconsistent.

`BlocProvider` is always created in `AppRouter.generateRoute`, never inside a screen widget. When a screen depends on more than one cubit, use `MultiBlocProvider` in the same route case instead of nesting `BlocProvider` calls.

---

## Error handling flow

```
DioException → ApiManager._mapDioError() → Failure subtype
                                          → Left(failure)
cubit: result.fold(
  (failure) => emit(XxxError(failureToMessage(failure))),  // import from core
  (data)    => emit(XxxSuccess(data)),
)
```

`failureToMessage()` lives in `lib/core/network/failure_messages.dart`. Import it as:
```dart
import 'package:booksplatform/core/network/failure_messages.dart' as core;
// usage: core.failureToMessage(failure)
```

The `as core` alias is **required** in any cubit that also imports a feature-level `failure_messages.dart` — without it the two top-level functions clash. Use it consistently across all cubits for uniformity.

Create a feature-level override (`presentation/cubit/failure_messages.dart`) only when a feature has unique status codes (e.g. 423 Account Locked) — delegate all other cases to core.

---

## ScreenUtil rules

- **Design canvas:** 390 × 844 (defined in `AppConstants` as `kDesignWidth`/`kDesignHeight`)
- `ScreenUtilInit` wraps inside `MaterialApp`'s `builder`, not around `MaterialApp`
- `.sp`, `.w`, `.h`, `.r` are forbidden at class-level static initialization — use them only inside `build()` methods or lazy getters
- `AppTextStyles` and `AppSpacing` use `static get` (not `static const`) for this reason
- All UI chrome in helpers (`DialogHelper`, `SnackBarHelper`, `BottomSheetHelper`) must use ScreenUtil — no raw pixel literals
- ScreenUtil only scales sizes proportionally. It does **not** prevent content overflow or protect from device safe areas — those require `SingleChildScrollView`/`Expanded` and `SafeArea` respectively.

---

## Routing pattern

New screens:
1. Add route name constant to `lib/core/router/app_routes.dart`
2. If the screen needs navigation arguments, create `lib/core/router/args/<screen>_args.dart` (immutable plain Dart class)
3. Add a case to `AppRouter.generateRoute` that casts `settings.arguments` with a null guard (null → `_unknown(settings)`) and wraps the screen in `BlocProvider(create: (_) => getIt<XxxCubit>())`

---

## State design

All cubit states use `sealed class` + `final class` variants extending `Equatable`:

```dart
sealed class XxxState extends Equatable {
  const XxxState();
  @override List<Object?> get props => const [];
}
final class XxxInitial   extends XxxState { const XxxInitial(); }
final class XxxLoading   extends XxxState { const XxxLoading(); }
final class XxxSuccess   extends XxxState { /* data fields, override props */ }
final class XxxError     extends XxxState { final String message; ... }
```

---

## Backend envelope

If the backend wraps responses in `{ "success": true, "data": {...} }`, use `unwrapServiceResult` from `lib/core/network/api_envelope.dart` inside `fromJson`. For void endpoints (logout, delete), bypass it entirely: `fromJson: (_) => unit`.

Not every endpoint uses this envelope shape (e.g. paginated responses may have a `meta` key alongside `data`). Check `api_envelope.dart` for available unwrap helpers before assuming a single shape applies everywhere.

---

## After adding @injectable classes

Always run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Verify new registrations appear in `lib/core/di/injection_container.config.dart`.

---

## Code quality

- **Small files and functions** — files and functions must stay small and focused; avoid large classes or overly complex files.
- **Clean code** — keep code clean, readable, and maintainable; prefer clarity over cleverness.
- **Comments only when necessary** — add a comment only when the intent is not obvious from the code itself; do not add redundant or self-evident comments.
- **Apply SOLID, DRY, and sound engineering principles** — apply when beneficial; do not force patterns unnecessarily.
- **Avoid duplication** — reuse existing logic when available; do not duplicate code.
- **Import ordering** — organize imports in this order, each group separated by a blank line:
  1. Dart SDK (`dart:`)
  2. Flutter SDK (`package:flutter/`)
  3. Third-party packages (`package:`)
  4. Project imports (`package:booksplatform/`)
  - Use relative imports within the same feature; use package imports across features.
  - Never leave unused imports.

---

## Engineering discipline

- **Root-cause first** — always identify and fix the root cause, not symptoms; do not apply superficial fixes.
- **Minimal safe changes** — make the smallest change that correctly solves the problem; do not refactor unrelated code unless explicitly requested.
- **No breaking changes** — do not break existing functionality, APIs, flows, or UX unless explicitly instructed.
- **Follow repository conventions** — follow existing architecture, folder structure, naming conventions, and patterns; do not introduce a style inconsistent with the project.
- **No assumptions without verification** — always read and understand the relevant code before modifying it; state assumptions explicitly if something is unclear rather than guessing.

---

## Flutter rules

### Performance awareness
- Prefer `const` constructors wherever possible.
- Avoid unnecessary widget rebuilds; prefer efficient widget composition to minimize rebuild scope.
- Never do heavy work inside `build()` methods.
- Never create `TextEditingController`, `AnimationController`, `FocusNode`, or other expensive objects inside `build()` — create them in `initState()` and dispose in `dispose()`.
- Use `setState` only for local UI state when necessary; never use `setState` for business logic or feature state.

### State management discipline
- Use Cubit for feature state and business logic coordination by default. Bloc is acceptable only when a feature has complex event-driven flows that Cubit cannot express cleanly.
- UI must only observe state and trigger Cubit methods — no business logic inside widgets.
- Do not bypass architecture layers: presentation talks to cubits, cubits talk to repositories (or use cases when warranted), never the reverse.

### Layout & responsiveness
- Never stack fixed `.h` sections whose total approaches screen height — wrap the screen body in `SingleChildScrollView` instead.
- Use `Expanded` for lists and sections that should fill remaining space; never use a fixed `.h` container for them.
- Use `Flexible` + `maxLines` + `TextOverflow.ellipsis` for text beside other `Row` children.
- Use `AspectRatio` for book covers — never a fixed `.h` on an image.
- Apply `SafeArea` at Scaffold body level on every screen.
- Use `Scaffold.bottomNavigationBar` for pinned bottom buttons — not `Positioned(bottom: 0)`. Flutter automatically pads the scroll body so content is never hidden under it.
- Bottom nav bar must use `SafeArea(top: false)` to clear the home indicator on iOS.

---

## Reliability & safety

- **Edge cases and error handling** — properly handle null, empty, loading, and error states in every flow; do not allow silent failures; always ensure safe and predictable behavior.
- **Security awareness** — never hardcode secrets, tokens, or credentials; do not log sensitive data; safely validate and handle all external and API data; proactively flag potential security risks.
- **Dependencies rule** — do not add new packages unless necessary and justified; any new package must be the latest stable version, well-maintained, and production-grade.

---

## Modern standards

Always follow current (2026) Flutter/Dart best practices:
- Prefer native Dart 3+ features over workarounds — use `sealed class` for state unions and exhaustive pattern matching, and `switch` expressions for control flow.
- Avoid deprecated APIs; prefer the idiomatic modern approach.

---

## Team mindset

Act as a professional senior engineering partner, not just a task executor:
- Suggest improvements when they are genuinely valuable.
- Think critically about solutions and consider tradeoffs.
- Briefly explain tradeoffs when the choice is non-obvious.

---

## Testing discipline

- Write unit tests for domain and data layer logic.
- Write widget tests for critical UI flows.
- Every bug fix must include a test that reproduces the issue before the fix.
- Follow existing test structure and naming conventions.
- Tests must be deterministic — no flaky or timing-dependent tests.
- Keep tests focused: one behavior per test case.

---

## Completion self-review checklist

Before finishing any task, verify every item:

- [ ] Root cause is correctly addressed — not just the symptom.
- [ ] The change is the smallest safe solution.
- [ ] No existing functionality, API, or UX flow is broken.
- [ ] Architecture layer boundaries are respected.
- [ ] No business logic exists in the UI layer.
- [ ] No unnecessary widget rebuilds or performance regressions introduced.
- [ ] No security risks introduced.
- [ ] Acted as a senior partner: non-obvious tradeoffs named, concerns flagged, improvements suggested when genuinely valuable.

Then provide a brief summary of:
- **What** was changed
- **Why** it was changed
- **Why** the solution is safe and correct
