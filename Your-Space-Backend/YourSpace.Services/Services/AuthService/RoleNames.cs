namespace YourSpace.Services.Services.AuthService;

public static class RoleNames
{
    public const string User = "User";
    public const string StandardAdmin = "StandardAdmin";
    public const string SuperAdmin = "SuperAdmin";

    public static readonly string[] All = [User, StandardAdmin, SuperAdmin];
    public static readonly string[] AdminRoles = [StandardAdmin, SuperAdmin];
}
