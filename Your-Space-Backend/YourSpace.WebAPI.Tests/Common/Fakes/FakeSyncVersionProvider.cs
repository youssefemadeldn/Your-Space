using System.Collections.Concurrent;
using YourSpace.Repository.Sync;

namespace YourSpace.WebAPI.Tests.Common.Fakes;

// Real ISyncVersionProvider calls Postgres's nextval(), which the SQLite-backed integration test
// host (TestWebApplicationFactory) can't run — same reason IEmailSender/IR2StorageService are
// swapped for fakes there. An in-memory atomic counter per sequence name is monotonic and unique
// enough for a single-process test run, which is all these tests need.
public class FakeSyncVersionProvider : ISyncVersionProvider
{
    private readonly ConcurrentDictionary<string, long> _counters = new();

    public Task<long> NextValueAsync(string sequenceName, CancellationToken cancellationToken = default)
        => Task.FromResult(_counters.AddOrUpdate(sequenceName, 1, (_, current) => current + 1));
}
