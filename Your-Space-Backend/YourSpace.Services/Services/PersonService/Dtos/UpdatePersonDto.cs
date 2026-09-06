using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonService.Dtos;

public class UpdatePersonDto
{
    public required int Id { get; set; }

    // Null on any of the below means "leave unchanged" — with two documented exceptions:
    // - SubGroupId: null also covers "explicitly clear" (indistinguishable from "not provided" on
    //   a plain int?, same limitation as every other nullable-clearable field here) — and is what
    //   PersonService auto-applies when GroupId changes without a new SubGroupId in the same call.
    // - CityId/NeighborhoodId are validated for consistency against GovernorateId/CityId when the
    //   parent changes, even though they weren't resubmitted — see PersonService.UpdateAsync.
    public string? Name { get; set; }
    public string? PhoneNumber { get; set; }
    public string? PhoneNumber2 { get; set; }
    public Gender? Gender { get; set; }
    public int? GroupId { get; set; }
    public int? SubGroupId { get; set; }
    public int? GovernorateId { get; set; }
    public int? CityId { get; set; }
    public int? NeighborhoodId { get; set; }
    public string? Notes { get; set; }
}
