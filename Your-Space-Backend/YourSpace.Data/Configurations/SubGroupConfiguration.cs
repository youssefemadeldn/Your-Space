using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class SubGroupConfiguration : IEntityTypeConfiguration<SubGroup>
{
    public void Configure(EntityTypeBuilder<SubGroup> builder)
    {
        builder.HasKey(s => s.Id);

        builder.HasIndex(s => s.OwnerUserId);
        builder.HasIndex(s => s.GroupId);

        // Delta-sync "changes since" query (doc/local-first-sync-design.md §6, row 8.17):
        // WHERE OwnerUserId = @p0 AND SyncVersion > @p1, ORDER BY SyncVersion.
        builder.HasIndex(s => new { s.OwnerUserId, s.SyncVersion });

        builder.HasOne(s => s.Owner)
            .WithMany()
            .HasForeignKey(s => s.OwnerUserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Restrict — SubGroupService blocks deleting a group's subgroup while active Persons still
        // reference it (a DB-dependent guard clause), same rationale as Person -> Group.
        builder.HasOne(s => s.Group)
            .WithMany()
            .HasForeignKey(s => s.GroupId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
