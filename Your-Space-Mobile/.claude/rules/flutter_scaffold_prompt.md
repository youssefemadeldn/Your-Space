> Scaffold the complete foundational architecture layer for a new empty Flutter
  project before any feature code is written — covering helpers, constants,
  theming, routing, networking, and dependency injection.

**Current state:** The project is a clean Flutter init — only pubspec.yaml exists
with the packages listed below already added. No lib/ structure has been created yet.
The goal is to establish a professional, scalable foundation that makes every future
feature consistent, easy to maintain, and hard to break. Do not generate any feature
screens or business logic — only the infrastructure layer.

---

**Package context (ignore versions — use latest compatible):**
- HTTP & networking: dio, pretty_dio_logger
- State management: flutter_bloc (Cubits only, no classic BLoC)
- DI: get_it + injectable + injectable_generator (build_runner)
- Functional programming: dartz (Either for error handling)
- Storage: flutter_secure_storage
- Routing: manual (app_router.dart — no go_router or auto_route)
- UI utilities: flutter_screenutil, flutter_svg, cached_network_image, shimmer
- Connectivity: connectivity_plus
- Equality: equatable
- Localization & formatting: intl, easy_localization
- Other: url_launcher, cupertino_icons, flutter_launcher_icons

---

**Platform & UI Strategy:**

This app targets both iOS (App Store) and Android (Play Store).
The UI strategy is **Material Design everywhere** — no platform-adaptive components,
no Cupertino widgets, no Platform.isIOS checks anywhere in the foundation layer.
All helpers (DialogHelper, SnackBarHelper, BottomSheetHelper) must use Material
widgets only. Icons use Material Icons as default; cupertino_icons is in pubspec
but not actively used in the foundation layer.

---

**Design & Theme Constraints:**

> Color values and design tokens are placeholders — I will replace them later.
> The structure and wiring must be correct from day one.

- Design canvas (ScreenUtil): **390 × 844** (iPhone 14 base, portrait only)
- Design size constants live in `lib/core/constants/app_constants.dart` as
  `kDesignWidth = 390.0` and `kDesignHeight = 844.0` — ScreenUtil reads from
  these, nowhere else.
- Color palette intent (use these hex defaults as placeholders):
  - `primary`: #2563EB
  - `primaryDark`: #1D4ED8
  - `secondary`: #7C3AED
  - `error`: #DC2626
  - `success`: #16A34A
  - `warning`: #D97706
  - `background`: #F9FAFB
  - `surface`: #FFFFFF
  - `textPrimary`: #111827
  - `textSecondary`: #6B7280
  - `textHint`: #9CA3AF
  - `divider`: #E5E7EB
  - `shimmerBase`: #E5E7EB
  - `shimmerHighlight`: #F3F4F6
  - `cardBackground`: #FFFFFF
  - `inputFill`: #F3F4F6

---

**Environment Strategy:**

The backend does not exist yet — placeholder URLs will be used.
The structure must be production-ready so switching to real URLs later
requires changing only the constants, not the architecture.

Use compile-time environment variables via `--dart-define=ENVIRONMENT=dev`.
`ApiConstants` must expose a single `baseUrl` getter that resolves at compile
time using `const String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev')`.

Define two placeholder URLs:
- dev:  `https://api-dev.placeholder.com/v1`
- prod: `https://api.placeholder.com/v1`

No third-party env package. No .env files. Just `--dart-define` + `const String.fromEnvironment`.
The plan must show how to pass this flag in both VS Code (launch.json) and
Android Studio (run configurations) so the setup is documented, not just the code.

---

**Dependency Injection Scopes:**

Every registered service in the plan must explicitly state its scope:
- `@singleton` → instantiated immediately at app start, lives for app lifetime.
  Use for: GlobalKey<NavigatorState>, Dio, SharedPreferences
- `@lazySingleton` → instantiated on first use, lives for app lifetime.
  Use for: FlutterSecureStorage, ApiManager, SecureStorageHelper, ConnectivityHelper,
           remote data sources, repository impls
- `@injectable` → new instance per injection request.
  Use for: Cubits, use cases

