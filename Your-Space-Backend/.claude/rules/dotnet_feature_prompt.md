# Backend — Feature/Module Scaffold Guide

> **Companion to `dotnet_scaffold_prompt.md`.**
> That file owns the foundation (project split, DI, error boundary, auth, config).
> This file owns adding one feature/module to an existing backend.
> `<Solution>` stands for the root name (e.g. `VetLink`); `<Feature>`/`<Entity>` stand for the feature being added (e.g. `Product`).

---

## 1. Canonical File Set

```
<Solution>.Data/
├── Entities/<Entity>.cs
└── Configurations/<Entity>Configurations.cs

<Solution>.Repository/
└── Specifications/<Feature>Specifications/
    └── <Entity>WithSpecs.cs                    # one class, multiple constructor overloads per query shape (§6)

<Solution>.Services/
└── Services/<Feature>Service/
    ├── I<Feature>Service.cs
    ├── <Feature>Service.cs
    └── Dtos/
        ├── Create<Entity>Dto.cs
        ├── Update<Entity>Dto.cs
        ├── <Entity>DetailsDto.cs                # single-item response shape
        └── <Entity>ProfileDto.cs                # list-row response shape — never reuse DetailsDto for list rows
    Validators/
    ├── Create<Entity>DtoValidator.cs
    └── Update<Entity>DtoValidator.cs

<Solution>.WebAPI/
└── Controllers/<Feature>Controller.cs

<Solution>.WebAPI.Tests/
├── Unit/Services/<Feature>Service/
│   └── <Feature>Service_<Method>Tests.cs        # one file per method under test
└── Integration/Controllers/<Feature>ControllerTests.cs
```

**Rule:** never add an empty folder speculatively. Only create `Validators/Update<Entity>DtoValidator.cs` if an update endpoint actually exists; only create a background job file if the feature actually has recurring/scheduled work (see `templates/layers/T7-background-job.md`).

**Rule 8 reminder:** any entity field in this file set that holds user-facing text (not an internal code/slug/enum) gets an `<Field>Ar` counterpart on the entity, in the same migration — see Rule 8 and `templates/layers/T1-entity.md`.

---

## 2. The Non-Negotiable Rules

### Rule 1 — One error boundary: guard clauses, not catch-and-swallow

Service methods return the specific `ServiceResult` failure directly for expected outcomes. They do not wrap the whole method in `try/catch (Exception ex)` to log and return a generic failure — that duplicates `ExceptionMiddleware` and buries expected outcomes inside exception handling.

**Correct:**
```csharp
public async Task<ServiceResult<ProductDetailsDto>> GetDetailsAsync(int id)
{
    var repo = _unitOfWork.Repository<Product, int>();
    var product = await repo.GetByIdWithSpecAsync(new ProductWithSpecs(id));

    if (product is null)
    {
        _logger.LogWarning("Product {ProductId} not found", id);
        return ServiceResult<ProductDetailsDto>.NotFound(_localizer["Product.NotFound", id]);   // see Rule 8
    }

    return ServiceResult<ProductDetailsDto>.Ok(_mapper.Map<ProductDetailsDto>(product));
}
```

**Wrong — never do this:**
```csharp
// ❌ Whole-method try/catch swallowing every exception into a generic failure — violates Rule 1
public async Task<ServiceResult<ProductDetailsDto>> GetDetailsAsync(int id)
{
    try
    {
        var product = await _unitOfWork.Repository<Product, int>().GetByIdAsync(id);
        if (product == null) return ServiceResult<ProductDetailsDto>.NotFound("Not found");
        return ServiceResult<ProductDetailsDto>.Ok(_mapper.Map<ProductDetailsDto>(product));
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error getting product");
        return ServiceResult<ProductDetailsDto>.ServerError("An error occurred");
    }
}
```

