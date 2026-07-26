using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class PersonOccasionHistoryConfiguration : IEntityTypeConfiguration<PersonOccasionHistory>
{
    public void Configure(EntityTypeBuilder<PersonOccasionHistory> builder)
    {
        builder.HasKey(h => h.Id);

        builder.HasIndex(h => h.PersonId);
        builder.HasIndex(h => new { h.PersonId, h.InvitedMe });

        builder.HasOne(h => h.Person)
            .WithMany()
            .HasForeignKey(h => h.PersonId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
