using System.ComponentModel.DataAnnotations;

namespace YourSpace.Data.Entities;

// Second classification tier under Group — e.g. "Immediate Family" under the "Family" group.
// Always user-owned and scoped to exactly one parent Group.
public class SubGroup
{
    public int Id { get; set; }

    public required string OwnerUserId { get; set; }

    public required int GroupId { get; set; }

    [MaxLength(200)]
    public required string Name { get; set; }

    [MaxLength(200)]
    public string? NameAr { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public AppUser Owner { get; set; } = null!;
    public Group Group { get; set; } = null!;
}
