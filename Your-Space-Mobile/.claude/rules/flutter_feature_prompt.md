# BooksPlatform — Feature Scaffold Guide

> **Companion to `flutter_scaffold_prompt.md`.**
> That file owns the foundation and core layer (DI, networking, storage, routing, theming).
> This file owns everything inside `lib/features/<feature_name>/`.
> When building a new feature, read both. Core is already built; this is your blueprint.

---

## 1. Canonical Folder Structure

```
lib/features/<feature>/
├── data/
│   ├── datasources/                                # add base_* + local_* only when local source needed (§1.1)
│   │   ├── base_<feature>_data_source.dart        # abstract — only when local source exists
│   │   ├── <feature>_remote_data_source_impl.dart # @lazySingleton
│   │   └── <feature>_local_data_source_impl.dart  # @lazySingleton — only when local source exists
│   ├── models/
│   │   ├── <input>_request.dart                    # toJson only
│   │   └── <output>_response.dart                  # fromJson + toEntity()
│   └── repositories/
│       └── <feature>_repository_impl.dart          # @LazySingleton(as: <Feature>Repository)
├── domain/
│   ├── entities/
│   │   └── <entity>.dart                           # pure Dart, Equatable, no imports from data/
│   ├── repositories/
│   │   └── base_<feature>_repository.dart          # abstract, returns entities not models
│   └── use_cases/                                  # add only when rule in §4 applies
│       └── <verb>_<noun>_use_case.dart             # @injectable
└── presentation/
    ├── cubit/
    │   ├── <action>_cubit/
    │   │   ├── <action>_cubit.dart                 # @injectable (factory)
    │   │   └── <action>_state.dart                 # sealed class
    │   └── <query>_cubit/
    │       ├── <query>_cubit.dart                  # @injectable (factory)
    │       └── <query>_state.dart                  # sealed class
    ├── pages/
    │   ├── <screen>_screen.dart       # flat — under ~250 lines, no embedded StatefulWidget
    │   └── <screen>_screen/            # folder — exceeds threshold (see §1.1)
    │       ├── <screen>_screen.dart   # only the screen widget
    │       ├── <screen>_body.dart
    │       └── <screen>_shimmer.dart
    └── widgets/
        └── <component>.dart           # shared across 2+ screens only
```

**Rule:** Never add folders that are empty. Only create `use_cases/` when §4 applies.
Only create a `widgets/` folder if widgets are shared across two or more screens in the feature.

### §1.1 — Screen file vs screen folder

Use a flat file by default. Create a screen folder when either threshold is crossed:

| Threshold | Trigger |
|---|---|
| File size | Total widget code reaches ~250 lines |
| Lifecycle | Any embedded component is a `StatefulWidget` with its own controller or form |

**Flat (default):**
```
pages/
└── catalog_screen.dart    # simple, stays flat
```

**Folder (threshold crossed):**
```
pages/
└── home_screen/
    ├── home_screen.dart              # only HomeScreen — routing target
    ├── home_body.dart                # main scroll content
    ├── home_categories_section.dart
    ├── home_books_carousel_section.dart
    ├── home_newsletter_strip.dart    # StatefulWidget — always extract
    └── home_shimmer.dart             # all shimmer skeletons in one file
```

**Rules inside a screen folder:**
- `<screen>_screen.dart` contains only the screen widget — no private sub-widgets.
- One file per extracted component. Group closely related skeletons (e.g. all shimmer
  classes for the same screen) into a single `<screen>_shimmer.dart`.
- No `states/` subfolder — "states" already means cubit sealed classes in this codebase.
  Name files by visual concern and keep flat.
- Components here are **not** reusable widgets. If a component is needed in a second
  screen, move it to `widgets/` and import from there.

### Data source: single file vs contract + implementations

Default — remote only:
```
datasources/
└── <feature>_remote_data_source_impl.dart   # concrete, @lazySingleton
```

When a feature needs a **local data source** (offline cache, recently-viewed records, local
persistence), introduce an abstract contract and split into two implementations:
```
datasources/
├── base_<feature>_data_source.dart              # abstract contract, read operations only
├── <feature>_remote_data_source_impl.dart       # @Named('remote') @LazySingleton(as: Base<Feature>DataSource)
└── <feature>_local_data_source_impl.dart        # @Named('local')  @lazySingleton
```

