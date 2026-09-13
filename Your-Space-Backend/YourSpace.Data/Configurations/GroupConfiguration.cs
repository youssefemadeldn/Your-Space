using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class GroupConfiguration : IEntityTypeConfiguration<Group>
{
    public void Configure(EntityTypeBuilder<Group> builder)
    {
        builder.HasKey(g => g.Id);

        builder.HasIndex(g => g.OwnerUserId);

        // Backs GroupWithSpecs's delta-sync "changes since" query (doc/local-first-sync-design.md
        // §6): WHERE OwnerUserId = @p0 AND SyncVersion > @p1, ORDER BY SyncVersion.
        builder.HasIndex(g => new { g.OwnerUserId, g.SyncVersion });

        builder.HasOne(g => g.Owner)
            .WithMany()
            .HasForeignKey(g => g.OwnerUserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