If an operation genuinely needs richer log context than the middleware alone can provide (e.g. which external API call failed mid-operation), catch narrowly, log with context, and **rethrow** — never swallow:
```csharp
try
{
    await _paymentGateway.CaptureAsync(orderId);
}
catch (Exception ex)
{
    _logger.LogError(ex, "Payment capture failed for order {OrderId}", orderId);
    throw; // ExceptionMiddleware still decides the HTTP response
}
```

---

### Rule 2 — Every mutating DTO has a validator

`CreateProductDtoValidator`, `UpdateProductDtoValidator`, etc. live in `Validators/` and are picked up automatically by the assembly scan already wired in `ServiceRegistration`. No manual per-validator registration, and no manual shape-checks in the service.

**Correct:**
```csharp
public class CreateProductDtoValidator : AbstractValidator<CreateProductDto>
{
    public CreateProductDtoValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Price).GreaterThan(0);
        RuleFor(x => x.CategoryId).GreaterThan(0);
    }
}
```

**Wrong:**
```csharp
// ❌ Manual shape-checking in the service — this belongs in a validator, and nothing enforces
// it runs for every caller the way the global FluentValidation pipeline does
public async Task<ServiceResult<ProductDetailsDto>> CreateAsync(CreateProductDto dto)
{
    if (dto == null) return ServiceResult<ProductDetailsDto>.Fail("Invalid product data");
    if (string.IsNullOrEmpty(dto.Name)) return ServiceResult<ProductDetailsDto>.Fail("Name required");
    // ...
}
```

A service guard clause is still correct for a **domain invariant** a validator can't see (e.g. "this SKU already exists for this seller") — that's a database-dependent business rule, not input shape, and validators shouldn't reach into the database to check it.

---

### Rule 3 — Generic repository stays generic

`IGenericRepository<TEntity,TKey>` never grows a method that only makes sense for one entity. Domain-specific data operations go on `IUnitOfWork` directly or a dedicated repository interface for that aggregate.

**Correct:**
```csharp
// IUnitOfWork — a cross-cutting, atomic operation, not tied to the generic contract
Task<bool> TryDecrementStockAsync(int productId, int quantity);
```

**Wrong:**
```csharp
// ❌ IGenericRepository<TEntity, TKey> — every entity type now nominally exposes this,
// even though it only makes sense for Order
Task<string> GenerateOrderNumberAsync();
```

---

### Rule 4 — DTOs never leak persistence types

A DTO under `Services/**/Dtos/` never references `Microsoft.EntityFrameworkCore` or `<Solution>.Data.Entities`. Mapping from entity to DTO happens once, in the service, via AutoMapper or an explicit `Map` call.

**Correct:**
```csharp
public class ProductDetailsDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public List<ImageDto> Images { get; set; } = new();
}
```

**Wrong:**
```csharp
// ❌ DTO exposes the entity type directly — violates Rule 4, and will fail the
// architecture test that checks Dtos namespaces for EF Core / entity references
public class ProductDetailsDto
{
    public Product Product { get; set; }   // entity leaking straight into the transport contract
}
```

---

### Rule 5 — Transactions wrap multi-step writes

Any operation writing to more than one table where a partial write would corrupt state uses an explicit transaction. Commit catches, rolls back, and rethrows — never swallows.

**Correct:**
```csharp
await using var transaction = await _unitOfWork.BeginTransactionAsync();
try
{
    imageRepo.Delete(oldImage);
    await imageRepo.AddRangeAsync(newImages);
    await _unitOfWork.SaveChangesAsync();
    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
```

See `patterns/P3-transactional-write.md` for the full pattern including the retry-strategy caveat.

---

### Rule 6 — Every mutating endpoint has explicit authorization

No controller action that mutates state ships without an `[Authorize]` (role or policy) unless the endpoint is deliberately public — and "deliberately public" is a decision stated in a code comment, not silence.

**Correct:**
```csharp
[HttpPost]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> CreateProduct([FromBody] CreateProductDto dto)
{
    var result = await _productService.CreateAsync(dto);
    return new ResultActionResult<ProductDetailsDto>(result);
}
```

