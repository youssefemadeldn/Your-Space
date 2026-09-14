using Microsoft.EntityFrameworkCore;
using YourSpace.Data.Contexts;
using YourSpace.Data.Entities;
using YourSpace.Repository.Sync;

namespace YourSpace.WebAPI.Helpers;

// Idempotent — safe to run on every boot in every environment (unlike Database.Migrate() and
// MockDataSeeder, which stay Development-only). Seeds the shared/global reference rows the app
// can't function without: Egypt's 27 governorates (OwnerUserId null, IsLocked true), which every
// user's location picker reads. Distinct from IdentitySeeder (roles + first SuperAdmin).
public static class ReferenceDataSeeder
{
    public static async Task SeedAsync(IServiceProvider services, ILogger logger)
    {
        var context = services.GetRequiredService<YourSpaceDbContext>();
        var syncVersionProvider = services.GetRequiredService<ISyncVersionProvider>();

        var existingNames = (await context.Governorates
                .Where(g => g.OwnerUserId == null)
                .Select(g => g.Name)
                .ToListAsync())
            .ToHashSet();

        var missing = EgyptianGovernorates.All
            .Where(g => !existingNames.Contains(g.En))
            .Select(g => new Governorate { OwnerUserId = null, IsLocked = true, Name = g.En, NameAr = g.Ar })
            .ToList();

        if (missing.Count == 0)
        {
            return;
        }

        // A global row's SyncVersion (doc/local-first-sync-design.md §6) is assigned once, here,
        // at seed time and never bumped again — CheckEditable in GovernorateService blocks any
        // Update/Delete from ever reaching a locked row. Left at the column default 0, every
        // global row would be indistinguishable to a `WHERE SyncVersion > @since` delta-sync
        // pull and would never surface to any user, including on their very first sync.
        foreach (var governorate in missing)
        {
            governorate.SyncVersion = await syncVersionProvider.NextValueAsync("Governorates_SyncVersion_seq");
        }

        await context.Governorates.AddRangeAsync(missing);

        try
        {
            await context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            // Another API instance seeded the same rows concurrently on boot and won the race to
            // the filtered unique index on Governorate.Name (OwnerUserId IS NULL). Benign — the
            // rows exist either way. Any other failure is a real bug and still propagates.
            logger.LogInformation("Global governorates already seeded by another instance — skipping");
            return;
        }

        logger.LogInformation("Seeded {Count} global governorates", missing.Count);
    }
}
