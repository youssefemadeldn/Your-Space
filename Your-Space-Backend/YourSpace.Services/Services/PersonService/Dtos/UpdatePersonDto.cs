using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonService.Dtos;

public class UpdatePersonDto
{
    public required int Id { get; set; }

    // Null on any of the below means "leave unchanged".
    public string? Name { get; set; }
    public string? PhoneNumber { get; set; }
    public string? PhoneNumber2 { get; set; }
    public Gender? Gender { get; set; }
    public int? GroupId { get; set; }
    public string? Notes { get; set; }
}
