namespace YourSpace.Services.Services.PersonImageService.Dtos;

public class PersonImageDto
{
    public required int Id { get; set; }

    // Presigned, resolved in-service — never a plain AutoMapper member-map.
    public required string Url { get; set; }

    // Row 9.17 — lets the mobile client's outbox replayer populate the local
    // bookkeeping cache's `objectKey` column directly from an upload's own
    // confirmation response, without waiting for the next Tier 3
    // full-refetch. Never itself cached as a display value (see
    // `PersonImageProfileDto`'s own doc comment) — `Url` stays the only
    // renderable field.
    public required string ObjectKey { get; set; }

    public required bool IsPrimary { get; set; }
    public required DateTime CreatedAt { get; set; }
}
