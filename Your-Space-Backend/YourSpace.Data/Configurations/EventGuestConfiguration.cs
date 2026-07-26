using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class EventGuestConfiguration : IEntityTypeConfiguration<EventGuest>
{
    public void Configure(EntityTypeBuilder<EventGuest> builder)
    {
        builder.HasKey(eg => eg.Id);

        builder.HasIndex(eg => new { eg.EventId, eg.PersonId }).IsUnique();
        builder.HasIndex(eg => eg.EventId);

        // Cascade — disposable join row, safe to lose alongside its one parent (Event/Person are
        // soft-deletable master data; this only fires on a genuine hard delete of either).
        builder.HasOne(eg => eg.Event)
            .WithMany()
            .HasForeignKey(eg => eg.EventId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(eg => eg.Person)
            .WithMany()
            .HasForeignKey(eg => eg.PersonId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
