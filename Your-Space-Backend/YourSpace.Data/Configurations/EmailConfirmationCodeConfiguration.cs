using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class EmailConfirmationCodeConfiguration : IEntityTypeConfiguration<EmailConfirmationCode>
{
    public void Configure(EntityTypeBuilder<EmailConfirmationCode> builder)
    {
        builder.HasKey(oc => oc.Id);

        builder.Property(oc => oc.CodeHash).HasMaxLength(64).IsRequired();

        // Not unique: a 6-digit code's hash can collide across users/requests, unlike RefreshToken's
        // high-entropy token hash — lookups always go through (UserId, ConsumedAt == null), never the hash.
        builder.HasIndex(oc => oc.UserId);

        builder.HasOne(oc => oc.User)
            .WithMany()
            .HasForeignKey(oc => oc.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
