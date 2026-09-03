using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonService.Dtos;

public class CreatePersonDto
{
    public required string Name { get; set; }
    public string? PhoneNumber { get; set; }
    public string? PhoneNumber2 { get; set; }
    public required Gender Gender { get; set; }
    public required int GroupId { get; set; }
    public string? Notes { get; set; }
}
