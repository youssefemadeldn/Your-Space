---
name: T2-repository
governed-by: CLAUDE.md Architecture rules 1 & 3 · dotnet_feature_prompt.md Rule 3 & §4
---

# T2 — Specification (+ generic repository usage)

The generic `IGenericRepository<TEntity,TKey>`/`IUnitOfWork` already exist from scaffolding (`dotnet_scaffold_prompt.md`) — a feature almost never adds new repository *methods*, it adds new **specifications**.

---

## Specification — `<Solution>.Repository/Specifications/<Feature>Specifications/<Entity>WithSpecs.cs`

```csharp
using System.Linq.Expressions;
using <Solution>.Data.Entities;
using <Solution>.Repository.Specifications.Paginated;

namespace <Solution>.Repository.Specifications.<Feature>Specifications;

public class <Entity>WithSpecs : BaseSpecification<<Entity>>
{
    // By id — single item, with the includes a details view needs.
    public <Entity>WithSpecs(int id)
        : base(x => x.Id == id && x.DeletedAt == null)
    {
        AddInclude(x => x.<RelatedEntity>);
    }

    // Paginated list with optional search/filters — shares the predicate builder below
    // instead of repeating the same expression in every list-shaped overload.
    public <Entity>WithSpecs(string? search, int? <filterId>, PaginationSpecification paging)
        : base(BuildListPredicate(search, <filterId>))
    {
        AddInclude(x => x.<RelatedEntity>);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
        ApplyOrderByDescending(x => x.CreatedAt);
    }

    // Add further constructors for other real query shapes (by owner, by external code, …) —
    // each one calls BuildListPredicate (or a similarly-extracted helper) rather than
    // rewriting the search expression inline.

    private static Expression<Func<<Entity>, bool>> BuildListPredicate(string? search, int? <filterId>)
        => x => x.DeletedAt == null
            && (!<filterId>.HasValue || x.<FilterColumn>Id == <filterId>)
            && (string.IsNullOrWhiteSpace(search)
                || x.Name.Contains(search)
                || (x.NameAr != null && x.NameAr.Contains(search)));
}
```

## Using it from a service

```csharp
var repo = _unitOfWork.Repository<<Entity>, int>();
var spec = new <Entity>WithSpecs(id);
var entity = await repo.GetByIdWithSpecAsync(spec);
```

---

## Notes

- **Every constructor overload calls the shared predicate builder** (`BuildListPredicate` above) instead of copy-pasting the search expression — this is the fix for the most common specification anti-pattern (see `dotnet_feature_prompt.md` §7 anti-patterns table). If two overloads' predicates genuinely diverge, that's a sign they're not actually variations of the same query shape — consider whether they belong in two differently-named specification classes instead of two constructors on one.
- **A feature adds a repository *method* only when the operation cannot be expressed as a specification** — an atomic update (`ExecuteUpdateAsync` with a guard predicate) or a raw-SQL sequence read are the two legitimate cases, and both belong on `IUnitOfWork`, never on `IGenericRepository<TEntity,TKey>` (Rule 3).
- **Architecture test to add/extend** (whole-solution version, in `WebAPI.Tests/Architecture/ArchitectureLayeringTests.cs`, seeded during scaffolding):
  ```csharp
  [Fact]
  public void Repository_assembly_does_not_depend_on_Services()
  {
      var result = Types.InAssembly(typeof(GenericRepository<,>).Assembly)
          .Should()
          .NotHaveDependencyOn("<Solution>.Services")
          .GetResult();
      result.IsSuccessful.Should().BeTrue(
          "Repository must stay below Services in the layer direction. " + result);
  }
  ```
  Every new feature's specifications live inside `<Solution>.Repository` — if a specification ever needs something from `<Solution>.Services`, that's a sign the logic belongs in the service layer, not the specification.