The remote impl must bind **as** the abstract contract — plain `@lazySingleton` only
registers it under its own concrete type, and the repository's `Base<Feature>DataSource`-typed
constructor parameter can't resolve it (`build_runner` fails with "depends on unregistered
type"). `@LazySingleton(as: Base<Feature>DataSource)` is what actually satisfies that.

The abstract contract covers **read** operations only — whatever the repository needs to
be able to serve from either source. The local impl also exposes its own `save*` methods to
populate the cache after a successful remote fetch; those have no remote equivalent, so they
live only on the concrete local class, never on the shared interface.

The repository impl holds `_remote` typed against the abstraction (swappable, no extra
methods) and `_local` typed against its **concrete** class (so it can call the save methods):
```dart
@LazySingleton(as: BookRepository)
class BookRepositoryImpl implements BookRepository {
  final BaseBookDataSource _remote;        // abstract — read-only contract
  final BookLocalDataSourceImpl _local;    // concrete — exposes save* too

  BookRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
  );

  @override
  Future<Either<Failure, Book>> getBook(String id) async {
    final result = await _remote.getBook(id);
    return result.fold(
      (_) => _local.getBook(id),
      (book) async {
        await _local.saveBook(book);
        return right(book);
      },
    );
  }
}
```

Do not create the abstract contract until a local data source actually exists.
A base class with one implementation is ceremony with no benefit.

### Choosing a storage backend

`SharedPreferences` is the default for feature-level local data source caching — it's
already `@preResolve @singleton` in `register_module.dart`, and it's what `CartStorage`,
`SearchHistoryStorage`, and `WishlistStorage` already use for the same kind of data. Only
reach for something heavier when a feature's data genuinely outgrows a flat key-value
store — decide per feature against this table, not preemptively:

| Signal | Storage choice |
|---|---|
| Bounded reference/user data (settings, wishlist, cart, recently-viewed, small paginated lists) | `SharedPreferences` |
| Caching a full catalog for real offline-first browsing (e.g. entire books list so search/filter/sort work with no connection) | `Hive` — SharedPreferences forces decoding the entire JSON blob on every read just to filter a subset, and rewriting the whole blob on every write |
| Relational queries across cached entities (joins, filtered counts, cross-entity lookups) | `drift` — Hive is still a KV/box store; `drift` gives real type-safe SQL queries |
| Sync/conflict resolution (bi-directional offline edits) | Out of scope for a read cache — needs its own design |

Adding Hive or drift is still a new package — it must clear the dependency rule (see
CLAUDE.md) same as anything else. This table is what makes "necessary and justified"
concrete for caching specifically.

### Per-entity cache keys need an eviction strategy

A single default-list/countries-style cache is naturally bounded — it gets overwritten
wholesale on each successful fetch. A per-entity cache (one key per viewed record, e.g.
`cache_<feature>_detail_<slug>`) is not — every entity a user ever views gets a permanent
key, with no built-in expiry. If the feature's cardinality is large or unbounded, the local
data source needs an explicit cap (e.g. LRU to N most-recently-viewed, prune on write).
Deciding "no eviction" is fine for a small catalog, but it must be a deliberate call, not
a default.

---

## 2. The Five Non-Negotiable Rules

### Rule 1 — Auth is invisible to the data layer

Data source methods must never touch a token, call an auth service, or manually build a
`headers` map. Auth is handled entirely by `AuthInterceptor` (defined in the scaffold —
`lib/core/network/interceptors/auth_interceptor.dart`).

**Correct:**
```dart
Future<Either<Failure, BookResponse>> getBook(String id) =>
    _api.get<BookResponse>(
      path: '/books/$id',
      fromJson: (json) => BookResponse.fromJson(json as Map<String, dynamic>),
    );
```

**Wrong — never do this:**
```dart
// ❌ Manual token in data source — violates Rule 1
final token = await storage.getToken();
final headers = {'Authorization': 'Bearer $token'};
final response = await dio.get('/books/$id', options: Options(headers: headers));
```

---

### Rule 2 — ApiManager is the single error mapper

