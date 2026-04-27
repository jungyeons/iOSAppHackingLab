# Architecture

iOSAppHackingLab is a Swift Package that builds a SwiftUI app without requiring a full Xcode project.

## Layers

- `Models`: data-driven lab definitions, including risk text, inspection hints, evidence prompts, and completion criteria.
- `Store`: observable app state for progress, notes, lab actions, and Markdown report generation.
- `Security`: platform API wrappers used for safer comparisons, such as Keychain storage.
- `Views`: SwiftUI navigation, lab detail pages, reusable sections, and lab action panels.

## Data Flow

1. `ContentView` lists the lab definitions from `LabChallenge.seed`.
2. `ChallengeDetail` renders the selected lab's risk model, practice steps, evidence prompts, notes, and report controls.
3. Lab action views call methods on `LabStore`.
4. `LabStore` performs intentionally weak local behavior, records console-style output, persists notes/progress in `UserDefaults`, and generates a Markdown study report.

## Persistence

- Progress: `UserDefaults` key `lab.progress.completedChallengeIDs`.
- Notes: `UserDefaults` key `lab.progress.notes`.
- Vulnerable storage lab: `UserDefaults` keys `lab.username` and `lab.password`.
- Safer storage comparison: Keychain generic password item under service `iOSAppHackingLab.local-lab`.

## Current Platform Shape

The package currently targets macOS so it can build with the installed command line tools. The UI and store are intentionally kept small and data-driven so the same lab model can later be reused from an Xcode iOS Simulator target.
