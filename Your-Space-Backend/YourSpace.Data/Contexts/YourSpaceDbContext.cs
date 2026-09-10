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

    public DbSet<Group> Groups => Set<Group>();
    public DbSet<Person> People => Set<Person>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<EventGuest> EventGuests => Set<EventGuest>();
    public DbSet<PersonOccasionHistory> PersonOccasionHistories => Set<PersonOccasionHistory>();
    public DbSet<PersonImage> PersonImages => Set<PersonImage>();
    public DbSet<UserSettings> UserSettings => Set<UserSettings>();

    public DbSet<SubGroup> SubGroups => Set<SubGroup>();
    public DbSet<Governorate> Governorates => Set<Governorate>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<Neighborhood> Neighborhoods => Set<Neighborhood>();
    public DbSet<PersonRelationship> PersonRelationships => Set<PersonRelationship>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(YourSpaceDbContext).Assembly);
    }
}
