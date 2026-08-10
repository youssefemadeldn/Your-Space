# Session Handoff — 2026-08-10

> **OUT OF PREVIOUS SESSION — NEW SESSION START**
>
> Read this file first. It contains everything from the prior session.

## What Was Done

Added a new **Scalability & Performance** dimension to the `.NET` backend rule set (`Your-Space-Backend`), using the `dotnet-rules-sync` skill's phases + the `clarify-loop` skill for open decisions. This was a **rule-set-only** change — no application code was modified; real code was only read for style-matching. Full sequence:

- **Phase 1/2 (dotnet-rules-sync):** searched `CLAUDE.md`, both companion prompts, and `templates/` for existing partial coverage of six named gaps (caching, N+1, indexing, connection pooling, observability, load testing) before drafting anything. Findings reported to the user before drafting — see "Key References" below for the full recap (also embedded in the plan file).
- **Real-code exploration:** read the actual `Program.cs`, `ServiceRegistration.cs`, `RateLimitingExtension.cs`, a real `Specification` (`PersonWithSpecs.cs`), a real service (`CityService.cs`), `EventGuestWithSpecs.cs`/`EventService.cs` (the real N+1-avoidance precedent used as the new rule's "correct" example), `appsettings*.json`, and all `.csproj` files — so every new rule's code example matches this repo's actual style, not generic boilerplate.
- **clarify-loop round:** asked 4 batched questions (load-test tool, concurrency target, whether to create the new pattern file now vs. hold off, load-test rule scope). All answered — see "Clarifications & Decisions."
- **Plan written and approved** (plan-mode), then applied via precise `Edit` calls (one per changed block, per the skill's Phase 4), then a **Phase 5 consistency check** was run and reported (no contradictions, no orphaned cross-references, all propagations landed, no duplication).

Net result: 6 new rules covering caching (ownership/key-naming/TTL/invalidation), N+1 prevention (Architecture Rule 11), indexing discipline (per-Specification-shape checklist), Npgsql connection-pool sizing, OpenTelemetry observability, and an NBomber load-testing gate — fully routed across `CLAUDE.md`, both companion prompts, and one new pattern file, per the skill's routing table.

## Files Changed

| File | Change | Why |
|---|---|---|
| `Your-Space-Backend\CLAUDE.md` | Fixed `<Concern>ServiceExtensions.cs` → `ServiceExtension.cs` (line 113, matches real files); added Architecture Rule 11 (no per-iteration DB round-trips); added `IDistributedCache` to the DI lifetime table; added new `## Caching` section (after `## Secrets`, before `## Localization`) with correct/wrong invalidation example; extended `## Testing discipline` with `LoadTests/` taxonomy + the NBomber load-testing gate bullet; added 3 completion-checklist lines | Gaps #1, #2, #6 + a pre-existing naming inconsistency found on the exact line being extended |
| `Your-Space-Backend\.claude\rules\dotnet_scaffold_prompt.md` | Added Observability package bullet (OpenTelemetry, OTLP placeholder); appended `NBomber` to the Testing package bullet; added connection-pool-sizing bullet to "Environment & connection string strategy"; added `Extensions/CacheServiceExtension.cs` + `Extensions/ObservabilityServiceExtension.cs` to the WebAPI file plan; updated the `Program.cs` pipeline-order diagram (`AddObservability()`, `AddCaching()`) | Gaps #4, #5, and the `CacheServiceExtension` reference from #1 |
| `Your-Space-Backend\.claude\rules\dotnet_feature_prompt.md` | Added `### Rule 11 — No per-iteration database round-trips (N+1)` with a correct/wrong pair using the real `EventGuestWithSpecs.ForEvents`/`EventService.GetAllAsync` code; added checklist lines to §6 Data layer (indexing), Repository layer (N+1), Service layer (cache invalidation), Tests (load-test gate); added one §7 anti-pattern table row | Gaps #2, #3, #6 |
| `Your-Space-Backend\.claude\templates\patterns\P5-caching.md` (new) | Cache-aside read + invalidate-on-write pattern (`<Entity>`-templated read/write code, Notes section) | User overrode the "hold off" recommendation and asked to create it now |

## Files Audited (no changes)

| File | Checked For | Result |
|---|---|---|
| `Your-Space-Backend\YourSpace.WebAPI\Program.cs` | Current Serilog/Redis/DbContext wiring, whether lazy-loading proxies or OpenTelemetry already exist | Redis (`IConnectionMultiplexer` + `AddStackExchangeRedisCache`) already registered but **completely unused anywhere in the app** (confirmed by exhaustive grep — zero `IDistributedCache` call sites). No lazy-loading proxies. No OpenTelemetry. No pool-size config on the connection string. |
| `Your-Space-Backend\YourSpace.WebAPI\Helpers\ServiceRegistration.cs`, `Extensions\RateLimitingExtension.cs` | Grouping/naming conventions to mirror in new rule text | `Extensions/` files are named `<Concern>ServiceExtension.cs` (singular) in reality, not the `ServiceExtensions.cs` (plural) `CLAUDE.md` stated — fixed in this session |
| `YourSpace.Repository\Specifications\PeopleSpecifications\PersonWithSpecs.cs`, `EventSpecifications\EventGuestWithSpecs.cs` | Real Specification/eager-load shape for the N+1 rule's code example | `EventGuestWithSpecs.ForEvents` + `EventService.GetAllAsync` is a real, already-correct N+1-avoidance precedent in the codebase — used verbatim as the new rule's "Correct" example |
| `YourSpace.Services\Services\CityService\CityService.cs` | Constructor DI order, logging style, `ServiceResult`/`ErrorCodes` pattern | Used as the base for the Caching section's correct/wrong example |
| All `.csproj` files | Confirm exact package names/versions already installed | `Microsoft.Extensions.Caching.StackExchangeRedis` (10.0.10) and `Polly` (8.7.0) already referenced but **unused**; `Testcontainers.Redis` present (integration tests only); zero OpenTelemetry/k6/NBomber packages anywhere |
| `appsettings.json` / `appsettings.Development.json` | Existing connection-string/pool config | Bare Npgsql keyword=value string, zero pool-size keywords — new pool-sizing guidance is purely additive |

## Pending Tasks

- [ ] None for this rule-set task — it's complete and was verified via Phase 5 consistency check + grep confirmation.

## What's Next (ordered)

1. **Known drift, flagged not fixed:** `Program.cs` still registers Redis inline (`AddSingleton<IConnectionMultiplexer>` + `AddStackExchangeRedisCache`) instead of via the new `CacheServiceExtension.AddCaching()` the rule set now documents. A future feature PR that touches caching should extract this into the extension class to match the documented convention — out of scope for a rule-set-only session.
2. The first feature that actually needs caching should follow `CLAUDE.md` "Caching" + `patterns/P5-caching.md` (cache-aside read, invalidate-on-write, `yourspace:<feature>:<shape>:<id>` key naming, 15-min default TTL).
3. The first feature expected to carry meaningful concurrent traffic (payment, auth, contended writes) should get an `NBomber` load test under `WebAPI.Tests/LoadTests/` per the new "Testing discipline" gate (target: 200–500 concurrent virtual users).

## Key References

- Plan file (full before/after diffs + Phase 2/5 reports): `C:\Users\youss\.claude\plans\using-clarify-loop-and-dotnet-rules-sync-peppy-spark.md`
- `Your-Space-Backend\CLAUDE.md` — Architecture Rule 11, `## Caching`, `## Testing discipline`, completion checklist
- `Your-Space-Backend\.claude\rules\dotnet_scaffold_prompt.md` — package list, connection-pool bullet, WebAPI file plan, `Program.cs` pipeline order
- `Your-Space-Backend\.claude\rules\dotnet_feature_prompt.md` — Rule 11, §6 checklist, §7 anti-pattern table
- `Your-Space-Backend\.claude\templates\patterns\P5-caching.md` — new cache-aside pattern

## Clarifications & Decisions

| Question | Answer |
|---|---|
| Which single load-testing tool should the load-testing gate standardize on (NBomber vs. k6)? | **NBomber** — stays in C#/.NET, no separate runtime needed |
| What concurrency target should the load-testing gate treat as "realistic," given the app is currently personal/daily-use with a possible future public release? | **Public-release-ready (~200–500 concurrent users)** — user chose to size ahead of the stated possible public release, overriding the "current-scale" recommendation |
| Should `templates/patterns/P-caching.md` be created now, or held off (per the skill's "no speculative pattern files" rule, since zero features use caching yet)? | **Create it now** — user overrode the "hold off" recommendation; file created as `P5-caching.md` (correct sequence number, since `P1`–`P4` already exist) |
| Should the load-testing rule stay conditional on expected concurrent traffic (payment/auth/contended writes), or apply to every write endpoint? | **Keep it conditional** — matches how Rule 8 (localization) is already day-one non-negotiable yet fires only on its own trigger |

## Notes

- Solution/namespace root confirmed as `YourSpace` (no `<RootNamespace>` overrides anywhere; matches the `<Solution>` placeholder used throughout the rule files exactly).
- Root-level `CLAUDE.md` (`d:\Programing\Your-Space\CLAUDE.md`) still lists the backend path as `.net/` in its project table, but the real folder is `Your-Space-Backend\`. Flagged during this session as an aside; **intentionally not fixed** — out of scope for a Scalability & Performance rule-set task.
- `RateLimitingExtension.cs` doesn't include "Service" in its name (unlike `EmailServiceExtension.cs`/`IdentityServiceExtension.cs`/`StorageServiceExtension.cs`/`SwaggerServiceExtension.cs`) — a minor pre-existing naming quirk, not touched since it's a single already-shipped file, not a documentation line.
- The new `CacheServiceExtension.cs`/`ObservabilityServiceExtension.cs` files described in `dotnet_scaffold_prompt.md` **do not exist yet** in `Your-Space-Backend\YourSpace.WebAPI\Extensions\` — they're the target shape for the next feature/cleanup PR that touches caching or observability, not something this session created (this session only touched rule/doc files, never application code).
