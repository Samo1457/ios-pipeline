# iOS App Automation Pipeline — Flutter + Windows + iPhone

## Overview

This skill automates the full lifecycle of shipping iOS (and Android) apps from a Windows PC using Flutter/Dart, Codemagic CI/CD, and a physical iPhone connected via USB for testing and screenshots.

**Stack:** Flutter (Dart) · Codemagic CI/CD · Playwright CLI · pymobiledevice3 · IosScreenCaptureTool · App Store Connect API

**Host OS:** Windows 10/11 (no Mac required)

**Browser Automation:** Playwright CLI (`@playwright/cli`) — used for research phase (web scraping), App Store Connect automation, and any browser-based task. Token-efficient, designed for coding agents, supports state persistence for authentication.

---

## Playwright CLI — Quick Reference

### Setup
```powershell
npm install -g @playwright/cli@latest
playwright-cli install-browser
playwright-cli install --skills    # install skills for Claude Code
```

### Core Commands
```powershell
# Navigation
playwright-cli open <url> --headed          # open URL (visible browser)
playwright-cli goto <url>                    # navigate to URL
playwright-cli snapshot                      # get accessibility tree with element refs

# Interaction
playwright-cli click <ref>                   # click element
playwright-cli fill <ref> "text"             # fill input
playwright-cli fill <ref> "text" --submit    # fill + press Enter
playwright-cli select <ref> "value"          # select dropdown
playwright-cli upload /path/to/file          # upload file
playwright-cli check <ref>                   # check checkbox
playwright-cli screenshot [filename]         # take screenshot

# Authentication persistence
playwright-cli state-save auth.json          # save cookies + localStorage
playwright-cli state-load auth.json          # restore session
```

### Workflow Pattern
Every interaction follows: **snapshot → identify ref → act → snapshot**
```powershell
playwright-cli snapshot           # see what's on screen
# Output: button "Submit" [ref=e15], textbox "Email" [ref=e3], ...
playwright-cli fill e3 "hello"    # interact using ref
playwright-cli snapshot           # verify result
```

---

## External Skills Integration

### Axiom (184 iOS development skills)
Installed as Claude Code plugin. Activates automatically on iOS-specific keywords.
Use for: SwiftUI patterns, App Review compliance, performance profiling, code signing issues, StoreKit.

Key commands:
- When build fails → Axiom build-debugging skill activates
- When reviewing for submission → Axiom app-review-guidelines + expert-review-checklist
- When implementing IAP → Axiom in-app-purchases (StoreKit 2)

### App Store Preflight (rejection scanner)
Installed via `npx skills add truongduy2611/app-store-preflight-skills`.
Contains 100+ Apple Review Guidelines rules categorized by severity (REJECTION / WARNING).

**MANDATORY: Run preflight scan before EVERY submission.**
```
> Run app store preflight scan on this project
```
Checks: privacy manifests, entitlements, Info.plist descriptions, screenshot formats, deprecated APIs, IAP configs.
Fix all REJECTION items. Fix WARNING items when feasible.

### Coding Discipline (Karpathy principles)
Merged into CLAUDE.md. Core rules:
1. Think before coding — surface assumptions, don't guess
2. Simplicity first — minimum code that solves the problem
3. Surgical changes — touch only what you must
4. Goal-driven execution — define success criteria, loop until verified

---

## Phase 1 — Research (find a shippable app idea)

### Goal
Find an iOS app idea with real demand, low competition, and shippable in ≤2 days.

### Method

1. **Generate search stems** — Pick a trending category (health, productivity, finance, utilities). Run 8 Google Autosuggest queries:
   - `[category] app for ...`
   - `[category] tracker ...`
   - `[category] app that ...`
   - `best [category] app ...`
   - `[category] reminder ...`
   - `[category] calculator ...`
   - `[category] log ...`
   - `[category] helper ...`

2. **Validate demand** — For each suggestion that looks promising, use Playwright CLI:
   ```powershell
   # Scrape Google Trends
   playwright-cli open "https://trends.google.com/trends/explore?q=QUERY" --headed
   playwright-cli snapshot
   playwright-cli screenshot ./research/trends_QUERY.png

   # Check Reddit for demand signals
   playwright-cli goto "https://www.reddit.com/search/?q=QUERY+app+iphone"
   playwright-cli snapshot
   # Look for phrases: "I wish there was...", "any app that...", "looking for..."
   ```
   - Note: phrases like "I wish there was an app that..." = strong signal

3. **Check saturation** — Query the iTunes Search API:
   ```
   https://itunes.apple.com/search?term=QUERY&entity=software&limit=25
   ```
   - < 10 results = low saturation (good)
   - 10-20 results = medium (check quality of existing apps)
   - 20+ results = high (pivot or find a niche angle)

4. **Score and rank** — For each candidate, assign:
   - Demand score (1-5): based on search volume + Reddit mentions
   - Saturation score (1-5): inverse of App Store competition
   - Feasibility score (1-5): can it be built with Flutter in ≤2 days?
   - **Total = Demand × Saturation × Feasibility**

