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
