using Microsoft.AspNetCore.Identity;

namespace YourSpace.Data.Entities;

public class AppUser : IdentityUser
{
    public required string FirstName { get; set; }

    public required string LastName { get; set; }
}
