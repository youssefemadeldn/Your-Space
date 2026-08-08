using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class CityConfiguration : IEntityTypeConfiguration<City>
{
    public void Configure(EntityTypeBuilder<City> builder)
    {
        builder.HasKey(c => c.Id);

        builder.HasIndex(c => c.OwnerUserId);
        builder.HasIndex(c => c.GovernorateId);

        builder.HasOne(c => c.Owner)
            .WithMany()
            .HasForeignKey(c => c.OwnerUserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Restrict — a Governorate (even a locked/global one) can be the valid parent of many
        // user-owned Cities; CityService blocks deleting a Governorate while active Cities exist.
        builder.HasOne(c => c.Governorate)
            .WithMany()
            .HasForeignKey(c => c.GovernorateId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
