using System.ComponentModel.DataAnnotations;

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

    public required int GroupId { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public AppUser Owner { get; set; } = null!;
    public Group Group { get; set; } = null!;
}
