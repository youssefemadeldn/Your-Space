using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using YourSpace.Data.Entities;

namespace YourSpace.Data.Contexts;

public class YourSpaceDbContext(DbContextOptions<YourSpaceDbContext> options)
    : IdentityDbContext<AppUser>(options)
{
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<EmailConfirmationCode> EmailConfirmationCodes => Set<EmailConfirmationCode>();
    public DbSet<PasswordResetCode> PasswordResetCodes => Set<PasswordResetCode>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(YourSpaceDbContext).Assembly);
    }
}
