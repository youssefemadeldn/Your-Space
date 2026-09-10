using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class PersonConfiguration : IEntityTypeConfiguration<Person>
{
    public void Configure(EntityTypeBuilder<Person> builder)
    {
        builder.HasKey(p => p.Id);

        builder.HasIndex(p => p.OwnerUserId);
        builder.HasIndex(p => new { p.OwnerUserId, p.GroupId });
        builder.HasIndex(p => new { p.OwnerUserId, p.SubGroupId });
        builder.HasIndex(p => new { p.OwnerUserId, p.GovernorateId });

        builder.HasOne(p => p.Owner)
            .WithMany()
            .HasForeignKey(p => p.OwnerUserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Restrict — a Group is master data potentially referenced by many independent Persons;
        // deleting a group is blocked in GroupService while active Persons still reference it
        // (a DB-dependent guard clause, not something a Restrict alone or a validator can express).
        builder.HasOne(p => p.Group)
            .WithMany()
            .HasForeignKey(p => p.GroupId)
            .OnDelete(DeleteBehavior.Restrict);

        // Same Restrict rationale as Group above — each parent's own service blocks deletion while
        // active Persons still reference it.
        builder.HasOne(p => p.SubGroup)
            .WithMany()
            .HasForeignKey(p => p.SubGroupId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(p => p.Governorate)
            .WithMany()
            .HasForeignKey(p => p.GovernorateId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(p => p.City)
            .WithMany()
            .HasForeignKey(p => p.CityId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(p => p.Neighborhood)
            .WithMany()
            .HasForeignKey(p => p.NeighborhoodId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