No service may have an unspecified scope in the plan.

---

**ApiResult vs Either — Strict Separation:**

These are two distinct layers with no overlap:

- `api_result.dart` → **internal transport sealed class** used only inside
  `ApiManager`. Represents the raw HTTP outcome before mapping.
  Never imported by any feature, Cubit, or Repository.

- `Either<Failure, T>` from dartz → **public contract** exposed by ApiManager
  to every feature layer caller. Left = Failure subtype, Right = success data T.

The plan must explicitly show the conversion chain:
  `DioResponse → ApiResult → Either<Failure, T>`
so the boundary is never blurred. ApiManager is the only class that touches
both sides of this boundary.

---

**Phase 1 — Exploration (no code yet)**

1. Confirm the Flutter SDK version and the current lib/ structure — verify it
   contains only main.dart before proceeding.
2. Confirm how get_it + injectable wires together: correct `@InjectableInit`
   annotation location, injection container file path, and how build_runner
   generates the `.config.dart` file. Identify any known issues with the
   current versions.
3. Confirm the flutter_screenutil initialization strategy:
   - ScreenUtilInit must wrap the widget tree inside MaterialApp's builder,
     NOT wrap MaterialApp itself.
   - `.sp`, `.w`, `.h` extensions must NEVER appear at class-level static
     initialization — only inside `build()` methods or lazy getters.
   - Call this constraint out explicitly in the plan for AppTextStyles
     and AppSpacing.

---

**Phase 2 — Plan**

Produce a complete file-by-file plan. For each file specify:
full path, responsibility, what it exports, dependencies on other
foundation files, and DI scope (if registered).

**Constants:**

- `lib/core/constants/app_constants.dart`
  Exports: kDesignWidth (390.0), kDesignHeight (844.0), kAppName,
  kAnimationDuration, kSplashDuration, kDefaultPageSize, kTokenKey,
  kUserKey.

- `lib/core/constants/api_constants.dart`
  Exports: ApiConstants class with static `baseUrl` getter (env-aware via
  String.fromEnvironment), connectTimeout, receiveTimeout, sendTimeout
  (all as Duration). Endpoint path constants as static String fields.

- `lib/core/constants/spacing_constants.dart`
  Exports: AppSpacing class with two scales of static getters:
  - Horizontal (`.w`): s4, s8, s12, s16, s20, s24, s32, s48, s64
  - Vertical (`.h`):   v4, v8, v12, v16, v20, v24, v32, v48, v64
  Both scales must be lazy getters, not static const (ScreenUtil must be
  initialized first). The `s*` prefix is for horizontal spacing; `v*` is
  for vertical. No mixed-axis getter exists — pick the axis at the call site.

**Theme & Styling:**

- `lib/core/theme/app_colors.dart`
  Exports: AppColors class with all static const Color fields per the
  palette above. No logic — pure constants.

- `lib/core/theme/app_font_weight.dart`
  Exports: AppFontWeight with static const: regular (w400), medium (w500),
  semiBold (w600), bold (w700), extraBold (w800).

- `lib/core/theme/app_text_styles.dart`
  Exports: AppTextStyles class with static getters (NOT const — uses .sp):
  displayLarge, displayMedium, headlineLarge, headlineMedium, headlineSmall,
  titleLarge, titleMedium, bodyLarge, bodyMedium, bodySmall, labelLarge, labelSmall.
  Each references AppColors and AppFontWeight.

- `lib/core/theme/app_theme.dart`
  Exports: AppTheme.lightTheme (ThemeData). Wires: colorScheme, textTheme,
  appBarTheme (no elevation, centered title), inputDecorationTheme (filled,
  rounded, uses inputFill color), elevatedButtonTheme (full-width, rounded),
  outlinedButtonTheme, textButtonTheme, dividerTheme, scaffoldBackgroundColor,
  cardTheme, bottomSheetTheme, snackBarTheme.
  `textButtonTheme` sets foregroundColor=primary and matching shape.
  `bottomSheetTheme` sets surface background, transparent surfaceTint, top-rounded shape.
  `snackBarTheme` sets floating behavior and rounded shape as baseline —
  SnackBarHelper still sets per-call backgroundColor and margin.

