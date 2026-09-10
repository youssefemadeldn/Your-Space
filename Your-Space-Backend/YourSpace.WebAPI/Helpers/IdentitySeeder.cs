using Microsoft.AspNetCore.Identity;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.AuthService;

namespace YourSpace.WebAPI.Helpers;

// Idempotent — safe to run on every boot in every environment (unlike Database.Migrate(),
// which stays Development-only). Bootstraps the first SuperAdmin, since only a SuperAdmin
// can promote another admin — without this there'd be no way to create one.
public static class IdentitySeeder
{
    public static async Task SeedAsync(IServiceProvider services, IConfiguration configuration, ILogger logger)
    {
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = services.GetRequiredService<UserManager<AppUser>>();

        foreach (var roleName in RoleNames.All)
        {
            if (!await roleManager.RoleExistsAsync(roleName))
            {
                await roleManager.CreateAsync(new IdentityRole(roleName));
                logger.LogInformation("Created role {RoleName}", roleName);
            }
        }

        var existingSuperAdmins = await userManager.GetUsersInRoleAsync(RoleNames.SuperAdmin);
        if (existingSuperAdmins.Count > 0)
        {
            return;
        }

        var email = configuration["SuperAdmin:Email"];
        var password = configuration["SuperAdmin:Password"];
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            logger.LogWarning(
                "No SuperAdmin account exists and SuperAdmin:Email/SuperAdmin:Password are not configured — skipping bootstrap seed");
            return;
        }

        var superAdmin = new AppUser
        {
            UserName = email,
            Email = email,
            FirstName = configuration["SuperAdmin:FirstName"] ?? "Super",
            LastName = configuration["SuperAdmin:LastName"] ?? "Admin",
            Gender = Gender.Female, // no business meaning for a system bootstrap account
            EmailConfirmed = true
        };

        // Transaction-wrapped for the same reason as AuthService.RegisterAsync: without it, a failed
        // AddToRoleAsync would leave a role-less user account behind, and since the idempotency check
        // above looks for a SuperAdmin *role* (not this email), every future boot would retry
        // CreateAsync on the same email and fail forever on the unique-email constraint.
        var unitOfWork = services.GetRequiredService<IUnitOfWork>();
        await using (var transaction = await unitOfWork.BeginTransactionAsync())
        {
            try
            {
                var createResult = await userManager.CreateAsync(superAdmin, password);
                if (!createResult.Succeeded)
                {
                    logger.LogError(
                        "Failed to seed the initial SuperAdmin account: {Errors}",
                        string.Join(", ", createResult.Errors.Select(e => e.Code)));
                    return;
                }

                var roleResult = await userManager.AddToRoleAsync(superAdmin, RoleNames.SuperAdmin);
                if (!roleResult.Succeeded)
                {
                    logger.LogError(
                        "Failed to assign the SuperAdmin role during bootstrap seed: {Errors}",
                        string.Join(", ", roleResult.Errors.Select(e => e.Code)));
                    return;
                }

                await unitOfWork.CommitAsync(transaction);
            }
            catch
            {
                await unitOfWork.RollbackAsync(transaction);
                throw;
            }
        }

        logger.LogInformation("Seeded initial SuperAdmin account {Email}", email);
    }
}
