namespace YourSpace.Services.Services.UserSettingsService.Dtos;

public class UserSettingsDetailsDto
{
    public required string UserId { get; set; }
    public required bool ReciprocitySuggestionsEnabled { get; set; }
    public required DateTime UpdatedAt { get; set; }
}