**Helpers / Utilities:**

- `lib/core/helpers/dialog_helper.dart`
  Registered as `@lazySingleton`. Receives `GlobalKey<NavigatorState>` via
  constructor injection. Instance methods (NOT static): showAppDialog,
  showConfirmDialog (with onConfirm/onCancel callbacks), showLoadingDialog,
  hideDialog. Call sites invoke via `getIt<DialogHelper>().showAppDialog(...)`.
  All chrome (text styles, paddings) uses `AppTextStyles` / ScreenUtil.
  `showLoadingDialog` wraps `CircularProgressIndicator` in a `Card` + `Padding`
  using ScreenUtil (`EdgeInsets.all(24.r)`) — never a bare indicator with no container.
  Material widgets only.

- `lib/core/helpers/snack_bar_helper.dart`
  Registered as `@lazySingleton`. Receives `GlobalKey<NavigatorState>` via
  constructor injection. Instance methods (NOT static): showSuccess, showError,
  showInfo, showWarning. Each shows a styled SnackBar via
  `ScaffoldMessenger.of(_navigatorKey.currentContext!)`. SnackBar text uses
  `AppTextStyles.bodyMedium.copyWith(color: AppColors.surface)` — never a raw
  `TextStyle`. All inline spacers use ScreenUtil (`12.w`, etc.).
  Every SnackBar must include `shape` (BorderRadius.circular(12.r)) and
  `margin` (EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h)) for
  proper Material 3 floating appearance.
  Material widgets only.

- `lib/core/helpers/bottom_sheet_helper.dart`
  Method: showAppBottomSheet(context, child, {isScrollable, maxHeight}).
  Shows a Material modal bottom sheet with: drag handle, top rounded corners,
  SafeArea at bottom, optional height as fraction of screen height.
  All chrome dimensions (corner radii, drag-handle size, paddings) must use
  ScreenUtil (`.r/.w/.h`). No raw pixel literals.
  Material widgets only.

- `lib/core/helpers/date_formatter_helper.dart`
  Uses intl package (DateFormat).
  Methods: formatDate (dd MMM yyyy), formatDateTime (dd MMM yyyy • hh:mm a),
  formatTimeAgo (relative: "2 hours ago", "yesterday"), formatDayMonth (dd MMM),
  formatMonthYear (MMM yyyy).
  All methods are static. Handles null input gracefully (returns empty string).

- `lib/core/helpers/regex_helper.dart`
  Static const RegExp patterns:
  email, egyptianPhone (01[0125] followed by 8 digits),
  password (min 8 chars, at least 1 uppercase, 1 lowercase, 1 digit),
  strongPassword (above + special character),
  username (alphanumeric + underscore, 3–20 chars),
  numericOnly, arabicText, noSpecialChars.
  Also exposes static bool validate(RegExp pattern, String value) helper.

**Shared Widgets:**

These three widgets live in `lib/core/widgets/` and are used by every feature's
`BlocBuilder`. Create them during scaffold — do not recreate per feature.

- `lib/core/widgets/app_loading_indicator.dart`
  `StatelessWidget`. Centered `CircularProgressIndicator` inside a `SizedBox`
  (default 32.w × 32.w, strokeWidth 2.5). Accepts optional `color` and `size`.
  Use inside `BlocBuilder` loading states: `if (state is XxxLoading) const AppLoadingIndicator()`.

- `lib/core/widgets/empty_state_widget.dart`
  `StatelessWidget`. Required: `IconData icon`, `String title`.
  Optional: `String? subtitle`, `String? actionLabel`, `VoidCallback? onAction`.
  Layout: centered column — icon (64.w, textHint color), title (titleMedium),
  subtitle (bodyMedium, textSecondary), action ElevatedButton.
  Use inside `BlocBuilder` empty states.

