# Architecture

iOSAppHackingLab shares one SwiftUI codebase between a Swift Package macOS app and a native Xcode iOS Simulator target.

## Layers

- `Models`: data-driven lab definitions, including risk text, inspection hints, evidence prompts, and completion criteria.
- `Store`: observable app state for progress, notes, lab actions, Markdown report generation, and sanitized report export.
- `Security`: platform API wrappers and helpers used for safer comparisons, such as Keychain storage, redacted logging, and a signed entitlement API client stub.
- `SelfCheck`: command-line validation for core redaction and report-generation behavior.
- `Views`: SwiftUI navigation, lab detail pages, reusable sections, and lab action panels.
- `iOSAppHackingLab.xcodeproj`: native iOS app target and shared scheme for Simulator builds.
- `.github/workflows/self-check.yml`: CI validation and public-safe demo media artifact upload.

## Data Flow

1. `ContentView` lists the lab definitions from `LabChallenge.seed`.
2. `ChallengeDetail` renders the selected lab's risk model, practice steps, evidence prompts, notes, and report controls.
3. Lab action views call methods on `LabStore`.
4. `LabStore` performs intentionally weak local behavior, records console-style output, persists notes/progress in `UserDefaults`, and generates Markdown study reports.
5. `ChallengeDetail` exposes a sanitized report export flow using SwiftUI `fileExporter` and a Markdown `FileDocument`.
6. `swift run iOSAppHackingLab --self-check` runs isolated checks without launching the app window.
7. `xcodebuild` builds the same Swift sources into `iOSAppHackingLab.app` for iOS Simulator.
8. `tools/verify-demo-media.swift` validates screenshot and GIF dimensions in CI.
9. GitHub Actions uploads sanitized screenshots, GIFs, and selected docs as `iosapphackinglab-demo-media`.

## Persistence

- Progress: `UserDefaults` key `lab.progress.completedChallengeIDs`.
- Notes: `UserDefaults` key `lab.progress.notes`.
- Vulnerable storage lab: `UserDefaults` keys `lab.username` and `lab.password`.
- Tamperable entitlement lab: `UserDefaults` key `lab.premium.enabled`.
- Server-authoritative comparison cache: `UserDefaults` key `lab.premium.serverClaim`, containing signed claim fields and a P256 signature.
- Safer storage comparison: Keychain generic password item under service `iOSAppHackingLab.local-lab`.
- Safer logging comparison: `RedactingLogger` emits event-style logs without raw account or token values.

## Entitlement Model

The intentionally weak path stores premium access in `lab.premium.enabled`. The safer comparison uses `SimulatedEntitlementAuthority` to model a trusted issuer response and caches a signed display claim in `lab.premium.serverClaim`.

The cached claim includes a hashed account, plan, premium decision, issuer key ID, expiration, and signature. `verifyServerEntitlementCache()` grants access only when the signature validates, the issuer key matches, and the claim is not expired.

This is a local teaching model, not a real backend. In a production app, the authoritative decision should come from a trusted service, App Store receipt validation, or a cryptographically verifiable claim whose private signing material is kept server-side, not embedded in the app. The example production contract is documented in `docs/SIGNED_ENTITLEMENT_API.md`.

`SignedEntitlementAPIClient` is a Swift async stub for that production boundary. It builds the public-key discovery request, builds the signed-claim request with idempotency, and decodes the example JSON envelope. `SelfCheck` verifies the stub stays aligned with the documented API contract.

## Report Export Evidence

`docs/REPORT_EXPORT_FLOW.md` captures the actual iOS `fileExporter` path: prepare sanitized report, tap `Export .md`, choose the storage location, save, then reopen the exported Markdown from the Files app. These images are public-safe because the generated report redacts common token, password, account, and local path patterns before export.

## Current Platform Shape

- Swift Package: quick local macOS runs and self-check validation.
- Xcode project: iOS Simulator app target with generated Info.plist and shared scheme.
- Verified simulator: iPhone 17 Pro running iOS 26.4.1.
