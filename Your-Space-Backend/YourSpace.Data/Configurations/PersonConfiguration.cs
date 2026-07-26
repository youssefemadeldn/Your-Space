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
    }
}
