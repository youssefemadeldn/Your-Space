# integrations/

Add one subfolder per third-party SDK integration when the pattern is established (e.g. `google-maps/`, `firebase/`, `payment/`).

**Rules:**
- Create a subfolder only when that integration is actively being built — never speculatively.
- Name templates inside the subfolder with the `T` prefix scoped within that subfolder (T1, T2, ...).
- Each template file follows the same structure as `layers/`: frontmatter with governed-by references, fenced Dart code block(s), Notes section.
- If a rule in the integration template conflicts with the project rule files (`CLAUDE.md`, `flutter_feature_prompt.md`), the rule files win.
