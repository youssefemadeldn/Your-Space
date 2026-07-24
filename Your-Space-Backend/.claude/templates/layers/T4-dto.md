---
name: T4-dto
governed-by: CLAUDE.md Architecture rule 4 · dotnet_feature_prompt.md Rule 4 & §3
---

# T4 — Request/Response DTOs

All in `<Solution>.Services/Services/<Feature>Service/Dtos/`. Plain classes — no EF Core, no entity references, no business logic.

---

## Create request — `Create<Entity>Dto.cs`

```csharp
namespace <Solution>.Services.Services.<Feature>Service.Dtos;

public class Create<Entity>Dto
{
    public required string Name { get; set; }
    public decimal <PriceOrAmount> { get; set; }
    public int <RelatedEntity>Id { get; set; }
    // Never a server-assigned field here: no Id, no CreatedAt, no RowVersion.
}
```

## Update request — `Update<Entity>Dto.cs`

```csharp
namespace <Solution>.Services.Services.<Feature>Service.Dtos;

public class Update<Entity>Dto
{
    public required int Id { get; set; }   // the only server-known field a caller supplies, to identify the target
    public string? Name { get; set; }
    public decimal? <PriceOrAmount> { get; set; }
    // Nullable fields = "leave unchanged if omitted" — decide this convention once and apply it
    // consistently; don't mix "null means unchanged" and "null means clear" across DTOs.
}
```

## Single-item response — `<Entity>DetailsDto.cs`

```csharp
namespace <Solution>.Services.Services.<Feature>Service.Dtos;

public class <Entity>DetailsDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal <PriceOrAmount> { get; set; }
    public List<ImageDto> Images { get; set; } = new();   // rendered navigation data, not raw FKs
}
```

## List-row response — `<Entity>ProfileDto.cs`

```csharp
namespace <Solution>.Services.Services.<Feature>Service.Dtos;

public class <Entity>ProfileDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal <PriceOrAmount> { get; set; }
    public string? ThumbnailUrl { get; set; }   // deliberately smaller than DetailsDto
}
```

---

## Notes

- **`<Entity>DetailsDto` and `<Entity>ProfileDto` are never the same class** — a list endpoint that's actually returning the full details shape is sending unused fields over the wire on every single row, at whatever the list's page size is.
- **AutoMapper profile:** one `Profile` class per feature (`<Feature>Profile.cs`) mapping `<Entity>` → `<Entity>DetailsDto`/`<Entity>ProfileDto`, and `Create<Entity>Dto`/`Update<Entity>Dto` → `<Entity>`. Keep transformation logic (formatting, conditional fields) in the profile or the service, never in the DTO itself — a DTO is a data shape, not a place for behavior.
- **Architecture test to add/extend** (whole-solution version, in `WebAPI.Tests/Architecture/ArchitectureLayeringTests.cs`, seeded during scaffolding):
  ```csharp
  [Fact]
  public void Dtos_do_not_reference_EF_Core_or_entities()
  {
      var result = Types.InAssembly(typeof(<Entity>DetailsDto).Assembly)
          .That()
          .ResideInNamespace("<Solution>.Services.Services.<Feature>Service.Dtos")
          .Should()
          .NotHaveDependencyOnAll("Microsoft.EntityFrameworkCore", "<Solution>.Data.Entities")
          .GetResult();
      result.IsSuccessful.Should().BeTrue(
          "DTOs are transport-only, not persistence-aware. " + result);
  }
  ```
  Run this for every feature's `Dtos` namespace, not just one — a single subsystem passing this test while others don't is a false sense of safety.
