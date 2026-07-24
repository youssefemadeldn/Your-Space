---
name: P1-pagination
governed-by: dotnet_feature_prompt.md §1 (canonical file set) · templates/layers/T2-repository.md
---

# P1 — Pagination

**Trigger:** any list endpoint where the underlying table can grow past what's reasonable to return in one response — which in practice means *every* list endpoint; treat unpaginated list endpoints as the exception requiring justification, not the default.

---

## Request shape — `<Solution>.Repository/Specifications/Paginated/PaginationSpecification.cs`

```csharp
namespace <Solution>.Repository.Specifications.Paginated;

public class PaginationSpecification
{
    private const int MaxPageSize = 50;
    private int _pageSize = 10;

    public int PageIndex { get; set; } = 1;

    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = value > MaxPageSize ? MaxPageSize : value;
    }
}
```

## Response shape — `<Solution>.Services/Helper/PaginatedResultDto.cs`

```csharp
namespace <Solution>.Services.Helper;

public class PaginatedResultDto<T>
{
    public IReadOnlyList<T> Items { get; }
    public int PageIndex { get; }
    public int PageSize { get; }
    public int TotalItems { get; }
    public int TotalPages { get; }

    public PaginatedResultDto(IReadOnlyList<T> items, int pageIndex, int pageSize, int totalItems, int totalPages)
    {
        Items = items;
        PageIndex = pageIndex;
        PageSize = pageSize;
        TotalItems = totalItems;
        TotalPages = totalPages;
    }
}
```

## Using it in a service

```csharp
var repo = _unitOfWork.Repository<<Entity>, int>();
var spec = new <Entity>WithSpecs(search, pagination);

var items = await repo.ListAllWithSpecAsync(spec);
var totalItems = await repo.CountWithSpecAsync(spec);
var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);

return ServiceResult<PaginatedResultDto<<Entity>ProfileDto>>.Ok(
    new PaginatedResultDto<<Entity>ProfileDto>(_mapper.Map<IReadOnlyList<<Entity>ProfileDto>>(items),
        pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
```

---

## Notes

- **`PageSize` caps itself in the setter** — a caller passing `pageSize=100000` gets silently clamped to `MaxPageSize`, not an unbounded query. This is the one input-shape rule that's cheap enough to enforce in the DTO itself rather than a validator — but a validator rule rejecting an out-of-range `PageIndex`/`PageSize` outright (per `T5-validator.md`) is still the better choice for a public API where the caller should see an explicit 422, not silently-clamped behavior.
- **`CountWithSpecAsync` runs a second query** (same filter, no paging/includes) — for a filter that's expensive to evaluate (a multi-field `Contains` search across joined tables), this doubles the cost of every list call. If that becomes a measured problem, consider caching the total count briefly rather than recomputing it every request — don't do this preemptively before it's actually measured as a cost.
- **Same query-string parameter names on every list endpoint** (`pageIndex`, `pageSize`, plus whatever filters are specific to that feature) — a client integrating against a third list endpoint shouldn't have to learn a new pagination convention.
- List responses use `<Entity>ProfileDto`, never `<Entity>DetailsDto` (see `T4-dto.md`) — this matters more here than anywhere else, since it's the shape repeated across every row on every page.
