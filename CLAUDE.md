# CLAUDE.md — Project Conventions + Coding Discipline

## Coding Discipline (Karpathy principles)

### 1. Think before coding
- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.

### 2. Simplicity first
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" that wasn't requested.
- If you write 200 lines and it could be 50, rewrite it.
- Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical changes
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Remove imports/variables/functions that YOUR changes made unused.
- Every changed line should trace directly to the user's request.

### 4. Goal-driven execution
Transform tasks into verifiable goals:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

---

## Environment

- **OS:** Windows 10/11
- **Framework:** Flutter (Dart)
- **CI/CD:** Codemagic
- **Browser Automation:** Playwright CLI (`@playwright/cli`)
- **Test Device:** Physical iPhone via USB
- **Shell:** PowerShell (use .ps1 scripts, not .sh)

## External Skills (installed globally)

### Axiom (iOS Development — 184 skills)
```powershell
# Install: in Claude Code terminal
/plugin marketplace add CharlesWiltgen/Axiom
```
Use Axiom skills for: SwiftUI patterns, App Review compliance, code signing debugging, StoreKit, performance profiling, iOS-specific architecture. Skills activate automatically on iOS keywords.

Key skills for our pipeline:
- `app-review-guidelines` — Apple Review compliance before submission
- `app-store-submission` — Submission workflow guidance
- `expert-review-checklist` — Final quality pass
- `in-app-purchases` — StoreKit 2 (if app has IAP)
- `build-debugging` — When Codemagic builds fail
- `code-signing` — Certificate and provisioning issues

### App Store Preflight (rejection scanner)
```powershell
# Install: in project directory
npx skills add truongduy2611/app-store-preflight-skills
```
Run BEFORE every App Store submission. Scans for: missing privacy manifests, undeclared entitlements, screenshot format errors, deprecated SDKs, IAP config issues.

**Mandatory workflow:** After Phase 5 (build), before Phase 5.5 (listing):
```
> Run app store preflight scan on this project
```
Fix all REJECTION-severity items. Fix WARNING items when possible.

---

## Playwright CLI Usage

- Always use `playwright-cli snapshot` before interacting — never guess refs
- Pattern: **snapshot → identify ref → act → snapshot (verify)**
- Save auth state after manual login: `playwright-cli state-save appstore_auth.json`
- Load auth state before automation: `playwright-cli state-load appstore_auth.json`
- If a 2FA prompt appears, STOP and ask the user to complete authentication
- Never commit `appstore_auth.json` (it's in .gitignore)

## Code Style

- Dart: follow `dart format` defaults (2-space indent, 80-char lines)
- Use `const` constructors wherever possible
- Prefer `final` over `var`
- All widgets: stateless unless they need local state
- Use trailing commas for better diffs
- Name files in `snake_case.dart`
- Name classes in `PascalCase`
- Name variables and functions in `camelCase`

## Architecture

- One screen per file in `lib/screens/`
- All routes defined in `lib/routes.dart` using GoRouter
- State management: Provider (simple apps) or Riverpod (complex)
- Business logic in `lib/services/`, never in widgets
- Constants and theme in `lib/utils/`
- Reusable widgets in `lib/widgets/`

## Do NOT

- Do NOT modify `ios/` directory files manually — Codemagic handles iOS build
- Do NOT use packages requiring CocoaPods manual setup unless confirmed Codemagic-compatible
- Do NOT hardcode colors — use `Theme.of(context)` everywhere
- Do NOT use `print()` for debugging — use `debugPrint()` or `log()`
- Do NOT commit API keys — use environment variables via `--dart-define`
- Do NOT use `flutter_test` imports in integration tests (use `integration_test`)
- Do NOT submit to App Store without running preflight scan first

## Testing

- Unit tests: `test/` directory
- Integration tests: `integration_test/` directory
- Screenshot tests: `integration_test/screenshot_test.dart`
- Run locally: `flutter test` (unit) or `flutter run` (on Android emulator)
- iOS testing: done via Codemagic or manually on physical iPhone

## Git

- Commit messages: `type: description` (feat, fix, chore, docs, test)
- Branch: `main` = production trigger for Codemagic
- Tag releases: `v1.0.0`, `v1.0.1`, etc.

## Screenshots

- App Store screenshots go in `screenshots/appstore/`
- Debug screenshots go in `screenshots/debug/`
- Integration test screenshots go in `screenshots/test/`

## Privacy Policy

- Template in `docs/privacy_policy.md`
- Host on GitHub Pages: `https://USERNAME.github.io/APP_NAME/privacy`
- Must be live before App Store submission

## Experience Log

After each completed app, update `experience.md` with:
1. What went wrong
2. What the fix was
3. Time spent on the issue
4. How to prevent it next time
