# Design ↔ Code conformance log

One-way record of syncing the Claude Design canvas exports in `doc/design/*.dc.html`
**from** the shipped Flutter code. Code is the source of truth; the canvases carry no
"differs from code" commentary — that lives only here.

Each entry: what code state the canvases were brought up to, which artboards changed,
and any drift left unresolved.

---

## 2026-09-10 — Event Screens (`Event Screens.dc.html`) — copy sync + new artboard

Final canvas file. Copy taken verbatim from `events.*` / `common.*` in `en.json` / `ar.json`.
This completes the feature-by-feature sync of all three `.dc.html` files.

### Copy synced (existing artboards)

| `t` key | Change | Source key |
|---|---|---|
| `searchEvents` | AR → "ابحث عن مناسبة" | `events.list.searchHint` |
| `eventNameAr` | EN + AR → "… (Arabic, optional)" | `events.form.nameArLabel` |
| `eventDate` | EN + AR → "Event date (optional)" | `events.form.dateLabel` |
| `noGuestsYetHint` | EN + AR → drop trailing period, match wording | `events.details.noGuestsHint` |
| `filterInvited` / `filterSkipped` | AR → "مدعو" / "تم تخطيه" | `events.guests.statusInvited` / `statusSkipped` |
| `guestsEmptyTitle` | AR → "لم تتم إضافة ضيوف إلى هذه المناسبة بعد" | `events.guests.emptyTitle` |
| `actionMarkInvited` / `actionRevert` | AR → "تحديد كمدعو" / "الرجوع لغير مدعو" | `events.guests.actionMarkInvited` / `actionRevert` |
| `phoneCall` | AR "اتصال هاتفي" → "مكالمة هاتفية" | `common.inviteMethod.phoneCall` |
| `tabPeople` | AR "أشخاص" → "الأشخاص" | `events.addGuests.peopleTab` |
| `suggestionsTitle` | AR "اقتراحات المعاملة بالمثل" → "اقتراحات المجاملة" | `events.reciprocity.title` |
| `suggestionsEmptyTitle` | EN + AR → add trailing period | `events.reciprocity.emptyTitle` |

Keyless demo strings left as-is: `eventsEmptyBody`, `eventNamePh`, `eventNameArPh`,
`notesEventPh`, the `hintNotes*` counters, `editVal*` / `newValName` / `noDateSet` sample
values, `totalGuests`, `notInvitedLabel` / `invitedLabel` / `skippedLabel` (lowercase
summary-line words — the capitalised `events.guests.status*` keys are the filter chips,
mapped separately), `allGroups`, `guestsEmptyBody`, `suggestionsEmptyBody`.

### New artboard — **unverified, needs Claude Design review**

- **`5 (current build) · Add guests — 6 tabs`** — cloned from the section-5 "By-group tab"
  frame, with the `Tabs` bar bound to a new `tabs6` array (People / By group / By subgroup /
  By governorate / By city / By neighborhood) and the "By governorate" tab shown active,
  matching `add_guests_screen.dart` + its six `add_guests_by_*_tab.dart` files. Body reuses
  the generic entity-row + soft "Add" button pattern (mock data stands in). The original
  2-tab frames in section 5 were left as the historical reference.
- DCLogic: `strings()` gained `tabBySubGroup`, `tabByGovernorate`, `tabByCity`,
  `tabByNeighborhood` in both branches (from `events.addGuests.by*Tab`); `renderVals()`
  gained `tabs6`.

### Drift reported, not fixed

- **Event details** now has a third CTA/link, "Reciprocity suggestions"
  (`events.details.reciprocitySuggestionsCta`), alongside Manage guests / Add guests — the
  canvas details artboards show only the two buttons. Small within-artboard drift, left for
  a future Claude Design rebuild.
- The `groupFilter` chips-vs-dropdown `data-props` knob on this canvas is a design fiction
  (the real Event guests screen has a single group filter) — harmless, left in place.

### Token CSS

Unchanged — still in sync with `lib/core/theme/`.

### Sync status — all canvases done

