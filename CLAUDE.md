# CLAUDE.md

This repo root holds multiple independently-governed projects, not one application.

## Projects

| Project | Path | Stack | Rules |
|---|---|---|---|
| Backend | `.net/` | ASP.NET Core / .NET | `.net/CLAUDE.md` |
| Mobile | `flutter/` | Flutter / Dart | `flutter/CLAUDE.md` |

Each project's own `CLAUDE.md` (and its `.claude/rules/`, `.claude/templates/`) loads automatically the moment a file inside that folder is read — Claude Code does this on its own, it doesn't need to be told to go open it. That file is the authority for everything inside its folder; this root file only orients and sets the rules that hold across all of them.

## Cross-project rules

- Never apply one project's architecture rules, naming conventions, or anti-patterns to another project's code — they're governed independently, even where a section name matches across projects (e.g. both have a "Testing discipline" section that means different things).
- If a task spans both projects (e.g. a new backend endpoint plus the mobile screen that calls it), keep each project's rules strictly inside its own folder rather than blending them into one style.
- If a request doesn't make the target project obvious before any file has been touched yet, ask rather than guessing.

## Adding a project

A new project (e.g. a frontend) gets its own top-level folder with its own `CLAUDE.md` + `.claude/rules/` + `.claude/templates/`, plus a new row above. Its rules load the same way — nothing else here needs to change.
