using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class PersonImageConfiguration : IEntityTypeConfiguration<PersonImage>
{
    public void Configure(EntityTypeBuilder<PersonImage> builder)
    {
        builder.HasKey(i => i.Id);

        // Two distinct indexes on the same property — EF Core treats repeated HasIndex(...) calls on an
        // identical property list as configuring the *same* index unless the name is passed into
        // HasIndex itself (a later .HasDatabaseName() call on a second HasIndex(...) call just renames/
        // re-configures the first one instead of creating a second index).
        builder.HasIndex(i => i.PersonId, "IX_PersonImages_PersonId");

        // At most one primary photo per person, enforced at the DB level (not just in-service) via a
        // partial unique index — Postgres-specific HasFilter syntax, fine given this project is pinned
        // to Npgsql; would need reworking if the provider ever changed.
        builder.HasIndex(i => i.PersonId, "IX_PersonImages_PersonId_OnePrimary")
            .IsUnique()
            .HasFilter("\"IsPrimary\" = true");

        builder.HasOne(i => i.Person)
            .WithMany()
            .HasForeignKey(i => i.PersonId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
