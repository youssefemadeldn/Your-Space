using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class EventConfiguration : IEntityTypeConfiguration<Event>
{
    public void Configure(EntityTypeBuilder<Event> builder)
    {
        builder.HasKey(e => e.Id);

        builder.HasIndex(e => e.OwnerUserId);

        // Backs EventWithSpecs's delta-sync "changes since" query (doc/local-first-sync-design.md
        // §6): WHERE OwnerUserId = @p0 AND SyncVersion > @p1, ORDER BY SyncVersion.
        builder.HasIndex(e => new { e.OwnerUserId, e.SyncVersion });

        builder.HasOne(e => e.Owner)
            .WithMany()
            .HasForeignKey(e => e.OwnerUserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