All HTTP calls go through `ApiManager` (defined in the scaffold). It catches every
`DioException` and returns `Either<Failure, T>` — features never see raw exceptions.

Data source methods must never contain a `try/catch` block. They return the `Either` that
`ApiManager` already produced.

**Correct:**
```dart
Future<Either<Failure, String>> forgotPassword(String email, UserRole role) =>
    _api.post<String>(
      path: '${role.path}/forgot-password',
      data: {'email': email},
      fromJson: (json) => unwrapServiceResult(json, (inner) => inner.toString()),
    );
```

**Wrong:**
```dart
// ❌ try/catch in data source — violates Rule 2
try {
  final response = await dio.post('/forgot-password', data: {...});
  if (response.statusCode == 200) return right(response.data['nonce']);
  return left(ServerFailure(...));
} on DioException catch (e) {
  return left(NetworkFailure(...));
} catch (e) {
  return left(ServerFailure(...));
}
```

**Corollary:** All user-facing error strings come from `failureToMessage(Failure)` in
`lib/core/network/failure_messages.dart` (created during scaffold phase — see §9).
No screen or cubit hardcodes error strings.

---

### Rule 3 — Domain entities are never response models

The domain repository contract (`abstract class <Feature>Repository`) returns only:
- Domain entities defined in `domain/entities/`
- Dart primitives (`String`, `int`, `bool`)
- `Unit` (dartz) for void operations

Response models (`data/models/*_response.dart`) never cross into the domain or presentation
layers. The repository implementation maps them with `toEntity()`.

**Correct domain contract:**
```dart
// domain/repositories/base_book_repository.dart
abstract class BookRepository {
  Future<Either<Failure, Book>> getBook(String id);           // ✅ entity
  Future<Either<Failure, List<Book>>> searchBooks(String q);  // ✅ entity list
  Future<Either<Failure, Unit>> addToFavourites(String id);   // ✅ Unit
}
```

**Wrong:**
```dart
// ❌ Response model in domain contract — violates Rule 3
abstract class BookRepository {
  Future<Either<Failure, BookResponseModel>> getBook(String id);
}
```

**Mapping in the repository impl:**
```dart
@override
Future<Either<Failure, Book>> getBook(String id) async {
  final result = await _remote.getBook(id);
  return result.fold(
    (failure) async => Left(failure),
    (response) async => Right(response.toEntity()),  // ← toEntity() lives on the model
  );
}
```

---

### Rule 4 — Use cases: add only when the rule applies

A use case is a class with a `call()` method that wraps one repository operation.
The overhead is real (one file, one class, one constructor parameter per cubit).
Do not add use cases by default.

**Add a use case when ANY of these is true:**

| Condition | Example |
|---|---|
| The operation is called from **two or more cubits** | `GetCurrentUserUseCase` called by `ProfileCubit` and `HomeCubit` |
| The operation has **non-trivial domain logic** beyond a single repo call | Combining two repo calls, applying business rules, coordinating side-effects |
| The operation needs **independent unit testing** away from the cubit | Complex validation, ordering, filtering logic |

**Skip use cases when:**
- The cubit calls the repository once and emits a state — no logic beyond that.
- The operation is specific to one screen and one cubit.

**Use case template (when warranted):**
```dart
// domain/use_cases/get_book_recommendations_use_case.dart
@injectable
class GetBookRecommendationsUseCase {
  final BookRepository _bookRepo;
  final UserRepository _userRepo;

  GetBookRecommendationsUseCase(this._bookRepo, this._userRepo);

  Future<Either<Failure, List<Book>>> call(String userId) async {
    final profileResult = await _userRepo.getProfile(userId);
    return profileResult.fold(
      Left.new,
      (profile) => _bookRepo.getRecommendations(profile.preferences),
    );
  }
}
```

**Direct repo call in cubit (no use case, correct for simple ops):**
```dart
// presentation/cubit/login/login_cubit.dart
Future<void> submit({required String email, required String password}) async {
  emit(const LoginLoading());
  final result = await _authRepository.login(LoginRequest(email: email, password: password));
  result.fold(
    (failure) => emit(LoginFailure(failureToMessage(failure))),
    (_) => emit(const LoginSuccess()),
  );
}
```