**Wrong:**
```csharp
[HttpPost("reviews")]
//[Authorize(Roles = "Buyer")]   // ❌ commented out — this is a shipped authorization gap, not a style nit
public async Task<IActionResult> AddReview([FromBody] AddReviewDto dto) { ... }
```

When a claim alone can't express the rule (e.g. status can change in the database after the JWT was issued), use a custom `IAuthorizationRequirement` + handler that checks live state — don't stretch a role claim to cover something it structurally can't.

---

### Rule 7 — Logging is mandatory and structured

Every service constructor takes `ILogger<TService>`. See CLAUDE.md "Logging" for the Information/Warning/Error rules — this is not optional per-feature.

**Correct:**
```csharp
_logger.LogInformation("Creating product {ProductName} for seller {SellerId}", dto.Name, sellerId);
```

**Wrong:**
```csharp
_logger.LogInformation($"Creating product {dto.Name}");   // ❌ interpolated string — not queryable by field
```

---

### Rule 8 — Every user-facing string ships bilingual (EN/AR) from the moment it's created

Any entity field, DTO field, or service/validator message a client can see is built with English/Arabic support the moment it's created — not added later once someone actually asks for translation (CLAUDE.md Architecture rule 8).

**Correct — entity + mapping resolve to one field:**
```csharp
// Entity
public required string Name { get; set; }
public string? NameAr { get; set; }

// AutoMapper profile — resolves to ONE field; the client never sees both
CreateMap<Product, ProductDetailsDto>()
    .ForMember(d => d.Name, opt => opt.MapFrom(s =>
        CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar" && !string.IsNullOrEmpty(s.NameAr)
            ? s.NameAr
            : s.Name));
```

**Correct — messages come from the localizer:**
```csharp
public class CreateProductDtoValidator : AbstractValidator<CreateProductDto>
{
    public CreateProductDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Name).NotEmpty().WithMessage(localizer["Product.Name.Required"]);
    }
}

// Service
return ServiceResult<ProductDetailsDto>.NotFound(_localizer["Product.NotFound"]);
```

**Wrong — never do this:**
```csharp
// ❌ Entity has no Ar counterpart — retrofitting later means a migration plus backfilling every row
public required string Name { get; set; }

// ❌ Hardcoded English literal — looks localized because Accept-Language is wired in the pipeline,
// but the message itself never actually changes with culture
RuleFor(x => x.Name).NotEmpty().WithMessage("Name is required");
return ServiceResult<ProductDetailsDto>.NotFound("Product not found");
```

See CLAUDE.md "Localization" and `templates/layers/T1-entity.md`, `T4-dto.md`, `T5-validator.md`.

---

## 3. Response Model Rules

- **`<Entity>DetailsDto`** — single-item shape, used by get-by-id and create/update responses. Include navigation data the client actually renders (images, category name) — not raw foreign keys the client can't use.
- **`<Entity>ProfileDto`** — list-row shape, deliberately smaller than `DetailsDto`. Never reuse the details DTO for a paginated list response — list endpoints are called far more often and the extra fields are wasted bandwidth at scale.
- Request DTOs (`Create<Entity>Dto`, `Update<Entity>Dto`) carry only the fields the caller may set — never a server-assigned field like `Id` (on create), `CreatedAt`, or `RowVersion`.
- **A response DTO exposes one resolved language field, never a raw `Name`/`NameAr` pair.** The AutoMapper profile picks the right value based on `CultureInfo.CurrentUICulture` at mapping time (Rule 8) — the client never branches on locale itself.

---

## 4. Specification Rules

- One `<Entity>WithSpecs` class per entity, multiple constructors for different query shapes (by id, by SKU, paginated list with filters, etc.) — see `templates/layers/T2-repository.md`.
- **Shared predicate/include logic across overloads must be extracted, not copy-pasted.** If three constructors all filter on the same multi-field search expression, factor it into a private static method or a composable `Expression<Func<T,bool>>` builder called from each constructor.
- Every specification for a soft-deletable entity filters `DeletedAt == null` (or relies on a global EF Core query filter — see `patterns/P2-soft-delete-and-concurrency.md`).
- A short-lived, low-entropy secret (a 6-digit OTP/verification code for email confirmation, password reset, phone verification, 2FA, ...) is never looked up by a hash-uniqueness index the way a high-entropy token (`RefreshToken`) is — its hash can collide across users/requests. The specification resolves `(UserId, not-yet-consumed)` first; the presented value's hash is compared only after that, in application code — see `patterns/P4-hashed-verification-code.md` for the full entity/spec/service shape.