`Auth Flow.dc.html`, `Core Screens.dc.html`, `Event Screens.dc.html` have each had a
code→canvas pass. Outstanding items across the whole design set:

- Small within-artboard drift not hand-patched (per skill): Auth Register gender field
  (authored as `2c`), Groups Arabic-name + "Manage subgroups", Home greeting line + stale
  "Soon" badge, Person details Notes section, Event details "Reciprocity suggestions" CTA.
- **No canvas file exists** for `onboarding`, `settings`, and the `classification`
  management screens (Subgroups / Cities / Neighborhoods) — these need a dedicated Claude
  Design pass to create the `.dc.html`; a code→canvas sync cannot.
- All newly authored artboards (`2c` in Auth, the 4 wizard steps + filters sheet in Core,
  the 6-tab Add guests in Events) are flagged **unverified** and need a Claude Design review.

### Recommended next step

Open each canvas in Claude Design, verify the authored artboards render and match their
siblings, then either accept them or rebuild the flagged within-artboard drift there.

---

## 2026-09-10 — Core Screens, Run A (`Core Screens.dc.html`) — copy sync only

Run scope: existing artboards' `strings()` map only. No layout changes, no new artboards.
Copy taken verbatim from `assets/translations/{en,ar}.json`.

### Copy synced

| `t` key | Change | Source key |
|---|---|---|
| `emptyHomeBody` | EN + AR → "Groups help you organize who's who…" | `home.emptySubtitle` |
| `emptyHomeCta` | AR → "أنشئ مجموعتك الأولى" | `home.emptyAction` |
| `searchGroups` | AR → "ابحث عن مجموعة" | `groups.list.searchHint` |
| `invitedYou` | AR → "دعاك من قبل" | `people.list.reciprocityBadge` |
| `peopleEmptyTitle` | EN "Nobody in Neighbours yet" → "Nobody in this group yet"; AR matched | `people.list.emptyTitle` |
| `recipTitle` | AR → "لقد دعاك Sara من قبل" | `people.details.reciprocityBanner` |
| `emptyOccTitle` | AR → "لا يوجد شيء مسجّل مع Omar بعد" | `people.details.emptyTitle` |
| `phoneCall` | AR "اتصال هاتفي" → "مكالمة هاتفية" | `common.inviteMethod.phoneCall` |
| `occasion` | EN "Occasion" → "Occasion name"; AR "المناسبة" → "اسم المناسبة" | `people.occasion.nameLabel` |
| `whenQ` | EN "When was it?" → "Date"; AR "متى كانت؟" → "التاريخ" | `people.occasion.dateLabel` |
| `dateHint` | EN + AR → drop leading "Optional · " | `people.occasion.dateFutureHint` |
| `addOccTitle` | EN "Add an occasion" → "Add occasion" (AR already matched) | `people.occasion.addTitle` |

Keyless demo strings left as-is (no `.tr()` equivalent): `hiSubFull`, `hiSubEmpty`,
`groupsSub`, `peopleSub`, `eventsSub`, `groupsEmptyBody`, `peopleEmptyBody`, `groupNamePh`,
`recipBody`, `emptyOccBody`, `methodQ`, the computed group captions, and the hard-coded
demo person names in the People list / Person details markup.

### Drift reported — deferred to Run B (new-artboard authoring)

Handled in Run B below: the person wizard and the people filters sheet. Still open:

- **Groups form** now has an Arabic-name field (`groups.form.nameArLabel`) and the list has a
  "Manage subgroups" affordance (`groups.list.manageSubGroups`) — neither on the canvas.
- **Home** shows a time-of-day greeting line (`home.greetingMorning/Afternoon/Evening`) above
  the "Hi {name}" line; canvas has only the one line. The Events row's **"Soon" badge** is
  stale — Events is a shipped feature.
- **Person details** now has a Notes section (`people.details.notesTitle`); not on the canvas.

Each is a small within-artboard change, so per the skill it is reported here for a future
Claude Design rebuild rather than hand-patched into the existing artboards.

### Gaps — no canvas file exists (recommend a dedicated design pass)

