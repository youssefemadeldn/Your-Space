using System.ComponentModel.DataAnnotations;

namespace YourSpace.Data.Entities;

// A photo attached to a Person, stored in the private "our-space-people-photos" R2 bucket. Hard-
// deletable child row — no DeletedAt — same precedent as PersonOccasionHistory.
public class PersonImage
{
    public int Id { get; set; }

    public required int PersonId { get; set; }

    // The R2 object key, never a URL — a URL is resolved on demand via IR2StorageService.GetPresignedUrlAsync,
    // never stored (it would go stale the moment the presigned expiry passes).
    [MaxLength(300)]
    public required string ObjectKey { get; set; }

    public bool IsPrimary { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Person Person { get; set; } = null!;
}