---

### Rule 5 — Action/query cubit split

Any feature that has **both mutations (write operations) and lists (read operations)** must
use separate cubits for each concern. Mixing them in one cubit causes state collisions —
a loading indicator on "accept request" would clobber the loaded friends list.

**Split pattern:**

```
cubit/
├── <feature>_action_cubit/   ← handles: add, remove, update, block, send, etc.
│   ├── <feature>_action_cubit.dart
│   └── <feature>_action_state.dart
└── <feature>_list_cubit/     ← handles: fetch, refresh, paginate
    ├── <feature>_list_cubit.dart
    └── <feature>_list_state.dart
```

**In the screen — `BlocConsumer` for action, `BlocBuilder` for list:**
```dart
BlocConsumer<BookActionCubit, BookActionState>(
  listener: (context, state) {
    if (state is BookActionSuccess) {
      getIt<SnackBarHelper>().showSuccess(state.message);
      context.read<BookListCubit>().refresh();  // ← action triggers list refresh
    } else if (state is BookActionError) {
      getIt<SnackBarHelper>().showError(state.message);
    }
  },
  builder: (context, _) {
    return BlocBuilder<BookListCubit, BookListState>(
      builder: (context, state) {
        // render list
      },
    );
  },
);
```

**When a feature has only reads or only writes, one cubit is fine.**

---

## 3. DI Scopes — Per Class Type

| Class | Annotation | Scope | Reason |
|---|---|---|---|
| Remote data source | `@lazySingleton` | Lifetime | Stateless HTTP wrapper |
| Repository impl | `@LazySingleton(as: Repo)` | Lifetime | Stateless, bound to interface |
| Use case | `@injectable` | Factory | Injected into cubit which is also a factory |
| Cubit | `@injectable` | Factory | Has local state — must never be shared |
| Request model | — | n/a | Plain Dart, instantiated inline |
| Response model | — | n/a | Plain Dart, instantiated in `fromJson` |
| Entity | — | n/a | Plain Dart, returned from `toEntity()` |

Cubit registration as factory is mandatory. `AppRouter` always does
`BlocProvider(create: (_) => getIt<XxxCubit>())` — each route build gets a fresh instance.

---

## 4. State Design — Sealed Classes

Every cubit state file uses a `sealed class` as the base and `final class` for each variant.
Extend `Equatable` and override `props`.

```dart
// presentation/cubit/book_list/book_list_state.dart
sealed class BookListState extends Equatable {
  const BookListState();
  @override
  List<Object?> get props => const [];
}

final class BookListInitial extends BookListState {
  const BookListInitial();
}

final class BookListLoading extends BookListState {
  const BookListLoading();
}

final class BookListSuccess extends BookListState {
  final List<Book> books;
  const BookListSuccess(this.books);
  @override
  List<Object?> get props => [books];
}

final class BookListError extends BookListState {
  final String message;
  const BookListError(this.message);
  @override
  List<Object?> get props => [message];
}
```

The `sealed` keyword enables exhaustive `switch` expressions in `BlocBuilder` and prevents
unhandled state variants at compile time.

---

## 5. Directional UI — RTL/LTR

This app targets AR (RTL) and EN (LTR). Every UI value that has a direction must use
Flutter's direction-aware primitive. Never write `isRtl`/`locale == 'ar'` ternaries to
choose between two hardcoded directional values — that pattern is fragile, clutters
callers, and breaks if locale detection changes.

### Rule: use direction-aware primitives everywhere

| Hardcoded (wrong) | Direction-aware (correct) |
|---|---|
| `EdgeInsets.only(left: …)` | `EdgeInsetsDirectional.only(start: …)` |
| `EdgeInsets.only(right: …)` | `EdgeInsetsDirectional.only(end: …)` |
| `Alignment.centerLeft / centerRight` | `AlignmentDirectional.centerStart / centerEnd` |
| `Alignment.topLeft / bottomRight` | `AlignmentDirectional.topStart / bottomEnd` |
| `Positioned(left: …)` | `PositionedDirectional(start: …)` |
| `TextAlign.left` | `TextAlign.start` |
| `TextAlign.right` | `TextAlign.end` |

