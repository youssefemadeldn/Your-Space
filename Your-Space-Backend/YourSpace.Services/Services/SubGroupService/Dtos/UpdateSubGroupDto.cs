namespace YourSpace.Services.Services.SubGroupService.Dtos;

// Id/GroupId come from the route — null on either field below means "leave unchanged".
public class UpdateSubGroupDto
{
    public string? Name { get; set; }
    public string? NameAr { get; set; }
}