5. **Pivot step (critical)** — If an idea is blocked by Apple API restrictions (e.g., AirPods companion apps need private APIs), pivot to an adjacent shippable idea. Example: "AirPods battery widget" (blocked) → "head-motion game using CMHeadphoneMotionManager" (shippable).

6. **Output** — Present top 3-5 ideas ranked by total score with one-line descriptions.

---

## Phase 2 — Build (Flutter/Dart)

### Project Setup

```bash
flutter create --org com.YOURORG --project-name APP_NAME ./
```

### Architecture Rules

- **State management:** Provider or Riverpod (no BLoC for simple apps)
- **Navigation:** GoRouter with named routes
- **File structure:**
  ```
  lib/
  ├── main.dart
  ├── app.dart              # MaterialApp + router
  ├── routes.dart           # All route definitions
  ├── models/               # Data classes
  ├── screens/              # One file per screen
  ├── widgets/              # Reusable components
  ├── services/             # Business logic, API calls
  └── utils/                # Helpers, constants, theme
  ```
- **Theme:** Define a single `ThemeData` in `utils/theme.dart`. Use Material 3.
- **Assets:** Place in `assets/` and declare in `pubspec.yaml`.

### Design Conventions

- Minimum touch target: 44x44 points
- Use `SafeArea` on every screen
- Support Dynamic Type (no hardcoded font sizes — use `Theme.of(context).textTheme`)
- Test both light and dark mode
- Include a splash screen (use `flutter_native_splash`)

### Build Command (local, Android only)

```bash
flutter build apk --release
flutter run  # on connected Android emulator
```

### Common Pitfalls

- Always run `flutter pub get` after editing `pubspec.yaml`
- If using platform channels, add iOS-specific code in `ios/Runner/`
- Don't use packages that require native iOS setup unless confirmed to work with Codemagic remote build

---

## Phase 3 — Test (Android Emulator + iPhone)

### Local Testing (Android Emulator)

```bash
flutter test                           # unit + widget tests
flutter run -d emulator-5554           # run on Android emulator
```

### Generate Integration Test for Screenshots

After building the app, automatically generate a test file that captures every screen:

```dart
// integration_test/screenshot_test.dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:APP_NAME/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture all screens', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_home');

    // ... repeat for each screen
  });
}
```

**Rules for generating this file:**
- Read `routes.dart` to get all route paths
- Navigate in logical order (home → settings → detail → etc.)
- Name screenshots as `XX_screen_name.png` (zero-padded)
- Add test data / mock state before navigating to data-dependent screens
- Wait 500ms after each navigation for animations

### iPhone Testing via USB (semi-automated)

When the app is installed on iPhone via TestFlight or direct install:

```powershell
# Capture current iPhone screen
.\IosScreenCaptureTool.exe --capture-frame .\screenshots\current.png

# Or via pymobiledevice3
pymobiledevice3 developer dvt screenshot .\screenshots\current.png
```

Claude Code workflow:
1. Prompt user: "Navigate to [screen name] on your iPhone, then press Enter"
2. Capture screenshot via IosScreenCaptureTool
3. Analyze the screenshot — check for:
   - UI elements present and correctly positioned
   - Text not truncated or overlapping
   - Colors matching the theme spec
   - Safe area respected (no content behind notch/home indicator)
4. Report issues or confirm screen passes
5. Move to next screen

---

## Phase 4 — App Store Screenshots (automated via Codemagic)

### Screenshot Specifications

| Device | Resolution | Required |
|--------|-----------|----------|
| iPhone 6.7" (15 Pro Max) | 1290 × 2796 | Yes |
| iPhone 6.1" (15 Pro) | 1179 × 2556 | Optional |
| iPad 12.9" (6th gen) | 2048 × 2732 | If universal |

**Rules:**
- 3 to 10 screenshots per device size
- First screenshot is the most important (shown in search results)
- No alpha channels, no transparency
- PNG or JPEG format

### Automation via Codemagic Integration Test

The integration test from Phase 3 runs on Codemagic's real devices. Screenshots are saved as build artifacts and downloaded automatically.

---

## Phase 5 — Build & Upload (Codemagic CI/CD)

### Codemagic handles:
1. iOS code signing (automatic with App Store Connect API key)
2. Building the IPA
3. Uploading to App Store Connect
4. Uploading to TestFlight

### Trigger
```bash
git add -A && git commit -m "v1.0.0 release" && git push origin main
```
Codemagic is configured to build on push to `main`.

---

## Phase 5.25 — App Store Preflight Scan (MANDATORY)

### Before creating the App Store listing, run the rejection scanner.

```
> Run app store preflight scan on this project
```

