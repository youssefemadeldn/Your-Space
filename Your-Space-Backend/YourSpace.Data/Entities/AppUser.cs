using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;

using YourSpace.Data.Enums;

namespace YourSpace.Data.Entities;

public class AppUser : IdentityUser
{
    [MaxLength(100)]
    public required string FirstName { get; set; }

    [MaxLength(100)]
    public required string LastName { get; set; }

    public required Gender Gender { get; set; }
}
