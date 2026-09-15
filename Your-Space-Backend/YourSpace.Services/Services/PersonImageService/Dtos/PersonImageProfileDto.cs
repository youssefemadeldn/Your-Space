namespace YourSpace.Services.Services.PersonImageService.Dtos;

// Flat "all mine" sync shape (row 9.16) -- deliberately NOT PersonImageDto's presigned Url: a
// presigned URL expires within minutes/hours and must never be treated as a cacheable value. This
// endpoint exists purely to feed the mobile client's local existence/bookkeeping cache (row 9 --
// what images exist, which is primary); the client still resolves a live, renderable Url via the
// existing nested GetAll endpoint whenever it actually needs to display one.
public class PersonImageProfileDto
{
    public required int Id { get; set; }
    public required int PersonId { get; set; }
    public required string ObjectKey { get; set; }
    public required bool IsPrimary { get; set; }
}
