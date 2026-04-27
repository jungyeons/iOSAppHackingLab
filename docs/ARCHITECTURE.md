# Architecture

iOSAppHackingLab shares one SwiftUI codebase between a Swift Package macOS app and a native Xcode iOS Simulator target.

## Layers

- `Models`: data-driven lab definitions, including risk text, inspection hints, evidence prompts, and completion criteria.
- `Store`: observable app state for progress, notes, lab actions, Markdown report generation, and sanitized report export.
- `Security`: platform API wrappers and helpers used for safer comparisons, such as Keychain storage and redacted logging.
- `SelfCheck`: command-line validation for core redaction and report-generation behavior.
- `Views`: SwiftUI navigation, lab detail pages, reusable sections, and lab action panels.
- `iOSAppHackingLab.xcodeproj`: native iOS app target and shared scheme for Simulator builds.

## Data Flow

1. `ContentView` lists the lab definitions from `LabChallenge.seed`.
2. `ChallengeDetail` renders the selected lab's risk model, practice steps, evidence prompts, notes, and report controls.
3. Lab action views call methods on `LabStore`.
4. `LabStore` performs intentionally weak local behavior, records console-style output, persists notes/progress in `UserDefaults`, and generates Markdown study reports.
5. `ChallengeDetail` exposes a sanitized report export flow using SwiftUI `fileExporter` and a Markdown `FileDocument`.
6. `swift run iOSAppHackingLab --self-check` runs isolated checks without launching the app window.
7. `xcodebuild` builds the same Swift sources into `iOSAppHackingLab.app` for iOS Simulator.

## Persistence

- Progress: `UserDefaults` key `lab.progress.completedChallengeIDs`.
- Notes: `UserDefaults` key `lab.progress.notes`.
- Vulnerable storage lab: `UserDefaults` keys `lab.username` and `lab.password`.
- Tamperable entitlement lab: `UserDefaults` key `lab.premium.enabled`.
- Server-authoritative comparison cache: `UserDefaults` key `lab.premium.serverClaim`.
- Safer storage comparison: Keychain generic password item under service `iOSAppHackingLab.local-lab`.
- Safer logging comparison: `RedactingLogger` emits event-style logs without raw account or token values.

## Entitlement Model

The intentionally weak path stores premium access in `lab.premium.enabled`. The safer comparison uses `SimulatedEntitlementAuthority` to model a trusted service response and caches only a display claim in `lab.premium.serverClaim`.

This is a local teaching model, not a real backend. In a production app, the authoritative decision should come from a trusted service, App Store receipt validation, or a cryptographically verifiable claim whose private signing material is not embedded in the app.

## Current Platform Shape

- Swift Package: quick local macOS runs and self-check validation.
- Xcode project: iOS Simulator app target with generated Info.plist and shared scheme.
- Verified simulator: iPhone 17 Pro running iOS 26.4.1.