**Vertical-only values are direction-neutral** — `Alignment.topCenter/bottomCenter`,
`EdgeInsets.symmetric(vertical: …)` — and need no change.

### Directional icons — never ternary

Flutter's Material icon set bakes `matchTextDirection` into the `IconData` of standard
directional icons. The `Icon` widget reads `Directionality.of(context)` internally and
mirrors the glyph automatically — no logic needed in the caller.

```dart
// ❌ Fragile — isRtl / locale variable pollutes every caller
Icon(isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded)
Icon(locale == 'ar' ? Icons.chevron_left_rounded : Icons.chevron_right_rounded)

// ✅ The icon mirrors automatically — no caller logic
Icon(Icons.chevron_right_rounded)  // forward / next / see-all
Icon(Icons.arrow_back_rounded)     // back button
Icon(Icons.arrow_forward_rounded)  // go-forward (full arrow variant)
```

**Icon → intent mapping:**

| Icon | Meaning | In RTL renders as |
|---|---|---|
| `Icons.chevron_right_rounded` | Forward / next / see-all | ‹ (left-pointing) |
| `Icons.arrow_back_rounded` | Back / previous | → (right-pointing) |
| `Icons.arrow_forward_rounded` | Go forward (full arrow) | ← (left-pointing) |

### Exception: explicit-direction cards

When a widget must express the direction of a **specific language** — not the app's
current direction — (e.g. a language-selection card that must always show ‹ for Arabic
and › for English regardless of the current locale), override the ambient `Directionality`
explicitly rather than picking a hardcoded icon:

```dart
Directionality(
  textDirection: isRtlLanguage ? TextDirection.rtl : TextDirection.ltr,
  child: Icon(Icons.chevron_right_rounded),
)
```

This is the **only** legitimate reason to override direction on an icon. In all other
screens and widgets, let ambient `Directionality` do the work.

---

## 6. Layout & Responsiveness

ScreenUtil scales sizes proportionally across devices. It does **not** handle content overflow or device safe areas — those are your responsibility on every screen. They are two separate concerns.

### Never stack fixed `.h` sections

A column of fixed-height widgets will overflow on short phones or when the keyboard opens.

```dart
// ❌ Wrong — total height can exceed viewport on short devices
Column(children: [HeroSection(), CategorySection(), BooksSection(), StatsStrip()])

// ✅ Correct — scrolls when content is taller than the screen
SingleChildScrollView(
  child: Column(children: [HeroSection(), CategorySection(), BooksSection(), StatsStrip()]),
)
```

Use `Expanded` for a section that should fill remaining space (e.g. a list inside a `Scaffold` body):

```dart
// ❌ Wrong — fixed height overflows on short phones
Container(height: 400.h, child: BookList())

// ✅ Correct — takes whatever space is left
Expanded(child: BookList())
```

Use `Flexible` + `TextOverflow.ellipsis` for text beside other content in a `Row`:

```dart
Row(
  children: [
    Flexible(
      child: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
    ),
    Text(book.price),
  ],
)
```

Use `AspectRatio` for book covers — never a fixed `.h` on an image:

```dart
AspectRatio(
  aspectRatio: 2 / 3,
  child: BookCoverImage(book: book),
)
```

### SafeArea — protect from notch and home indicator

Flutter renders behind system UI by default. Apply `SafeArea` on every screen:

```dart
// Scaffold body — covers notch + status bar
Scaffold(
  body: SafeArea(child: YourScreenContent()),
)

// Bottom nav bar — only protect the bottom (home indicator)
SafeArea(
  top: false,
  child: BottomNavBar(),
)
```

For screens with a pinned bottom button (BookDetail, Cart, Checkout), use `Scaffold.bottomNavigationBar` — not `Positioned`:

```dart
// ❌ Wrong — home indicator hides the button; Scaffold body scroll doesn't account for it
Scaffold(
  body: Stack(children: [BookContent(), Positioned(bottom: 0, child: AddToCartButton())]),
)

// ✅ Correct — Flutter pads the scroll body automatically; SafeArea clears the home indicator
Scaffold(
  body: SingleChildScrollView(child: BookContent()),
  bottomNavigationBar: SafeArea(
    top: false,
    child: AddToCartButton(),
  ),
)
```

