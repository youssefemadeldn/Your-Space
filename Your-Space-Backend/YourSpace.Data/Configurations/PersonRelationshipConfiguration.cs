using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Configurations;

public class PersonRelationshipConfiguration : IEntityTypeConfiguration<PersonRelationship>
{
    public void Configure(EntityTypeBuilder<PersonRelationship> builder)
    {
        builder.HasKey(r => r.Id);

        builder.HasIndex(r => r.PersonId);
        // Powers the "at most one incoming Father + one incoming Mother per person" guard clause.
        builder.HasIndex(r => new { r.PersonId, r.RelationType });

        // Cascade — if the owning Person row is ever hard-deleted, its outgoing relationship edges
        // go with it.
        builder.HasOne(r => r.Person)
            .WithMany()
            .HasForeignKey(r => r.PersonId)
            .OnDelete(DeleteBehavior.Cascade);

        // Restrict, not Cascade — avoids two cascade paths into the same Persons table (SQL Server/
        // Postgres both reject multiple cascade paths converging on one table). The service deletes
        // both sides of a relationship explicitly (see PersonRelationshipService.DeleteAsync).
        builder.HasOne(r => r.RelatedPerson)
            .WithMany()
            .HasForeignKey(r => r.RelatedPersonId)
            .OnDelete(DeleteBehavior.Restrict);

        // Self-referencing link to the auto-derived inverse row. Restrict — the service manages
        // both sides of a delete explicitly (PersonRelationshipService.DeleteAsync), a DB-level
        // cascade here would be redundant and could race the service's own transaction.
        builder.HasOne<PersonRelationship>()
            .WithOne()
            .HasForeignKey<PersonRelationship>(r => r.InverseRelationshipId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
