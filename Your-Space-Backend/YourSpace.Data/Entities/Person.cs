using System.ComponentModel.DataAnnotations;

using YourSpace.Data.Enums;

namespace YourSpace.Data.Entities;

// Deliberately shared/core — not owned by any one feature. Other future features can reference
// the same Person records without re-creating them.
public class Person
{
    public int Id { get; set; }

    public required string OwnerUserId { get; set; }

    // No NameAr — a personal contact's name isn't "translated content" the way a product name is;
    // matches AppUser.FirstName/LastName, which also has no Ar counterpart today.
    [MaxLength(200)]
    public required string Name { get; set; }

    [MaxLength(20)]
    public string? PhoneNumber { get; set; }

    [MaxLength(20)]
    public string? PhoneNumber2 { get; set; }

    public required Gender Gender { get; set; }

    public required int GroupId { get; set; }

    // Second classification tier, scoped to GroupId — auto-cleared by PersonService whenever
    // GroupId changes and a new SubGroupId isn't explicitly provided in the same call.
    public int? SubGroupId { get; set; }

    // Location hierarchy (Governorate -> City -> Neighborhood), fully independent of Group/SubGroup.
    // Governorate is required; City/Neighborhood are optional but validated against their parent.
    public required int GovernorateId { get; set; }
    public int? CityId { get; set; }
    public int? NeighborhoodId { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public AppUser Owner { get; set; } = null!;
    public Group Group { get; set; } = null!;
    public SubGroup? SubGroup { get; set; }
    public Governorate Governorate { get; set; } = null!;
    public City? City { get; set; }
    public Neighborhood? Neighborhood { get; set; }
}