---

## 7. Response Model Rules

Response models live in `data/models/` and have two responsibilities only:
1. `fromJson(Map<String, dynamic>)` — deserialize from API JSON
2. `toEntity()` — return the domain entity

```dart
// data/models/book_response.dart
class BookResponse {
  final String id;
  final String title;
  final String authorName;
  final String? coverUrl;

  const BookResponse({
    required this.id,
    required this.title,
    required this.authorName,
    this.coverUrl,
  });

  factory BookResponse.fromJson(Map<String, dynamic> json) => BookResponse(
        id: json['id'] as String,
        title: json['title'] as String,
        authorName: json['authorName'] as String,
        coverUrl: json['coverUrl'] as String?,
      );

  Book toEntity() => Book(
        id: id,
        title: title,
        authorName: authorName,
        coverUrl: coverUrl,
      );
}
```

Response models must never be `Equatable` or carry business logic.
They are data transfer objects — instantiated once, mapped to entity, then discarded.

---

## 8. Request Model Rules

Request models live in `data/models/` and expose only `toJson()`.

```dart
// data/models/add_review_request.dart
class AddReviewRequest {
  final String bookId;
  final int rating;
  final String? comment;

  const AddReviewRequest({
    required this.bookId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'rating': rating,
        if (comment != null) 'comment': comment,   // ← omit null fields
      };
}
```

Omit null optional fields from `toJson()` rather than sending `"field": null` unless the
backend explicitly requires null for "clear this field" semantics.

---

## 9. Error Messages — One Place

> **This file is created during scaffold phase.** `lib/core/network/failure_messages.dart`
> already exists when you start a feature. Do not recreate it. Import it directly.

All common failure messages live in **one shared file**:
`lib/core/network/failure_messages.dart`

```dart
// lib/core/network/failure_messages.dart
import 'package:flutter/foundation.dart';
import 'failure.dart';

String failureToMessage(Failure failure) => switch (failure) {
      NetworkFailure()        => 'No internet connection',
      UnauthorizedFailure()   => 'Session expired. Please sign in again',
      CacheFailure()          => 'Local storage error',
      ValidationFailure(message: final m) => m,
      ServerFailure(statusCode: final code, message: final m) =>
        kReleaseMode ? 'Something went wrong. Please try again.' : '[$code] $m',
      UnexpectedFailure(message: final m) =>
        kReleaseMode ? 'Unexpected error' : (m.isEmpty ? 'Unexpected error' : m),
      Failure() => 'Unexpected error',
    };
```

**Dev vs prod behaviour:**
- `ValidationFailure` — always passes the backend message through; it is written for the user.
- `ServerFailure` / `UnexpectedFailure` — in debug/profile builds shows the raw message and status
  code so developers see exactly what went wrong; in release builds shows a safe, generic string.
- All other failures are environment-independent — their messages are always user-friendly.

`kReleaseMode` is tree-shaken by the Flutter compiler — the debug branch does not exist in
production binaries. If the project adopts Flutter flavors later, replace `kReleaseMode` with
`AppConfig.isProduction` in this one file.

Cubits import and call this directly — no per-feature file needed:
```dart
import '../../../../core/network/failure_messages.dart' as core;

result.fold(
  (failure) => emit(LoginFailure(core.failureToMessage(failure))),
  (_) => emit(const LoginSuccess()),
);
```

### Feature-level override — only when needed

Create `presentation/cubit/failure_messages.dart` **only** when a feature has
feature-specific status codes to handle. Delegate everything else to core:

```dart
// lib/features/auth/presentation/cubit/failure_messages.dart
import 'package:booksplatform/core/network/failure_messages.dart' as core;
import 'package:booksplatform/core/network/failure.dart';

String failureToMessage(Failure failure) => switch (failure) {
      ServerFailure(statusCode: 423, message: final m) =>
        'Account locked: $m. Try again in 5 minutes.',
      _ => core.failureToMessage(failure),
    };
```

No screen or widget ever maps a `Failure` directly.
Do not create a feature-level `failure_messages.dart` unless a unique status code requires it.

---

## 10. Route Args

Only screens that require navigation parameters have an args class.
Args classes live in `lib/core/router/args/` — one file per screen:

