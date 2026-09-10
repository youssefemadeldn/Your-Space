
# Session Handoff — 2026-08-03

> **OUT OF PREVIOUS SESSION — NEW SESSION START**
>
> Read this file first. It contains everything from the prior session.

## What Was Done

- Walked Joe through the entire first-time App Store Connect submission for **Your Space** (Flutter iOS app, `com.yourspace.app`), start to finish, while simultaneously building a reusable global Claude Code skill from the process.
- Created the App Record in App Store Connect (final Name: **"Your Space – Gifts & Events"**, after an earlier name — "Your Space – Gift & Event Planner" — was first rejected for exceeding the 30-char limit, then for colliding with an existing App Store app name).
- Solved the recurring "Bundle ID not appearing in App Store Connect" issue via **Product → Archive** in Xcode (not manual portal registration), and separately diagnosed an "App Record Creation Error" as a Name-uniqueness issue rather than a Bundle ID problem, using Xcode's distribution logs.
- Drafted and filled all Version 1.0 metadata: Promotional Text, Description, Keywords, Subtitle, Copyright ("© 2026 Youssef Emad El Din").
- Built and deployed two on-brand static pages (using Your Space's real "Doorway" logo/red color) via Vercel drag-and-drop, since no site existed yet:
  - Support page: https://your-space-support.vercel.app/ (contact: youssefemad63.ye@gmail.com)
  - Privacy Policy page: https://your-space-privacy.vercel.app/ (content based on the Claude Code data audit, not guessed)
- Uploaded Build 1 (version 1.0.0) via Xcode Distribute App; resolved the "Missing Compliance" export-compliance question ("None of the algorithms mentioned above" — app only uses standard HTTPS/Keychain, no custom crypto).
- Ran a full Claude Code personal-data audit (see Key References) before answering the **App Privacy** questionnaire — confirmed data collected (own account: email/name/phone; "People"/guest data: name/phone, server-stored, no device Contacts permission; IP retained for session security) and confirmed **no third-party analytics/ads/crash-reporting/push/social-login/payment SDKs** anywhere in the codebase.
- Completed App Information: Category = Lifestyle (Primary), Content Rights = "No third-party content", Age Rating questionnaire (all None/No) → calculated **4+**.
- Set Pricing to Free ($0.00), all 175 countries/regions.
- Published App Privacy, then submitted the app: **status "Waiting for Review"** as of Aug 3, 2026, 6:22 PM (Submission ID below).
- Compiled all of the above into a global, reusable **SKILL.md** for Claude Code (not project-specific), iterated on it per Joe's feedback to add: a "Role" section (act as a decisive senior App Store specialist, not a menu of options), a "Hard rule" prohibiting the agent from editing Xcode-managed files directly (project.pbxproj, Info.plist, entitlements) — guide the user through Xcode's UI instead, an "Ongoing maintenance" section (proactively flag App Store Connect updates triggered by future code changes — new permissions, new SDKs, new data fields, new Capabilities, new crypto usage), and reordered Privacy Policy URL to live in the App Privacy section rather than with Support/Marketing URL, matching App Store Connect's actual UI layout.
- Delivered the finished skill file to Joe as a download; he'll place it at `~/.claude/skills/app-store-submission/SKILL.md` on his Mac so Claude Code picks it up globally.
- Also explained (separately, unrelated to Your Space) what claude.ai's "Instructions for Claude" account-wide setting is, and drafted an English version of instructions text for Joe to consider adding — he asked to revert to the original draft and is still deciding whether to add the "present options with a clear recommendation" nuance for personal-call decisions.

## Bugs Found

| # | Bug | Severity | Location | Evidence |
|---|---|---|---|---|
| 1 | Android release build will fail to reach the network | Medium (blocks Android release only, not the current iOS submission) | `android/app/src/main/AndroidManifest.xml` | Claude Code audit found `<uses-permission android:name="android.permission.INTERNET"/>` present only in the debug/profile manifest variants, missing from main/release |

## Key Findings / Decisions

- App Store Connect requires **Privacy Policy published before "Add for Review" works** — confirmed via Apple's own guidance; this ordering caught us once and is now baked into the skill.
- "App Record Creation Error... Name already being used" is about the **App Store listing Name** (must be globally unique across the whole Store), not the Bundle ID — a very easy thing to misdiagnose without checking Xcode's distribution logs.
- For apps using only standard HTTPS + Keychain (no bundled crypto library), the correct export-compliance answer is **"None of the algorithms mentioned above"** — not option 2, which a lot of online guides wrongly suggest.
- In App Store Connect's App Privacy questionnaire, data manually typed about other people (not sourced from the device's native Contacts) belongs under **"Contact Info,"** not the separate **"Contacts"** checkbox.
- Release setting is currently **"Automatically release this version"** (default) — Joe never explicitly confirmed whether he wants automatic or manual release; worth asking directly in the next session before the app is approved.

## Pending Tasks

- [ ] Check for Apple's App Review decision (email + App Store Connect), Submission ID below — typically within 48 hours
- [ ] Decide release timing: keep "Automatically release this version," or switch to manual release for launch-timing control — not yet decided
- [ ] Fix the Android `INTERNET` permission in `main`/`release` `AndroidManifest.xml` before any Android release build
- [ ] Place the delivered `appstore-submission-SKILL.md` at `~/.claude/skills/app-store-submission/SKILL.md` on his Mac (if not already done)
- [ ] Decide whether to add the "present options + clear recommendation for personal-call decisions" nuance to claude.ai's "Instructions for Claude" setting — still considering, not yet decided
- [ ] Optional housekeeping: consider consolidating the two separate Vercel projects (`your-space-support`, `your-space-privacy`) into one project with two routes — not urgent

## What's Next (ordered)

1. Wait for/check the App Review result for Your Space
2. If approved, decide on release timing and let it go live (or release manually)
3. Fix the Android INTERNET permission before targeting an Android release
4. Resume the underlying Your-Space Flutter feature work (Core Screens pass, then Event Screens pass — see `/areas/your-space.md` for full context, this predates and is independent of the App Store submission thread)

## Key References

- App Store Connect app: **Your Space – Gifts & Events**, Bundle ID `com.yourspace.app`
- Submission ID: `d958f4ac-3391-4c6e-bd82-66ed5108aebc` (submitted Aug 3, 2026, 6:22 PM)
- Support page: https://your-space-support.vercel.app/
- Privacy Policy page: https://your-space-privacy.vercel.app/
- Global skill file (delivered to Joe, to be placed at `~/.claude/skills/app-store-submission/SKILL.md`): `appstore-submission-SKILL.md`
- Memory: `/areas/your-space.md` (full project history), `/areas/appstore-submission-skill.md` (skill-building notes), `/preferences.md`

## Clarifications & Decisions

| Question | Answer |
|---|---|
| Screenshots ready? | Yes, already had iPhone 6.5" set |
| Support/Marketing URL ready? | No — built a quick Vercel page instead |
| Support contact email? | youssefemad63.ye@gmail.com |
| App Store Name after the naming conflict? | "Your Space – Gift & Event Planner" → too long → "Your Space – Gifts & Events" |
| Where should the global Claude Code skill live? | `~/.claude/skills/app-store-submission/SKILL.md` |
| Automatic or manual release timing? | Not yet decided — still on the default "Automatically release this version" |
| Add "options + recommendation" nuance to Instructions for Claude? | Not yet decided — reverted to the original draft for now, will consider separately |

## Notes

- App Review sign-in credentials (test account email/password) and the reviewer's personal contact phone number were entered directly into App Store Connect during the session — intentionally not recorded here or in memory.
