using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class NeighborhoodConfiguration : IEntityTypeConfiguration<Neighborhood>
{
    public void Configure(EntityTypeBuilder<Neighborhood> builder)
    {
        builder.HasKey(n => n.Id);

        builder.HasIndex(n => n.OwnerUserId);
        builder.HasIndex(n => n.CityId);

        // Backs NeighborhoodWithSpecs's delta-sync "changes since" query
        // (doc/local-first-sync-design.md §6): WHERE OwnerUserId = @p0 AND SyncVersion > @p1,
        // ORDER BY SyncVersion.
        builder.HasIndex(n => new { n.OwnerUserId, n.SyncVersion });

        builder.HasOne(n => n.Owner)
            .WithMany()
            .HasForeignKey(n => n.OwnerUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(n => n.City)
            .WithMany()
            .HasForeignKey(n => n.CityId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