```
lib/core/router/
├── app_router.dart
├── app_routes.dart
└── args/
    ├── book_detail_args.dart
    ├── author_profile_args.dart
    └── reader_args.dart
```

**Why `core/router/args/` and not next to the screen?**
The caller must import and construct the args object before navigating.
If args lived inside a feature, any other feature navigating there would import
from a foreign feature's presentation layer — a cross-feature dependency violation.
Placing args in `core/router/args/` makes the dependency direction clean:
Feature → Core, never Feature → Feature.

```dart
// lib/core/router/args/book_detail_args.dart
class BookDetailArgs {
  final String bookId;
  final String title;
  const BookDetailArgs({required this.bookId, required this.title});
}
```

`AppRouter.generateRoute` casts with a null guard:

```dart
case AppRoutes.bookDetail:
  final args = settings.arguments as BookDetailArgs?;
  if (args == null) return _unknown(settings);
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => BlocProvider(
      create: (_) => getIt<BookDetailCubit>(),
      child: BookDetailScreen(args: args),
    ),
  );
```

Caller in any feature:
```dart
Navigator.pushNamed(
  context,
  AppRoutes.bookDetail,
  arguments: BookDetailArgs(bookId: '123', title: 'My Book'),
);
```

New route name constants go in `lib/core/router/app_routes.dart`.
Do not add args classes to `app_router.dart` or inside any feature folder.

---

## 11. ApiEnvelope Unwrapper

**Only applies if the backend wraps every response in a general envelope:**
```json
{ "success": true, "data": { ... }, "errors": {} }
```

If the backend returns raw JSON with no wrapper, skip this section entirely —
do not create `api_envelope.dart` and call `fromJson` directly on the response.
If the decision is not yet confirmed at build time, add a single marker comment in
`api_manager.dart` — do not create a skeleton file.

When the envelope exists, `unwrapServiceResult` in `lib/core/network/api_envelope.dart`
extracts `data` so that `fromJson` only sees the inner object and never knows the envelope exists:

```dart
fromJson: (json) => unwrapServiceResult(
  json,
  (inner) => BookResponse.fromJson(inner as Map<String, dynamic>),
),
```

`unwrapServiceResult` throws a `FormatException` (caught by `ApiManager` as `UnexpectedFailure`) in two cases:
- The top-level response is not a JSON object
- `data` is `null` — explicit fast-fail with a message pointing to the fix

For endpoints that return `data: null` (e.g., logout, delete), **bypass the unwrapper entirely**:

```dart
fromJson: (_) => unit,
```

Never pass a void endpoint through `unwrapServiceResult` — it will throw.

---

## 12. Pre-Ship Checklist

Before marking a feature complete, verify every item:

**Data layer**
- [ ] No `try/catch` in data source — all error handling is in `ApiManager`
- [ ] No token/auth logic in data source — `AuthInterceptor` handles it
- [ ] All response models have `fromJson` + `toEntity()` and nothing else
- [ ] All request models omit null optional fields in `toJson()`

**Domain layer**
- [ ] Repository abstract returns only entities and primitives — no `*ResponseModel` types
- [ ] Use cases added only where Rule 4 applies; otherwise cubits call repo directly

**Presentation layer**
- [ ] All cubits are `@injectable` (factory), never `@lazySingleton`
- [ ] All states are `sealed class` extending `Equatable`
- [ ] Action and query state machines are in separate cubits (Rule 5) if feature has both
- [ ] All error messages go through `failureToMessage()` — no inline string literals
- [ ] Screens use `BlocListener` for side effects, `BlocBuilder` for rendering
- [ ] `BlocProvider` is created in `AppRouter`, not inside the screen widget
- [ ] All directional spacing uses `EdgeInsetsDirectional` — no `EdgeInsets.only(left/right: …)`
- [ ] Diagonal gradients use `AlignmentDirectional.topStart / bottomEnd` — no `Alignment.topLeft / bottomRight`
- [ ] Directional icons use standard Material icons (`Icons.chevron_right_rounded`, `Icons.arrow_back_rounded`) with no `isRtl` ternary (see §5)