`onboarding` (3-slide carousel, `onboarding.page1–3*`), `settings` (profile form, avatar,
change-password link, logout, delete-account dialog — `settings.*`), and the three
**classification management** screens (Subgroups / Cities / Neighborhoods — `classification.*`).
These have no `.dc.html` to author into.

### Token CSS

Unchanged — verified in sync during the 2026-09-10 auth run; `lib/core/theme/` has not moved.

---

## 2026-09-10 — Core Screens, Run B (`Core Screens.dc.html`) — new artboards

Authored a new canvas section, **"3 (current build) · Add / edit person — 4-step wizard"**,
placed between the existing People section (section 3) and Person details (section 4). The
stale single-sheet "Add / edit person" artboards in section 3 were left in place as the
historical reference; a reviewer may retire them.

### New artboards — **unverified, need Claude Design review**

| Artboard | Represents | Notes |
|---|---|---|
| Step 1 · Basic identity + photos | `person_wizard_step1_basic_identity.dart` | Name, Phone 1, Phone 2 (Optional), Gender chips (Male/Female), Photos header "0 / 6" + one dashed add-tile in a 3-col grid, photos hint. Step indicator (dot 1 current). Footer: Back hidden, Next. |
| Step 2 · Classification & location | `person_wizard_step2_classification_location.dart` | "Classification" → Group / Subgroup(disabled, "Pick a group first"); "Location" → Governorate / City(disabled) / Neighborhood(disabled); location hint. Step indicator (1 done, 2 current). |
| Step 3 · Family & relationships | `person_wizard_step3_relationships.dart` | One relationship-row card (Family member 1, remove ✕, relationship `Select`, person-search `Input`) + outlined "Add family member" button. Step indicator (1–2 done, 3 current). |
| Step 4 · Notes | `person_wizard_step4_notes.dart` | Multiline Notes input (hint + Optional). Step indicator (1–3 done, 4 current). Footer CTA → "Save person". |
| People list · filters sheet | `people_filter_sheet.dart` | Dimmed list + bottom sheet: "Filters" + "Clear all", Subgroup ("Pick a group first"), Location → Governorate ("All governorates") / City(disabled) / Neighborhood(disabled), "Done". |

All five are composed only from existing DS components (`AppBar`, `Input`, `Select`, `Chip`,
`Button`) and existing `var(--…)` tokens — no new component, no raw hex/px beyond the
step-indicator dot geometry (which mirrors the auth-flow OTP-cell inline pattern). The step
indicator is inline markup (no DS stepper component exists).

### DCLogic

- `strings()` (both branches): added `back`, `next`, `done`, `wizStepEyebrow1–4`, `wizName`,
  `wizPhone1/2`, `wizGender`, `genderMale/Female`, `wizPhotos`, `wizPhotosHint`, `wizAddPhoto`,
  `wizPrimary`, `wizClassification`, `wizLocationSection`, `wizGroup`, `wizGroupPh`,
  `wizAddGroup`, `wizSubGroup`, `wizPickGroupFirst`, `wizGovernorate`, `wizGovernoratePh`,
  `wizCity`, `wizPickGovFirst`, `wizNeighborhood`, `wizPickCityFirst`, `wizLocationHint`,
  `wizRelSection`, `wizFamilyMember1`, `wizRelTypePh`, `wizAddFamily`, `wizNotesHint`,
  `filtersTitle`, `filtersClearAll`, `filtersLocation`, `filtersSubGroup`, `filtersCity`,
  `filtersNb`, `filtersAllGov/AllCities/AllNb`. Values taken verbatim from `people.wizard.*`,
  `people.filters.*`, `common.*` in `en.json` / `ar.json` (Arabic step numerals localised).
- `renderVals()`: added `relationTypes` (static localised list) for the step-3 relationship
  `Select`.

### Verification

Tag balance `div` 237/237, `sc-if` 11/11, `x-import` 159/159; `node --check` on the DCLogic
block passes; all 125 distinct `{{ t.* }}` references resolve in both `strings()` branches;
`<helmet>` / `support.js` / `_ds_bundle.js` untouched.