- `lib/core/widgets/error_state_widget.dart`
  `StatelessWidget`. Required: `String message`.
  Optional: `VoidCallback? onRetry`.
  Layout: centered column — `Icons.error_outline` (64.w, error color),
  message (bodyMedium, textSecondary), retry `OutlinedButton.icon` with refresh icon.
  Use inside `BlocBuilder` error states — message always comes from `failureToMessage()`.

**Networking:**

- `lib/core/network/failure.dart`
  Abstract class Failure extends Equatable.
  Subtypes: ServerFailure(statusCode, message), NetworkFailure,
  UnauthorizedFailure, CacheFailure, ValidationFailure(message),
  UnexpectedFailure(message).
  Each overrides props for Equatable.

- `lib/core/network/api_result.dart`
  Internal sealed class (not exposed outside network layer).
  Subtypes: ApiSuccess<T>(data T) and ApiFailure(failure Failure).
  Imported only by ApiManager.

- `lib/core/network/interceptors/auth_interceptor.dart`
  Extends Interceptor.
  Constructor receives `SecureStorageHelper` **and `GlobalKey<NavigatorState>`**
  (both injected — NOT fetched from getIt inside the interceptor to avoid
  circular dependency).
  onRequest: reads token → if not null, sets Authorization: Bearer header;
  if null, skips silently (public route).
  onError: if 401 → clears token via SecureStorageHelper →
  `_navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, ...)`.

- `lib/core/network/dio_factory.dart`
  Factory class (`@lazySingleton`) — produces the Dio singleton.
  Constructor receives `SecureStorageHelper` and `GlobalKey<NavigatorState>`,
  both forwarded to `AuthInterceptor`.
  Creates Dio with BaseOptions from ApiConstants.
  Interceptor order — **PrettyDioLogger first (when `kDebugMode`), then
  AuthInterceptor**. This ordering is mandatory: if AuthInterceptor runs first,
  PrettyDioLogger will log the just-attached `Authorization: Bearer …` header
  in debug builds.
  The produced Dio instance is registered as `@singleton` via RegisterModule.
  Construction order: FlutterSecureStorage → SecureStorageHelper →
  GlobalKey<NavigatorState> → DioFactory → Dio.

- `lib/core/network/api_manager.dart`
  Registered as @lazySingleton.
  Constructor receives Dio.
  Methods: get, post, put, delete, patch — all generic, all return
  Future<Either<Failure, T>>.
  `JsonMapper<T>` signature is `T Function(Object? json)` — never `dynamic`.
  Callers cast explicitly at the boundary
  (e.g. `(json) => Foo.fromJson(json as Map<String, dynamic>)`).
  Internally: calls Dio → catches DioException → maps to Failure subtype →
  wraps in Left. On success: deserializes via a passed fromJson function → Right.
  `DioExceptionType.badResponse` with a null `statusCode` maps to
  `UnexpectedFailure`, never `ServerFailure(0, ...)` — `ServerFailure` only
  carries real HTTP statuses.
  Conversion chain: DioResponse → ApiResult → Either<Failure, T>.
  Never throws — always returns Either.

- `lib/core/network/connectivity_helper.dart`
  Registered as @lazySingleton.
  Wraps connectivity_plus.
  Exposes: Future<bool> isConnected(), Stream<bool> connectivityStream.
  Stream maps ConnectivityResult list to bool (true = has connection).

- `lib/core/network/failure_messages.dart`
  Top-level function: `failureToMessage(Failure failure) → String`.
  Handles all Failure subtypes. Dev vs prod behaviour:
  - `ValidationFailure`: always passes message through (written for the user).
  - `ServerFailure` / `UnexpectedFailure`: in debug shows raw status + message; in
    release shows a generic string (`kReleaseMode` guard — tree-shaken by compiler).
  - All other subtypes: environment-independent, always user-friendly.
  Single source of truth for error strings. Never duplicated per feature.
  Feature layer imports as:
  `import 'package:booksplatform/core/network/failure_messages.dart' as core;`