**Layout**
- [ ] Screens with tall/variable content are wrapped in `SingleChildScrollView` or `CustomScrollView`
- [ ] Dynamic lists use `Expanded`, not `Container(height: X.h)`
- [ ] Text beside sibling widgets in `Row` uses `Flexible` + `TextOverflow.ellipsis`
- [ ] Book covers use `AspectRatio(2/3)`, not a fixed `.h`
- [ ] `SafeArea` applied at Scaffold body level on every screen
- [ ] Pinned bottom buttons use `Scaffold.bottomNavigationBar` + `SafeArea(top: false)`, not `Positioned`
- [ ] Bottom nav uses `SafeArea(top: false)` to clear the home indicator

**DI**
- [ ] After adding `@injectable` / `@lazySingleton` classes, run:
  `dart run build_runner build --delete-conflicting-outputs`
- [ ] Verify the new registrations appear in `injection_container.config.dart`

**Analysis**
- [ ] `flutter analyze` → No issues found

---

## 13. Anti-Patterns (Do Not Repeat)

The following patterns were found in other projects and features and must not appear
in this codebase:

| Anti-pattern | Why it's wrong | Correct approach |
|---|---|---|
| Token fetch + refresh in every data source method | 280+ lines of duplicate code; auth logic in wrong layer | `AuthInterceptor` handles it once |
| Domain repo returning `*ResponseModel` types | Domain leaks data-layer details; API changes break domain | Return entities from `toEntity()` |
| Repository impl that only delegates (zero transformation) | Adds files and ceremony with no value | Impl does real work: persists, maps, checks expiry |
| 13 trivial use case classes each wrapping one repo call | File count explodes; no benefit over direct repo call | Add use case only when Rule 4 applies |
| One cubit taking 9 constructor-injected use cases | Fragile DI, god-object cubit, unclear responsibility | Split into action cubit + query cubit |
| Error string literals inline in data source / cubit | Can't localize, can't change centrally | `failureToMessage()` in one file |
| Numbered comments (`// 1. Send Friend Request`) | Noise; file structure and method names carry this | Clean code, no redundant comments |
| `isRtl ? Icons.chevron_left : Icons.chevron_right` ternary | Fragile; pollutes every caller; `isRtl` variable noise throughout the file | Use `Icons.chevron_right_rounded` — `matchTextDirection` is baked into the `IconData`; the `Icon` widget mirrors automatically |
| `Alignment.topLeft / bottomRight` in gradients | Hard-coded LTR diagonal; gradient does not flip in RTL | `AlignmentDirectional.topStart / bottomEnd` |
| `EdgeInsets.only(left: …)` for insets | Does not mirror in RTL; content shifts wrong | `EdgeInsetsDirectional.only(start: …)` |
| Stacking fixed `.h` sections without scroll wrapper | Overflows on short phones or when keyboard opens | Wrap in `SingleChildScrollView` |
| `Container(height: X.h)` for a dynamic list | Fixed height overflows as list grows | `Expanded(child: list)` inside Scaffold body |
| `Positioned(bottom: 0)` for pinned buttons | Home indicator hides button; Scaffold body scroll unaware of it | `Scaffold.bottomNavigationBar` + `SafeArea(top: false)` |
| No `SafeArea` on a screen | Content renders behind notch or home indicator on real devices | `SafeArea` at Scaffold body level |
| Putting screen-specific components in `widgets/` | `widgets/` means shared across 2+ screens; non-shared components there mislead readers into thinking they are reusable | Put them in `pages/<screen_name>_screen/` next to the screen (see §1.1) |
| Creating a `states/` subfolder inside a screen folder | "states" already means cubit sealed classes in this codebase — naming collision causes confusion | Keep flat inside the screen folder; name by visual concern (`home_shimmer.dart`, `home_body.dart`) |
| Hardcoding strings in a single-language app | Adding a second language later requires touching every screen to externalize the strings | Use `.tr()` with a JSON key in every screen from day one; adding a language then only requires a new JSON file |
| Creating a commented skeleton file for a conditionally-needed artifact | Can be mistaken for "already implemented"; must be actively deleted if the condition never triggers; a dead file's comments are less reliably seen than a note in a file that is always read | Place a single marker comment in the nearest high-traffic file in the same layer |
