namespace YourSpace.Services.Services.GroupService.Dtos;

public class UpdateGroupDto
{
    public required int Id { get; set; }

    // Null on any of the below means "leave unchanged".
    public string? Name { get; set; }
    public string? NameAr { get; set; }
}
