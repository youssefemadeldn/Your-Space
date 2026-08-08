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

        // Optional — OwnerUserId is nullable, null means a shared/global seeded row with no owner.
        builder.HasOne(g => g.Owner)
            .WithMany()
            .HasForeignKey(g => g.OwnerUserId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
