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

        builder.HasOne(g => g.Owner)
            .WithMany()
            .HasForeignKey(g => g.OwnerUserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
