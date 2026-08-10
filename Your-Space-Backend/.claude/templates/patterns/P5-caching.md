---
name: P5-caching
governed-by: CLAUDE.md "Caching" · dotnet_scaffold_prompt.md "Environment & connection string strategy" (Redis registration)
---

# P5 — Cache-Aside Read, Invalidate-on-Write

**Trigger:** a service method reads data that's fetched far more often than it changes (lookup/reference data, a details view for a rarely-edited entity) and the read cost (a joined/paginated query, a multi-table `Include`) is worth avoiding on every request.

---

## Read path — cache-aside in the service

```csharp
public async Task<ServiceResult<<Entity>DetailsDto>> GetDetailsAsync(int id)
{
    var cacheKey = $"yourspace:<feature>:details:{id}";
    var cached = await cache.GetStringAsync(cacheKey);
    if (cached is not null)
    {
        return ServiceResult<<Entity>DetailsDto>.Ok(JsonSerializer.Deserialize<<Entity>DetailsDto>(cached)!);
    }

    var repo = unitOfWork.Repository<<Entity>, int>();
    var entity = await repo.GetByIdWithSpecAsync(new <Entity>WithSpecs(id));
    if (entity is null)
    {
        return ServiceResult<<Entity>DetailsDto>.NotFound(localizer["<Entity>.NotFound", id], "<Entity>.NotFound");
    }

    var dto = mapper.Map<<Entity>DetailsDto>(entity);
    await cache.SetStringAsync(cacheKey, JsonSerializer.Serialize(dto),
        new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(15) });

    return ServiceResult<<Entity>DetailsDto>.Ok(dto);
}
```

## Write path — invalidate in the same method

```csharp
public async Task<ServiceResult<<Entity>DetailsDto>> UpdateAsync(int id, Update<Entity>Dto dto)
{
    var repo = unitOfWork.Repository<<Entity>, int>();
    var entity = await repo.GetByIdWithSpecAsync(new <Entity>WithSpecs(id));
    if (entity is null)
    {
        return ServiceResult<<Entity>DetailsDto>.NotFound(localizer["<Entity>.NotFound", id], "<Entity>.NotFound");
    }

    entity.Name = dto.Name ?? entity.Name;
    entity.UpdatedAt = DateTime.UtcNow;
    repo.Update(entity);
    await unitOfWork.SaveChangesAsync();

    await cache.RemoveAsync($"yourspace:<feature>:details:{id}");   // same method as the write

    return ServiceResult<<Entity>DetailsDto>.Ok(mapper.Map<<Entity>DetailsDto>(entity));
}
```

---

## Notes

- **Cache-aside, not write-through** — the service reads the cache first and falls back to the repository on a miss; it never asks the cache to own the write itself. `IUnitOfWork.SaveChangesAsync()` remains the single source of truth; the cache is a read accelerator on top of it, never the primary write target.
- **Invalidate, don't update-in-place** — `RemoveAsync` after a write is simpler and safer than computing the new cached value inline; the next read repopulates it. Only update the cached value in place instead of removing it when recomputing it is itself expensive enough to be worth avoiding on the very next read — a rare case, not the default.
- **Key naming matches CLAUDE.md "Caching"** — `yourspace:<feature>:<shape>:<identifier>`, all lowercase, colon-delimited. A list/paginated key includes every parameter that changes the result set, or it will silently serve one page's cached results for a different filter/page combination.
- **TTL is a starting point, not a ceiling** — 15 minutes by default; invalidation-on-write is what actually keeps the cache correct, TTL is only the backstop for a key that's never explicitly invalidated (e.g. written by a process that doesn't go through this service).
- **Never cache inside the repository/specification layer** — `IGenericRepository<TEntity,TKey>` stays persistence-only (Architecture rule 3); mixing cache logic into it means a caller using the repository directly gets silently stale-or-fresh data depending on who else already populated the cache.
