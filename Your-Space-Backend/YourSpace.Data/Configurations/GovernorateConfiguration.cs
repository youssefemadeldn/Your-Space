using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class GovernorateConfiguration : IEntityTypeConfiguration<Governorate>
{
    public void Configure(EntityTypeBuilder<Governorate> builder)
    {
        builder.HasKey(g => g.Id);

        builder.HasIndex(g => g.OwnerUserId);

        // Backs GovernorateWithSpecs's delta-sync "changes since" query
        // (doc/local-first-sync-design.md §6): WHERE (OwnerUserId IS NULL OR OwnerUserId = @p0)
        // AND SyncVersion > @p1, ORDER BY SyncVersion. Unlike Group's composite
        // (OwnerUserId, SyncVersion) index, a single-column index here is what the query actually
        // filters/sorts by — the predicate isn't a simple OwnerUserId equality (it's nullable-OR),
        // so a composite index with OwnerUserId leading wouldn't help the way it does for
        // always-owned entities; OwnerUserId already has its own index above for the
        // non-delta-sync visibility queries.
        builder.HasIndex(g => g.SyncVersion);

        // Shared/global reference governorates are keyed by their English Name (ReferenceDataSeeder
        // seeds them; MockDataSeeder's SeedCities/SeedPersons resolve them via
        // SingleAsync(g => g.OwnerUserId == null && g.Name == "...")). Filtered so it only constrains
        // the global rows — a user's own custom governorate may freely reuse any name.
        builder.HasIndex(g => g.Name)
            .IsUnique()
            .HasFilter("\"OwnerUserId\" IS NULL");

        // Optional — OwnerUserId is nullable, null means a shared/global seeded row with no owner.
        builder.HasOne(g => g.Owner)
            .WithMany()
            .HasForeignKey(g => g.OwnerUserId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
