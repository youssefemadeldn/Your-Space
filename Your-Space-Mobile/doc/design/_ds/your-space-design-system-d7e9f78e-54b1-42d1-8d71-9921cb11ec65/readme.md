# Your Space — Design System

**Your Space** is a bilingual (English-first, Arabic secondary) personal relationship & event-planning mobile app. Users maintain contact groups, plan events, build guest lists with invite tracking, and get reminders to reciprocate invitations they've received. Mobile-only (Flutter, Material 3). Warm and personal — this is about someone's real relationships and social obligations, not a corporate SaaS tool.

**Sources provided:** Flutter theme files (verbatim token source of truth) at `uploads/app_colors.dart`, `app_font_weight.dart`, `app_shadows.dart`, `app_text_styles.dart`, `app_theme.dart`. No Figma, no codebase screens, no logo files were provided.

**No logo was provided.** Wherever a mark would go, render "Your Space" in Cairo extra-bold. Do not invent a logo.

## CONTENT FUNDAMENTALS

- **Voice:** warm, personal, trustworthy. Talks about *people and occasions*, never "records" or "entries". "Sara hasn't been invited back yet" — not "Reciprocity pending".
- **Person:** second person, "you/your" ("Your events", "People you owe an invite"). The app addresses the user like a thoughtful friend, not a system.
- **Casing:** sentence case everywhere — titles, buttons, labels ("Add guests", not "Add Guests"). ALL-CAPS only for Inter micro-eyebrows (e.g. "UPCOMING", "THIS WEEK").
- **Bilingual:** English-first; Arabic secondary. All fonts (Cairo/Tajawal) are Arabic-optimized so mixed script never breaks. Keep strings short and translatable; avoid idioms.
- **Emoji:** none in UI chrome. User-generated content may contain them.
- **Numbers & counts:** humanized ("12 guests · 8 confirmed"), middot separators.
- **CTAs:** verb-first, specific: "Create event", "Send invites", "Remind me later".

## VISUAL FOUNDATIONS

- **Color:** one strong brand red `#B11E2E` on a calm near-white world (`#FAFAFA` app bg, white cards). Red is spent deliberately: primary CTAs, active nav states, key accents. Soft red `#F8E5E8` for selected/tinted fills. Brand black `#0B0B0B` for dark surfaces/headers only. Semantic green/amber/blue appear only as status (confirmed/pending/info) — usually as soft-tint pills.
- **Type:** Cairo (extra-bold/bold) for display & headlines; Tajawal for titles, body, UI; Inter semi-bold, +0.14em tracked, 11px, uppercase for Latin micro-labels only. Body line-height is generous (1.7) for Arabic legibility.
- **Shape:** friendly and round. Buttons are 52px pills (24px radius); cards 28px; inputs 14px filled with no border; bottom sheets 28px top radius. Nothing sharp.
- **Elevation:** flat design, shadow-only depth. Cards: `--shadow-soft` (0 4 24 @6%). Overlays: `--shadow-soft-lg`. Primary CTAs get the red-tinted `--shadow-brand` (0 8 28 rgba(177,30,46,.22)) — never neutral shadow on red. No Material elevation tints, no borders on cards.
- **Inputs:** filled `#F5F5F5`, borderless at rest; 1.5px primary border on focus; error border `#DC2626`. Hint text `#A3A3A3`.
- **States:** hover (web previews) darken primary to `#8B1623`; press = slight scale-down (0.98) + darker fill; disabled = 40% opacity. No ripple recreation needed in HTML.
- **Motion:** Material 3 defaults — quick fades and eased slides (~200–250ms, ease-out). Bottom sheets slide up. Shimmer (`#E5E5E5`→`#F5F5F5`) for loading. No bounces or playful springs.
- **Layout:** mobile 390px frame, 16px side gutters, cards stacked with 12–16px gaps. AppBar: white, flat, centered title (Tajawal bold 22). Fixed bottom nav / bottom CTA bars sit on white with soft shadow.
- **Dividers:** hairline `#E5E5E5`, full-bleed inside lists.
- **Imagery:** no brand imagery provided; use avatars (initials on soft tints) and leave photo slots as placeholders.

## ICONOGRAPHY

- Material Symbols (Rounded), the Material 3 icon set matching the Flutter app — loaded from the Google Fonts CDN icon font (`.msr` class in the kit). Weight ~400, filled for active nav states (`FILL 1`), outlined otherwise. 24px default, 20px in dense rows.
- No custom SVG icon set was provided; no icon binaries are shipped. **Substitution flag:** if the production app uses `Icons.*` (Material Icons classic) rather than Material Symbols, swap the CDN link.
- No emoji-as-icons, no unicode glyph icons.
- Avatars: initials (Tajawal bold) on `--brand-red-soft` or neutral tints — the app's fallback identity pattern.

## Fonts

All three families (Cairo, Tajawal, Inter) load from the Google Fonts CDN — no font binaries were provided or shipped. Matches the app exactly (it uses `google_fonts` package).

## Index

- `styles.css` → imports `tokens/colors.css`, `tokens/typography.css`, `tokens/shape.css`
- `guidelines/` — foundation specimen cards (colors, type, shape, shadows, spacing)
- `components/core/` — Button, IconButton, Chip, Badge, Avatar
- `components/forms/` — Input, Select, Checkbox, Radio, Switch
- `components/display/` — Card, ListTile, EmptyState
- `components/navigation/` — AppBar, BottomNav, Tabs
- `components/feedback/` — Dialog, Snackbar
- `ui_kits/app/` — Your Space mobile app kit: Home, Event detail (guest list + invite tracking), People/groups, Create event (index.html is the interactive entry)
- `SKILL.md` — agent skill entry point

**Intentional additions** (no component source existed; standard set sized for a Material 3 mobile app): ListTile, Avatar, AppBar, BottomNav, EmptyState — core furniture of the app's list-driven screens.
