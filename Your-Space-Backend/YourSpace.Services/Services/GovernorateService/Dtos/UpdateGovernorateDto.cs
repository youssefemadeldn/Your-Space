namespace YourSpace.Services.Services.GovernorateService.Dtos;

public class UpdateGovernorateDto
{
    public required int Id { get; set; }

    // Null on either field below means "leave unchanged".
    public string? Name { get; set; }
    public string? NameAr { get; set; }
}