- `lib/core/network/api_envelope.dart` *(create only when backend wraps every response)*
  Top-level function: `unwrapServiceResult(json, fromJson)`.
  Extracts `data` from envelope `{ "success": true, "data": {...}, "errors": {} }`.
  Throws `FormatException` (caught by `ApiManager` as `UnexpectedFailure`) when the
  top-level response is not a JSON object or `data` is null.
  For void endpoints (logout, delete) bypass entirely: `fromJson: (_) => unit`.
  See feature guide §11 for usage patterns.
  **Foundation phase — envelope pattern not yet confirmed:** do not create a skeleton file.
  Add a single marker comment in `api_manager.dart` instead:
  `// If backend wraps responses in { "success": true, "data": {...} }, create api_envelope.dart — see feature guide §11.`

**Routing:**

- `lib/core/router/navigator_key.dart`
  **Does not exist as a top-level global.** The `GlobalKey<NavigatorState>` is
  provided by `RegisterModule` as `@singleton`:
  ```dart
  @singleton
  GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();
  ```
  Consumers — `DialogHelper`, `SnackBarHelper`, `AuthInterceptor`, `DioFactory`,
  and `main.dart`'s `MaterialApp` — receive it via constructor injection or
  `getIt<GlobalKey<NavigatorState>>()`. `injection_container.dart` does **no**
  manual registration of the key.

- `lib/core/router/app_routes.dart`
  Exports: AppRoutes class with static const String fields for every route.
  Initially: splash ('/'), login ('/login'), register ('/register'),
  home ('/home'), unknown ('/unknown').

- `lib/core/router/args/` *(directory)*
  Contains one file per screen that requires navigation arguments.
  Naming: `<screen>_args.dart` (e.g. `book_detail_args.dart`).
  Args classes are immutable plain Dart — no Equatable needed.
  Placed in core (not inside features) so any feature can import and construct
  args before navigating without creating Feature → Feature import violations.
  `AppRouter.generateRoute` casts `settings.arguments` with a null guard;
  null → `_unknown(settings)`.

- `lib/core/router/app_router.dart`
  Static method: generateRoute(RouteSettings settings) → Route<dynamic>.
  Switch on settings.name → returns MaterialPageRoute for each known route.
  Each route that needs arguments receives a typed argument class
  (e.g. HomeArgs, LoginArgs) — no raw Map<String, dynamic> casting ever.
  Default case → returns route to UnknownScreen (a simple placeholder widget
  defined inline in this file).
  A private static `_unknown(RouteSettings settings)` helper is extracted from
  the switch — every null-guard on a missing/invalid args cast delegates to it,
  keeping all route cases consistent.
  When a screen lives in a folder (`pages/<screen_name>/<screen_name>_screen.dart`),
  the import path in `AppRouter` reflects that — the `BlocProvider` creation pattern
  is identical regardless of flat or folder layout.

**Localization:**

- Translation JSON files live in `assets/translations/`, one file per supported language
  (e.g. `en.json`, `ar.json`). `en.json` always exists — it is the source language where
  all keys are first written and the fallback when a key is missing in another language.
  Additional language files are added only when that language is actively supported —
  never create them speculatively.
  Keys are dot-separated namespaced strings (e.g. `home.title`, `auth.loginButton`).
  Declare the directory in `pubspec.yaml`:
  ```yaml
  flutter:
    assets:
      - assets/translations/
  ```
  Start each file with `{}` — features populate keys as they are built.
  Never hardcode user-visible strings in screens or widgets, even in a single-language app —
  always use a translation key. Adding a new language requires only adding a new JSON file;
  no code changes are needed.

- Reading a translated string in a widget:
  ```dart
  import 'package:easy_localization/easy_localization.dart';
  Text('home.title'.tr())
  ```

- Switching locale at runtime (e.g. in the language-selection screen):
  ```dart
  context.setLocale(const Locale('ar'));
  ```

- Reading the current locale code (use only for content branching — e.g. `book.titleAr` vs
  `book.titleEn`; never for directional icon or padding decisions):
  ```dart
  final locale = context.locale.languageCode; // 'ar' or 'en'
  ```

- The scaffold generates no `lib/core/l10n/` folder and no generated `.dart` files.
  `easy_localization` loads JSON at runtime; no code-gen step is required.