---

## 5. Background Work — Hosted Service vs. Fire-and-Forget

Decide per operation, using this test:

| Question | If yes → |
|---|---|
| Does it run on a recurring schedule, or must it survive a process restart? | `IHostedService` (see `templates/layers/T7-background-job.md`) |
| Would losing it silently matter to the business (payment confirmation, an order state transition)? | `IHostedService` or a durable queue — never fire-and-forget |
| Is it a genuinely best-effort side effect (an admin notification email) where silent loss is acceptable and logged? | Fire-and-forget `Task.Run` with its own `IServiceScopeFactory`-created scope, wrapped in its own try/catch that only logs |

Never default to `Task.Run` out of convenience for something that belongs in the first two rows.

---

## 6. Pre-Ship Checklist

Before marking a feature complete, verify every item:

**Data layer**
- [ ] Entity has `CreatedAt`/`UpdatedAt` (and `DeletedAt` if soft-deletable, `RowVersion` if written concurrently)
- [ ] Configuration class declares keys, indexes (including composite indexes for real query patterns), and relationship delete behavior explicitly
- [ ] Every user-facing text field has an `<Field>Ar` counterpart, and the AutoMapper profile resolves it to one DTO field by `CultureInfo.CurrentUICulture` (Rule 8)

**Repository layer**
- [ ] No domain-specific method added to `IGenericRepository<,>` (Rule 3)
- [ ] Specification constructors share predicate logic instead of duplicating it (§4)
- [ ] If this feature includes an OTP/verification code, it's looked up by `(UserId, not-yet-consumed)`, never by its hash (§4, `patterns/P4-hashed-verification-code.md`)

**Service layer**
- [ ] No whole-method `try/catch` swallowing exceptions into a generic failure (Rule 1)
- [ ] `ILogger<TService>` injected and used per CLAUDE.md's Information/Warning/Error rules (Rule 7)
- [ ] Multi-step writes across tables are transaction-wrapped (Rule 5)
- [ ] DTOs contain no EF Core / entity references (Rule 4)

**Validation**
- [ ] Every mutating DTO has a validator class (Rule 2)
- [ ] No manual shape-checking left in the service for anything the validator now owns
- [ ] Every `ServiceResult`/validator message comes from `IStringLocalizer<SharedResource>`, not a hardcoded string literal (Rule 8), with both `.resx` files updated in the same commit

**API layer**
- [ ] Every mutating endpoint has an explicit `[Authorize]` or a stated reason it's public (Rule 6)
- [ ] Controller only parses input, calls one service method, and wraps the result — no branching on `result.Success`

**Tests**
- [ ] Unit tests exist per service method (`<Feature>Service_<Method>Tests.cs`)
- [ ] A regression test exists for any bug this feature fixes
- [ ] Architecture tests still pass (layer boundaries, DTO/entity separation)

**Dependencies & config**
- [ ] No new package added without an active call site
- [ ] No secret added to `appsettings*.json`

---

## 7. Anti-Patterns (Do Not Repeat)

The following patterns were found in real production audits and must not appear in new code:

| Anti-pattern | Why it's wrong | Correct approach |
|---|---|---|
| Whole-method `try/catch` that logs and returns a generic failure, repeated in nearly every service method | Duplicates the exception boundary middleware already provides; buries expected outcomes (not-found, conflict) inside exception handling; dozens of near-identical catch blocks is pure repetition | Guard clauses return the specific `ServiceResult` failure directly (Rule 1); let unexpected exceptions bubble to `ExceptionMiddleware` |
| Two `IActionResult` wrapper classes with different names doing identical `StatusCode`-from-`ServiceResult` work | Pure duplication with no behavioral difference; splits the codebase into two conventions for the same job, for no reason | Exactly one `ResultActionResult<T>` / `ResultActionResult` |
| A domain-specific method (e.g. a formatted sequence-number generator) added directly to the generic repository interface | Every entity type now nominally exposes a method that only makes sense for one of them | Put it on `IUnitOfWork` or a dedicated repository interface (Rule 3) |
| The same multi-field search predicate copy-pasted across several specification constructor overloads | A typo fix or business-rule change now has to be applied N times; overloads silently drift out of sync | Extract the shared predicate into one place, called from every overload (§4) |
| Looking up a low-entropy secret (a 6-digit OTP/verification code) by a hash-uniqueness index, the way a high-entropy `RefreshToken` is | A 6-digit code has only 1,000,000 possible values — its hash *will* collide across users/requests at real scale, unlike a 64-byte random token's hash | Look up the active row by `(UserId, not-yet-consumed)` first, then compare the presented code's hash in application code with a constant-time comparison (§4, `patterns/P4-hashed-verification-code.md`) |
| FluentValidation wired globally, but most DTOs have no validator class, so mutating endpoints fall back to ad hoc `if`-checks or nothing | Coverage looks systematic (one global registration call) but is actually sparse and inconsistent per endpoint | Every mutating DTO gets a validator the moment it's created — no validator is an incomplete feature, not an optional extra (Rule 2) |
| `[Authorize]` commented out "temporarily" while testing | Ships as a live authorization gap the moment the branch merges; easy to forget, easy to miss in review | Never comment out an authorization attribute — use a role/policy actually satisfiable in the test environment instead (Rule 6) |
| A fully-referenced third-party package with zero call sites anywhere in the codebase | Dead weight in the dependency tree and build; misleads readers into thinking it's in active use | Remove a package the moment its last call site is removed — a `.csproj` reference is not free |
| A misspelled type/namespace/method name that ships and gets referenced elsewhere (`Extentions`, `Pirority`, `TicketReplay`) | The typo becomes part of the public shape of the code the moment something else references it; fixing it later is a breaking rename, not a one-line correction | Catch spelling in review before merge |
| Leftover PR-review-artifact comments (`// FIXED: already has X`, `// Critical Issue #3`) left in merged code | Reads as unresolved to the next person touching the file; noise unrelated to why the code is the way it is | Resolve the review conversation, then delete the comment |
| Secrets (DB password, signing key, third-party API key) committed directly in a tracked `appsettings.json` | Every clone — and every remote it's pushed to — now has the real credential in history; gitignoring afterward doesn't remove what's already committed | `dotnet user-secrets` locally, environment variables/secrets manager in deployed environments; rotate anything ever committed |
| A per-request `Scoped` service injected directly into a `Singleton` constructor | The scoped instance is captured once and lives for the app's lifetime — a captive-dependency bug that surfaces as stale or cross-request data | Singletons needing scoped data take `IServiceScopeFactory` and create a scope per use |
| Recurring or business-critical work implemented as fire-and-forget `Task.Run` instead of a hosted service or durable queue | No retry, no observability if the process recycles mid-run, silently drops the work on deploy | `IHostedService` for recurring/critical work; fire-and-forget reserved for genuinely best-effort side effects (§5) |
| `ServiceResult`/validator messages hardcoded as English string literals while `Accept-Language`/`RequestLocalization` is wired in the pipeline | Looks localized because the middleware is there, but no message actually changes with culture — a real gap observed in a reference project's audit | Every message string comes from `IStringLocalizer<SharedResource>`, keyed and translated in both `.resx` files at creation time (Rule 8) |
| A new entity's user-facing text field added without an `Ar` counterpart, "to add later when needed" | Retrofitting means a migration plus backfilling every existing row's `Ar` value — cheap now, expensive later | Add `<Field>Ar` alongside `<Field>` in the same migration that introduces the field (Rule 8) |
