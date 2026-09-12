namespace YourSpace.Repository.Sync;

/// Hands out the next value of a Postgres sequence backing a delta-sync entity's `SyncVersion`
/// column (doc/local-first-sync-design.md §6). One sequence per synced entity table (e.g.
/// "People_SyncVersion_seq") — every mutating service method (Create/Update/soft-Delete) must
/// assign a fresh value before saving, since a bigserial-style column only auto-populates on
/// INSERT, never on UPDATE.
public interface ISyncVersionProvider
{
    Task<long> NextValueAsync(string sequenceName, CancellationToken cancellationToken = default);
}
