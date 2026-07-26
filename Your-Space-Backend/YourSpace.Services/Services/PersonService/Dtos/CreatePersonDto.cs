namespace YourSpace.Services.Services.PersonService.Dtos;

public class CreatePersonDto
{
    public required string Name { get; set; }
    public string? PhoneNumber { get; set; }
    public required int GroupId { get; set; }
}
