namespace YourSpace.Services.Services.PersonService.Dtos;

public class PersonProfileDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? PhoneNumber { get; set; }
    public required int GroupId { get; set; }
    public required string GroupName { get; set; }
    public required bool HasReciprocityHistory { get; set; }
}