**Storage:**

- `lib/core/storage/secure_storage_helper.dart`
  Registered as @lazySingleton.
  Constructor receives FlutterSecureStorage (injected).
  Typed methods: saveToken(String), getToken() → Future<String?>,
  deleteToken(), saveString(key, value), getString(key) → Future<String?>,
  deleteKey(key), clearAll().
  Keys sourced from AppConstants (kTokenKey, kUserKey).

**Dependency Injection:**

- `lib/core/di/injection_container.dart`
  Entry point annotated with @InjectableInit.
  No manual registrations — every dependency, including `FlutterSecureStorage`
  and `GlobalKey<NavigatorState>`, is provided by `RegisterModule` (a `@module`
  abstract class).
  Generated .config.dart handles all @injectable / @lazySingleton / @singleton
  annotated classes (and `@module` providers) automatically.
  Exports: getIt instance and configureDependencies() Future.

- `lib/core/di/register_module.dart`
  Abstract class annotated `@module`. Provides:
    - `FlutterSecureStorage` → `@lazySingleton`
      `flutter_secure_storage` v10+ auto-migrates to custom ciphers — use
      `const FlutterSecureStorage()` with no options. Do NOT pass
      `AndroidOptions(encryptedSharedPreferences: true)`; that API is deprecated
      and will be removed in v11.
    - `GlobalKey<NavigatorState>` → `@singleton`
    - `Dio` → `@singleton` (built by `DioFactory.create()`)
    - `SharedPreferences` → `@preResolve @singleton`
      Async provider — annotate with both `@preResolve` and `@singleton` so injectable
      awaits the future before registering downstream dependencies. This requires
      `configureDependencies()` to be `async` and the generated `init()` to be awaited.

**Entry Point:**

- `lib/main.dart`
  Strict initialization order:
    1. WidgetsFlutterBinding.ensureInitialized()
    2. await EasyLocalization.ensureInitialized()
    3. await initializeDateFormatting('en')
    4. await initializeDateFormatting('ar')
    5. await configureDependencies()
    6. runApp(
         EasyLocalization(
           supportedLocales: const [Locale('en')], // add Locale('ar') etc. as languages are added
           path: 'assets/translations',
           fallbackLocale: const Locale('en'),
           child: const MyApp(),
         ),
       )
  MyApp is a StatelessWidget. Its `build` receives a `context` that already has the
  `EasyLocalization` provider above it, so it returns:
  ScreenUtilInit(
    designSize: Size(kDesignWidth, kDesignHeight),
    builder: (context, child) => MaterialApp(
      navigatorKey: getIt<GlobalKey<NavigatorState>>(),
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRoutes.splash,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    )
  ).
  The three `context.*` properties wire `easy_localization` into Flutter's locale system
  so that `Directionality`, `Localizations`, and locale-aware widgets all update when
  `context.setLocale(...)` is called. Omitting any of them silently breaks locale switching.
  No top-level `navigatorKey` import — the key is pulled from `getIt`
  (safe because `configureDependencies()` is awaited before `runApp`).
  No feature logic. No hardcoded strings. No colors. No sizes.

---

**Edge Cases — All Must Be Addressed in the Plan:**

1. **Initialization order in main.dart:** DI before runApp; WidgetsFlutterBinding
   before DI; ScreenUtil inside the widget tree, never before runApp.

2. **ScreenUtil safe usage:** `.sp`, `.w`, `.h` forbidden at class-level static
   init. AppTextStyles and AppSpacing must use lazy getters (static getters,
   not static const). Plan must name this rule explicitly.
   Note: ScreenUtil only handles proportional scaling — content overflow and device safe areas (notch, home indicator) are screen-level responsibilities covered in `flutter_feature_prompt.md §6`.

3. **Auth interceptor circular dependency:** Construction order must be:
   FlutterSecureStorage → SecureStorageHelper → GlobalKey<NavigatorState> →
   DioFactory → AuthInterceptor (created inside `DioFactory.create()` with
   both deps already resolved) → Dio.
   AuthInterceptor receives `SecureStorageHelper` **and**
   `GlobalKey<NavigatorState>` via constructor injection, NOT via getIt lookup
   inside the interceptor.

