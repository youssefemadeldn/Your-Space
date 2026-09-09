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
