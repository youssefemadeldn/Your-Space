namespace YourSpace.Services.Services.SubGroupService.Dtos;

// GroupId comes from the route (nested under groups/{groupId}/subgroups), not here.
public class CreateSubGroupDto
{
    public required string Name { get; set; }
    public string? NameAr { get; set; }
}
