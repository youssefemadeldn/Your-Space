# patterns/

Add one `.md` file per recurring behavioral pattern when it appears in two or more features and a template would prevent re-derivation each time.

**Rules:**
- Use the `P` prefix for pattern files (e.g. `P1-pagination.md`, `P2-optimistic-ui.md`).
- Create a pattern file only once the pattern has stabilized across at least two real feature implementations — not from speculation.
- Each file structure: (1) trigger condition — when to apply this pattern, (2) fenced Dart code block(s) with `<Placeholder>` tokens, (3) Notes section.
- Reference the relevant `§` sections from `flutter_feature_prompt.md` in the frontmatter.
