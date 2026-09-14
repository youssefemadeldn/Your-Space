using Microsoft.EntityFrameworkCore;
using YourSpace.Data.Contexts;

namespace YourSpace.Repository.Sync;

public class SyncVersionProvider(YourSpaceDbContext context) : ISyncVersionProvider
{
    public async Task<long> NextValueAsync(string sequenceName, CancellationToken cancellationToken = default)
    {
        // `sequenceName` is always a hardcoded constant from our own code (e.g.
        // "People_SyncVersion_seq"), never user input — passing it as a parameter here is a
        // defense-in-depth habit, not a required injection guard. Postgres's nextval() takes a
        // regclass; a double-quoted name string casts correctly for our case-sensitive,
        // PascalCase-with-underscore sequence names.
        var quotedName = $"\"{sequenceName}\"";
        var results = await context.Database
            .SqlQueryRaw<long>("SELECT nextval(@p0)", quotedName)
            .ToListAsync(cancellationToken);
        return results[0];
    }
}
