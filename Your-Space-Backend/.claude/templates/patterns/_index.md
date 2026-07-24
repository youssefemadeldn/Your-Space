# patterns/

Add one `.md` file per recurring *behavioral* pattern (not a layer — a cross-cutting shape like pagination or transactional writes) once it appears in two or more features and a template would prevent re-deriving it each time.

**Rules:**
- Use the `P` prefix for pattern files (e.g. `P1-pagination.md`, `P4-idempotent-webhook.md`).
- Create a pattern file only once the pattern has stabilized across at least two real feature implementations — not from speculation. `P1`–`P3` were seeded from day one here because the reference audit already showed each recurring across multiple real features; a genuinely new pattern still waits for its second real instance before earning a file.
- Each file structure: (1) trigger condition — when to apply this pattern, (2) fenced C# code block(s) with `<Placeholder>` tokens, (3) Notes section.
- Reference the relevant CLAUDE.md / companion-prompt sections in the frontmatter `governed-by` field.
- If a pattern file ever conflicts with `CLAUDE.md` or a companion prompt, the rule files win — update the pattern file, not the other way around.
