using System.ComponentModel.DataAnnotations;

namespace YourSpace.Data.Entities;

// Level 2 of the location hierarchy. Always user-owned (unlike Governorate) — no lock concept.
public class City
{
    public int Id { get; set; }

    public required string OwnerUserId { get; set; }

    public required int GovernorateId { get; set; }

    [MaxLength(200)]
    public required string Name { get; set; }

    [MaxLength(200)]
    public string? NameAr { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public AppUser Owner { get; set; } = null!;
    public Governorate Governorate { get; set; } = null!;
}