### Still open (not authored)

- Groups Arabic-name field + "Manage subgroups"; Home greeting line + stale "Soon" badge;
  Person details Notes section — small within-artboard drift, see Run A entry.
- **Gaps with no canvas file**: `onboarding`, `settings`, `classification` management. These
  need their own `.dc.html` created by a design pass — out of scope for a code→canvas sync.

---

## 2026-09-10 — Auth feature (`Auth Flow.dc.html`)

Run scope: `auth` only (feature-by-feature sync; Core Screens and Event Screens still pending).
Primary locale resolved as `en` (`main.dart` — `fallbackLocale: Locale('en')`, no `startLocale`).
Copy taken verbatim from `assets/translations/{en,ar}.json`.

### Copy synced (existing artboards — no layout changes)

| Artboard | Change | Source key |
|---|---|---|
| 6 · Change password | `cpDoneMsg` "Password updated." → "Password updated. Please log in again." (EN) / matching AR | `auth.changePassword.doneMessage` |
| 2 · Register, 2b · Register — submitting | phone field label `t.phone` → `t.phoneOptional` ("Phone number (optional)" / "رقم الهاتف (اختياري)") | `auth.phoneOptional` |
| 3 · Confirm email | added a success-message line under the "Email confirmed" done state | `auth.confirmEmail.doneMessage` |

### State / DCLogic synced

- `cpSubmit()` now also rejects a new password equal to the current one, showing
  `pwSameAsCurrent` ("Choose a password different from your current one"), matching
  `change_password_screen.dart` (`auth.validation.newPasswordSameAsCurrent`).
- Added `reg.gender` to `state` and `regGenderIsMale/Female` + `regSetMale/Female` to
  `renderVals()` to back the new artboard below.
- New `strings()` keys in both branches: `phoneOptional`, `genderOptional`, `genderMale`,
  `genderFemale`, `otpDoneMsg`, `pwSameAsCurrent`.

### New artboard authored — **unverified, needs Claude Design review**

- **`2c · Register — with gender field (current build)`** — cloned from `2 · Register — default`,
  adds the optional Gender picker (two `Chip` components, Male/Female) between the Phone and
  Password fields, matching `register_form_fields.dart` (`GenderChipGroup` →
  `common.gender.male/female`, label `auth.genderOptional`). Artboards 2 / 2b were left on the
  pre-gender structure as the historical reference; a reviewer may retire them.

### Token CSS — verified in sync, not regenerated

`_ds/your-space-design-system-d7e9f78e…/tokens/{colors,typography,shape,icons}.css` were
diffed against `lib/core/theme/*.dart` (AppColors, AppTextStyles, AppFontWeight, AppShadows,
AppTheme). All values match — brand/semantic/surface/text colours, the full Cairo/Tajawal/Inter
type scale, radii, all four shadows (incl. `--shadow-brand` alpha `0.22`), component metrics.
No changes.

### Drift reported, not fixed

- **Login `loginView:'unverified'` inline state** — no code equivalent; `login_screen.dart`
  calls `pushNamed(confirmEmail)` on `Auth.EmailNotConfirmed`. Left as a demo affordance
  (its dashed in-frame note already describes the real routing).
- **OTP wrong / locked / expired copy** (`otpWrong`, `otpLocked`, `otpBad`) and
  **change-password "current password incorrect"** (`curWrong`) — server-driven messages with
  no `.tr()` key; canvas demo strings retained.
- Artboard 3's dashed note "→ Routes to Home (verified accounts)" — code actually routes to
  Login with a success snackbar. In-frame design commentary; left untouched.

### Pending (future runs)

- `Core Screens.dc.html` — person form is now a 4-step wizard (identity → classification +
  location → relationships → notes) with photos; no artboards for subgroup / city /
  neighborhood management, onboarding, or settings (profile / avatar / account deletion).
- `Event Screens.dc.html` — "Add guests" has 2 tabs; code has 6 (People, Group, Sub-group,
  Governorate, City, Neighborhood).
