# GitHub Release Draft

Tag: v0.1.0
Title: iOSAppHackingLab v0.1.0
Target: `main`
Draft: true
Prerelease: false

## Summary

- Adds a captioned signed entitlement API client mock flow.
- Adds an in-app sanitized report export history panel with a GitHub Actions artifact link field.
- Regenerates the public demo media manifest and release-ready evidence notes.

## Demo Media Manifest

- Manifest: `artifacts/media-manifest.json`
- Repository: `jungyeons/iOSAppHackingLab`
- Generated: `2026-04-28T09:30:24Z`
- GitHub Actions artifact: `iosapphackinglab-demo-media`
- Public media count: 23
- PNG screenshots: 16
- GIF demos: 7
- Total public media bytes: 15,494,605
- Validation command: `swift tools/verify-demo-media.swift`
- Manifest command: `swift tools/generate-media-manifest.swift`

## New Or Updated Evidence

- `artifacts/ios-simulator-entitlement-api-client-mock-captioned.gif` (gif, 878x1280, 169304 bytes)
- `artifacts/ios-simulator-entitlement-api-client-mock.gif` (gif, 331x720, 55843 bytes)
- `artifacts/ios-simulator-entitlement-api-client-mock.png` (png, 1206x2622, 1173367 bytes)
- `artifacts/ios-simulator-entitlement-api-client-ready.png` (png, 1206x2622, 1200260 bytes)
- `artifacts/ios-simulator-report-export-files-reopen-narrated.gif` (gif, 878x1280, 137079 bytes)
- `artifacts/ios-simulator-report-export-history.png` (png, 1206x2622, 1413082 bytes)

## Verification

- `xcodebuild -project iOSAppHackingLab.xcodeproj -scheme iOSAppHackingLab -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' -derivedDataPath .build/XcodeDerivedData CODE_SIGNING_ALLOWED=NO build`
- `swift run iOSAppHackingLab --self-check`
- `swift tools/verify-demo-media.swift`
- `swift tools/generate-media-manifest.swift`
- `swift tools/generate-release-draft.swift --version v0.1.0 --date 2026-04-28`

## Safety Notes

- Scope remains limited to `com.jungyeons.iosapphackinglab`.
- Demo media excludes simulator containers, private notes, real credentials, and unredacted local paths.
- This file is a release draft body only. Creating or publishing the GitHub release is a separate manual or confirmed step.
