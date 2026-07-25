---
name: P3-transactional-write
governed-by: CLAUDE.md Architecture rule 7 · dotnet_feature_prompt.md Rule 5
---

# P3 — Transactional Multi-Step Write

**Trigger:** a service operation writes to more than one table/aggregate where a partial write would leave the data in an invalid state (e.g. replace a product's images: delete the old rows, upload new files, insert new rows — a crash between steps must not leave the product with zero images when it had some before).

---

```csharp
await using var transaction = await _unitOfWork.BeginTransactionAsync();
try
{
    // Step 1 — first repository's write
    imageRepo.Delete(oldImage);
    await _unitOfWork.SaveChangesAsync();

    // Step 2 — external side effect that must happen only if step 1 committed logically,
    // but BEFORE the transaction commits (see the "don't call out" note below for why
    // this specific example is a deliberate exception, not a template to copy blindly)

    // Step 3 — second repository's write, same transaction
    await imageRepo.AddRangeAsync(newImages);
    await _unitOfWork.SaveChangesAsync();

    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw; // ExceptionMiddleware decides the HTTP response — this catch only protects the transaction
}
```

---

## Notes

- **Never swallow in the catch** — `RollbackAsync()` then `throw;`, always. A transaction block is the one place `dotnet_feature_prompt.md` Rule 1 explicitly allows a `catch` in a service method, and even there it exists only to guarantee rollback, never to convert the failure into a generic `ServiceResult`.
- **Keep the transaction scope as small as possible — avoid calling an external HTTP/email/payment API while a database transaction is open.** An open transaction holds a connection (and potentially row locks) for as long as it's open; a slow or hanging external call extends that hold time and can exhaust the connection pool under load. If an operation genuinely needs "write to DB, then call an external service, then finalize," either commit the local write first and treat the external call as a separate follow-up step (with its own compensating logic if it fails), or use an outbox-style pattern — don't just wrap the external call inside the same `BeginTransactionAsync`/`CommitAsync` block as a shortcut.
- **This pattern is orthogonal to `SaveChangesAsync`'s own atomicity** — a single `SaveChangesAsync()` call is already atomic for everything tracked in that one call; you only need an explicit transaction when the operation needs *multiple* `SaveChangesAsync()` calls (often because something else — a file upload, a call into another repository across two units of work — has to happen between them) to succeed or fail together.
- **Retry-strategy incompatibility (carry this forward, don't rediscover it):** if `EnableRetryOnFailure` is ever enabled on the `DbContext` (Npgsql or SQL Server), every explicit `BeginTransactionAsync` call site must be wrapped in the provider's `IExecutionStrategy.ExecuteAsync(...)`, because the built-in retrying execution strategy is incompatible with user-initiated transactions otherwise. `dotnet_scaffold_prompt.md`'s default is to leave retry-on-failure off until this is deliberately taken on solution-wide, precisely to avoid a codebase full of transaction sites that all need updating at once.
- **`UnitOfWork.BeginTransactionAsync()` has no reentrancy guard** — it's a bare `context.Database.BeginTransactionAsync()`. If method A opens a transaction and, inside it, calls helper method B which *also* unconditionally opens its own transaction, that nested `BeginTransactionAsync` call throws at runtime — not at compile time, and not in a mocked unit test, only when B is actually reached with A's transaction still open. Any helper that manages its own transaction (a "revoke all X" or "invalidate all Y" style method used both standalone and as one step of a larger flow) needs two forms: a transaction-less "core" method containing the actual writes, and a thin wrapper that opens/commits/rolls back around a call to the core method. The standalone caller uses the wrapper; a caller that already holds an open transaction calls the core method directly.