4. **ApiResult → Either conversion:** ApiManager is the single boundary.
   No class outside the network layer ever imports api_result.dart.

5. **Typed route arguments:** Each screen that needs arguments has a dedicated
   immutable args class in `lib/core/router/args/<screen>_args.dart`.
   `AppRouter.generateRoute` casts `settings.arguments` to the typed class with a
   null guard (null → `_unknown(settings)`), never to `Map`.
   Args live in core so both feature and non-feature callers can import without
   cross-feature dependency violations. See feature guide §10 for full pattern.

6. **Null token on public routes:** AuthInterceptor skips the Authorization
   header silently when token is null. It does not throw, redirect, or log.

7. **DI scope per service:** Every service in the plan has an explicit scope.
   No unspecified or assumed scope allowed.

8. **Environment switching:** Plan documents exactly how to pass
   `--dart-define=ENVIRONMENT=prod` in VS Code launch.json and Android Studio
   run configuration so the team can switch environments without touching code.

9. **intl initialization:** If DateFormat requires locale initialization
   (initializeDateFormatting), the plan must specify where this is called
   in main.dart and for which locales (ar, en minimum).

10. **kDebugMode guard on logger:** PrettyDioLogger must only be added to Dio
    interceptors when `kDebugMode == true` — never in release builds.
    Additionally, PrettyDioLogger must be added **before** AuthInterceptor.
    Otherwise the logger sees the `Authorization: Bearer …` header that
    AuthInterceptor just attached, and the bearer token leaks into debug logs.

11. **ScreenUtil for chrome inside helpers:** All UI chrome inside foundation
    helpers (`DialogHelper`, `SnackBarHelper`, `BottomSheetHelper`) must use
    ScreenUtil for radii, paddings, gap widths, and handle sizes. No raw pixel
    literals. Helpers run inside the `ScreenUtilInit` widget tree (they are
    invoked from `build`-driven callbacks), so `.r/.w/.h` is safe at call time.

12. **Injected helpers, not statics:** `DialogHelper` and `SnackBarHelper` are
    `@lazySingleton` classes with constructor-injected `GlobalKey<NavigatorState>`.
    They are NOT static utility classes. Call sites use
    `getIt<DialogHelper>().showAppDialog(...)` /
    `getIt<SnackBarHelper>().showSuccess(...)`. There is no top-level
    `navigatorKey` global to import.

13. **JsonMapper uses `Object?`:** `ApiManager`'s `JsonMapper<T>` is
    `T Function(Object? json)`, never `dynamic`. Callers cast explicitly at the
    boundary. ApiManager's `badResponse` branch with a null statusCode returns
    `UnexpectedFailure`, not `ServerFailure(0, ...)`.

14. **EasyLocalization initialization and wiring:** Three distinct requirements must
    all be satisfied or locale switching silently breaks:
    - `await EasyLocalization.ensureInitialized()` must run in `main()` before
      `configureDependencies()` and before `runApp`. It reads the cached locale from
      shared preferences; skipping it causes the app to always start in the fallback locale.
    - `runApp` must receive an `EasyLocalization(supportedLocales, path, fallbackLocale, child)`
      widget as root so the provider is above `MyApp` in the widget tree.
    - `MaterialApp` must declare `localizationsDelegates: context.localizationDelegates`,
      `supportedLocales: context.supportedLocales`, and `locale: context.locale`.
      Without these, Flutter's own `Directionality` widget never updates when
      `context.setLocale(...)` is called, so RTL/LTR switching has no visual effect.
    Note: `EasyLocalization.ensureInitialized()` internally calls
    `WidgetsFlutterBinding.ensureInitialized()`; calling it explicitly first is still
    recommended for clarity.

---

⛔ Do not write any code yet. Produce the full file plan with responsibilities
   and wait for my approval before writing a single line of Dart.

---

> **Companion:** `flutter_feature_prompt.md` owns everything inside `lib/features/`.
> Read it alongside this file when developing any feature.