### What it checks:
- **Privacy:** PrivacyInfo.xcprivacy present and complete, NSPrivacyTracking declarations, required usage descriptions in Info.plist
- **Entitlements:** Declared capabilities match actual usage, no unused entitlements
- **Metadata:** Bundle ID format, version/build numbers, required icons (1024x1024), launch storyboard
- **Screenshots:** Correct resolutions, no alpha channels, minimum 3 per device
- **APIs:** No deprecated SDK calls, no private API usage
- **IAP:** StoreKit config consistency (if applicable), subscription group setup
- **Content:** Age rating alignment with actual content, COPPA compliance

### Severity levels:
- **REJECTION** — Fix before submission. Apple WILL reject.
- **WARNING** — Fix if possible. May cause rejection depending on reviewer.

### Action:
1. Fix all REJECTION items immediately
2. Fix WARNING items when feasible
3. Re-run scan to confirm all REJECTION items resolved
4. Document any accepted WARNING items in experience.md

### Also run Axiom's review checklist:
```
> Run expert review checklist for this app
> Check app review guidelines compliance
```

This catches higher-level design and UX issues that the code scanner misses.

---

## Phase 5.5 — App Store Connect Automation (Playwright CLI)

### First-time authentication (human, once)
```powershell
# Login to App Store Connect manually (2FA required, one-time)
playwright-cli open "https://appstoreconnect.apple.com" --headed
# → User logs in with Apple ID + 2FA
# → Save the session for reuse by Claude Code
playwright-cli state-save appstore_auth.json
```

### Automated App Store listing creation (Claude Code)
After Codemagic uploads the build, Claude Code fills the App Store listing:

```powershell
# 1. Load saved session
playwright-cli state-load appstore_auth.json
playwright-cli goto "https://appstoreconnect.apple.com/apps"

# 2. Create new app
playwright-cli snapshot
playwright-cli click <new-app-button-ref>

# 3. Fill app metadata
playwright-cli snapshot
playwright-cli fill <name-ref> "APP_NAME"
playwright-cli fill <subtitle-ref> "APP_SUBTITLE"
playwright-cli select <category-ref> "CATEGORY"
playwright-cli fill <bundle-id-ref> "com.YOURORG.APP_NAME"
playwright-cli fill <sku-ref> "APP_SKU"
playwright-cli click <create-ref>

# 4. Fill description and keywords
playwright-cli snapshot
playwright-cli fill <description-ref> "FULL_APP_DESCRIPTION"
playwright-cli fill <keywords-ref> "keyword1,keyword2,keyword3"
playwright-cli fill <privacy-url-ref> "https://USER.github.io/REPO/"
playwright-cli fill <support-url-ref> "https://USER.github.io/REPO/"

# 5. Upload screenshots
playwright-cli snapshot
playwright-cli upload ./screenshots/appstore/01_home.png
# ... repeat for each screenshot

# 6. Set pricing
playwright-cli goto "https://appstoreconnect.apple.com/apps/APP_ID/pricing"
playwright-cli snapshot
playwright-cli select <price-ref> "Free"

# 7. Complete age rating
playwright-cli goto "https://appstoreconnect.apple.com/apps/APP_ID/agerating"
playwright-cli snapshot
# Select "None" for all violence/adult content questions
playwright-cli click <none-ref>
# ... fill all required fields

# 8. Verification screenshot for human review
playwright-cli screenshot ./verification/appstore_listing_complete.png
```

### Important Notes
- `appstore_auth.json` is in `.gitignore` — NEVER commit authentication state
- Apple 2FA sessions expire after ~30 days. Re-authenticate when expired.
- Claude Code fills everything but does **NOT** click "Submit for Review" — that's always human.
- If Playwright detects a 2FA prompt, it stops and asks the user to complete authentication.

---

## Phase 6 — Review (Human)

Before clicking "Submit for Review":

1. **Check the verification screenshot** — `./verification/appstore_listing_complete.png`
2. **Open App Store Connect** — verify all fields are correct
3. **Test on real device** — Open TestFlight build, test all main flows
4. **Privacy policy** — Is the URL live and accessible?
5. **App Review Guidelines** — Does the app comply?
   - No private APIs used
   - No misleading metadata
   - Minimum viable functionality (not a "demo" app)
   - If using camera/location/contacts, justify in Info.plist

→ **Submit for Review** ✅

---

## File Reference

| File | Purpose |
|------|---------|
| `SKILL.md` | This file — master pipeline instructions |
| `CLAUDE.md` | Project conventions for Claude Code |
| `experience.md` | Lessons learned, error solutions |
| `codemagic.yaml` | CI/CD configuration |
| `appstore_auth.json` | Saved App Store Connect session (in .gitignore) |
| `scripts/research.ps1` | Research phase automation (Playwright CLI + iTunes API) |
| `scripts/screenshot_capture.ps1` | iPhone screenshot capture via USB |
| `scripts/appstore_upload.ps1` | App Store Connect listing automation |
| `scripts/screenshot_test_generator.dart` | Generates Flutter integration test |
| `docs/SETUP_GUIDE.md` | Human setup tutorial |
| `docs/PROCESS.md` | Process overview document |
