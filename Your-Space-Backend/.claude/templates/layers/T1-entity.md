---
name: T1-entity
governed-by: CLAUDE.md "Architecture" (Data project layout) · CLAUDE.md Architecture rule 4 · CLAUDE.md Architecture rule 8 ("Localization") · CLAUDE.md Architecture rule 9 ("Development Data Seeding") · patterns/P2-soft-delete-and-concurrency.md
---

# T1 — Entity + EF Core Configuration

Two files per entity. Replace all `<Placeholder>` tokens before use.

---

## Entity — `<Solution>.Data/Entities/<Entity>.cs`

```csharp
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace <Solution>.Data.Entities;

public class <Entity>
{
    public int Id { get; set; }

    public required string Name { get; set; }
    public string? NameAr { get; set; }   // nullable — falls back to Name when absent; see CLAUDE.md "Localization"

    [Column(TypeName = "decimal(10,2)")]
    public decimal <PriceOrAmount> { get; set; }

    // Only add if this entity is ever soft-deleted rather than hard-deleted — see patterns/P2.
    public DateTime? DeletedAt { get; set; }

    // Only add if this entity is written under contention (stock counts, balances, status flips).
    [ConcurrencyCheck]
    public byte[] RowVersion { get; set; } = Array.Empty<byte>();

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties — set up the FK side in the configuration, not here.
    public <RelatedEntity> <RelatedEntity>? { get; set; }
}
```

---

## Configuration — `<Solution>.Data/Configurations/<Entity>Configurations.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using <Solution>.Data.Entities;

namespace <Solution>.Data.Configurations;

public class <Entity>Configurations : IEntityTypeConfiguration<<Entity>>
{
    public void Configure(EntityTypeBuilder<<Entity>> builder)
    {
        builder.HasKey(x => x.Id);

        // Index every FK and every column used in a WHERE/ORDER BY across the app's real query patterns —
        // add composite indexes for combinations that are actually queried together (e.g. seller + isActive list views).
        builder.HasIndex(x => x.<CommonlyFilteredColumn>);
        builder.HasIndex(x => new { x.<ColumnA>, x.<ColumnB> });

        builder.HasOne(x => x.<RelatedEntity>)
            .WithMany(r => r.<Entities>)
            .HasForeignKey(x => x.<RelatedEntity>Id)
            .OnDelete(DeleteBehavior.Cascade); // pick Restrict/SetNull deliberately if cascading delete is wrong here

        // Only add if this entity is soft-deletable (see patterns/P2) — makes the DeletedAt == null
        // filter automatic instead of repeated in every specification:
        // builder.HasQueryFilter(x => x.DeletedAt == null);
    }
}
```

---

## Notes

- **Scalar constraints via data annotations, relationships/indexes via Fluent API** — never `[ForeignKey]`/`[Index]` attributes on the entity itself; keep all relationship/index knowledge in the configuration class where it's easy to audit in one place per entity.
- **User-facing text fields are bilingual from creation, not internal-only ones** — `Name` (default/English) plus a nullable `NameAr`, same pattern for any other user-facing text field (`Description`/`DescriptionAr`, etc.). Internal-only fields (slugs, codes, enums) don't need an `Ar` counterpart. See CLAUDE.md "Localization" and `dotnet_feature_prompt.md` Rule 8.
- **`DeletedAt` and `RowVersion` are opt-in, not default** — add them only when the feature actually needs soft-delete or concurrency-safe writes. Adding both unconditionally to every entity is premature generalization; an entity that's genuinely hard-deleted and never written concurrently doesn't need either.
- **`HasQueryFilter` vs. manual `DeletedAt == null` in every specification** — a global query filter removes the chance of forgetting the filter in a new specification, but it also silently excludes soft-deleted rows from *every* query including ones that might legitimately want them (an admin "restore" screen). Decide once per entity and document the choice in the configuration class's comment; don't mix both approaches for the same entity.
- **Migrations:** after adding or changing an entity/configuration, run `dotnet ef migrations add <Description> --project <Solution>.Data --startup-project <Solution>.WebAPI` and review the generated migration before applying it — EF Core's diff is usually right but not infallible, especially around index/rename detection.
- **Seed data:** add a matching `Seed<Entity>Async` method to `<Solution>.WebAPI/Helpers/MockDataSeeder.cs` in the same change — a normal case plus at least one edge case (empty/max-length text, a boundary numeric value, a soft-deleted row if this entity supports it). See CLAUDE.md "Development Data Seeding" and `dotnet_feature_prompt.md` Rule 9.
