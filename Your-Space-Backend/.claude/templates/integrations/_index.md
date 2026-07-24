# integrations/

Add one subfolder per third-party SDK/service integration once that integration is actively being built (e.g. `payment-gateway/`, `cloud-storage/`, `email/`, `sms/`).

**Rules:**
- Create a subfolder only when that integration is actively being built — never speculatively. No subfolders are seeded here by default, even though the reference audit this rule set was built from used several (a payment gateway, S3-compatible object storage, transactional email) — each of those earns its folder only in a project that's actually integrating it.
- Name templates inside the subfolder with the `T` prefix scoped within that subfolder (`T1`, `T2`, …), same structure as `templates/layers/`: frontmatter with `governed-by` references, fenced C# code block(s), a Notes section.
- Cross-cutting concerns that show up in most external integrations, worth naming explicitly whichever subfolder you create:
  - **Secrets** (API keys, HMAC secrets, webhook signing keys) follow CLAUDE.md "Secrets" without exception — an integration subfolder's template must never show a real key, only a placeholder and a pointer to `dotnet user-secrets`/environment variables.
  - **Webhooks need idempotency** — a payment or delivery webhook can be retried by the sender; the handler must be safe to receive the same payload twice (check-then-act against a stored external transaction id, not a bare "process every request that arrives").
  - **Outbound calls to the integration should not happen inside an open DB transaction** — see `patterns/P3-transactional-write.md`'s note on keeping transaction scope small.
- If a rule in an integration template conflicts with `CLAUDE.md` or a companion prompt, the rule files win.
