---
name: P2-soft-delete-and-concurrency
governed-by: templates/layers/T1-entity.md · templates/layers/T2-repository.md
---

# P2 — Soft Delete & Optimistic Concurrency

Two related but independent patterns — an entity can need either, both, or neither. Decide per entity; don't apply both by default (see `T1-entity.md` Notes).

---

## Soft delete

**Trigger:** an entity whose rows must never actually disappear (audit trail, referenced by historical orders/reviews, needed for a future "restore" action).

```csharp
// Entity (T1-entity.md)
public DateTime? DeletedAt { get; set; }

// "Delete" is an update, not a repo.Delete() call:
public async Task<ServiceResult> DeleteAsync(int id)
{
    var repo = _unitOfWork.Repository<<Entity>, int>();
    var entity = await repo.GetByIdAsync(id);
    if (entity is null || entity.DeletedAt is not null)
        return ServiceResult.NotFound(_localizer["<Entity>.NotFound", id]);   // see CLAUDE.md "Localization"

    entity.DeletedAt = DateTime.UtcNow;
    repo.Update(entity);
    await _unitOfWork.SaveChangesAsync();
    return ServiceResult.Ok();
}

// Every specification for this entity filters it out (T2-repository.md), e.g.:
public <Entity>WithSpecs(int id) : base(x => x.Id == id && x.DeletedAt == null) { }
```

## Optimistic concurrency

**Trigger:** an entity written concurrently by more than one caller where a lost update would be a real bug (a wallet balance, a stock count, a status field flipped by two admins at once).

```csharp
// Entity (T1-entity.md)
[ConcurrencyCheck]
public byte[] RowVersion { get; set; } = Array.Empty<byte>();

// Bump it on every update so the next writer's stale read is detected:
entity.RowVersion = Guid.NewGuid().ToByteArray();
repo.Update(entity);
await _unitOfWork.SaveChangesAsync(); // throws DbUpdateConcurrencyException if RowVersion no longer matches
```

**For a simple numeric counter under contention** (stock, balance), prefer an atomic guarded update over a full read-modify-write-with-concurrency-token cycle — it's simpler and avoids the retry-on-conflict logic concurrency tokens require entirely:

```csharp
// On IUnitOfWork — see T2-repository.md's Rule-3 guidance for why this lives here, not on the generic repo
public async Task<bool> TryDecrementStockAsync(int productId, int quantity)
{
    var rowsAffected = await _context.Set<<Entity>>()
        .Where(x => x.Id == productId && x.StockQuantity >= quantity)
        .ExecuteUpdateAsync(x => x.SetProperty(e => e.StockQuantity, e => e.StockQuantity - quantity));

    return rowsAffected > 0; // false means the guard failed — not enough stock — treat as an expected outcome, not an exception
}
```

---

## Notes

- **Soft delete and a `HasQueryFilter` are an either/or choice, not both-by-default** — see `T1-entity.md`'s note on the tradeoff (a global filter is safer against a forgotten `DeletedAt == null`, but also silently hides soft-deleted rows from an admin "show deleted" view unless that view explicitly uses `IgnoreQueryFilters()`).
- **`DbUpdateConcurrencyException` is an expected outcome for a concurrency-token entity, not an unexpected exception** — a service using `[ConcurrencyCheck]` should catch this specific exception type (not generic `Exception`) and return `ServiceResult.Conflict(...)`, which does not violate CLAUDE.md's "one error boundary" rule since it's a narrowly-typed catch for a genuinely expected outcome, not a blanket `catch (Exception ex)`.
- **The atomic-`ExecuteUpdateAsync`-with-guard approach and full optimistic concurrency solve overlapping but different problems** — the atomic update prevents an invalid state (stock below zero) without ever needing a retry; a concurrency token detects *any* conflicting write and forces the caller to re-read and retry. Use the atomic form when the "guard" is simple (a threshold check); use a concurrency token when the entity has many fields any of which might conflict.
