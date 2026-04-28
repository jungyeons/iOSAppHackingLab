#!/usr/bin/env swift

import Foundation

struct MediaManifest: Decodable {
    let generatedAt: String
    let repository: String
    let mediaCount: Int
    let media: [MediaEntry]
}

struct MediaEntry: Decodable {
    let path: String
    let type: String
    let width: Int
    let height: Int
    let bytes: Int
    let sha256: String
}

func usage() -> Never {
    fputs(
        "Usage: swift tools/generate-release-draft.swift [--version v0.1.0] [--date YYYY-MM-DD] [--output docs/RELEASE_DRAFT.md]\n",
        stderr
    )
    exit(64)
}

var arguments = Array(CommandLine.arguments.dropFirst())
var version = "v0.1.0"
var date = currentDateString()
var outputPath = "docs/RELEASE_DRAFT.md"

while !arguments.isEmpty {
    let flag = arguments.removeFirst()
    guard let value = arguments.first else {
        usage()
    }

    switch flag {
    case "--version":
        version = value
    case "--date":
        date = value
    case "--output":
        outputPath = value
    default:
        usage()
    }

    arguments.removeFirst()
}

let fileManager = FileManager.default
let repositoryRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let manifestURL = repositoryRoot
    .appendingPathComponent("artifacts", isDirectory: true)
    .appendingPathComponent("media-manifest.json")
let outputURL = URL(fileURLWithPath: outputPath, relativeTo: repositoryRoot)

guard fileManager.fileExists(atPath: manifestURL.path) else {
    fputs("Run swift tools/generate-media-manifest.swift before generating release notes.\n", stderr)
    exit(1)
}

let manifest = try JSONDecoder().decode(MediaManifest.self, from: Data(contentsOf: manifestURL))
let mediaByType = Dictionary(grouping: manifest.media, by: \.type)
let pngCount = mediaByType["png"]?.count ?? 0
let gifCount = mediaByType["gif"]?.count ?? 0
let totalBytes = manifest.media.reduce(0) { $0 + $1.bytes }
let updatedEvidence = manifest.media
    .filter { entry in
        entry.path.contains("api-client")
            || entry.path.contains("export-history")
            || entry.path.contains("reopen-narrated")
    }
    .map { "- `\($0.path)` (\($0.type), \($0.width)x\($0.height), \($0.bytes) bytes)" }
    .joined(separator: "\n")

let draft = """
# GitHub Release Draft

Tag: \(version)
Title: iOSAppHackingLab \(version)
Target: `main`
Draft: true
Prerelease: false

## Summary

- Adds a captioned signed entitlement API client mock flow.
- Adds an in-app sanitized report export history panel with a GitHub Actions artifact link field.
- Regenerates the public demo media manifest and release-ready evidence notes.

## Demo Media Manifest

- Manifest: `artifacts/media-manifest.json`
- Repository: `\(manifest.repository)`
- Generated: `\(manifest.generatedAt)`
- GitHub Actions artifact: `iosapphackinglab-demo-media`
- Public media count: \(manifest.mediaCount)
- PNG screenshots: \(pngCount)
- GIF demos: \(gifCount)
- Total public media bytes: \(totalBytes.formatted())
- Validation command: `swift tools/verify-demo-media.swift`
- Manifest command: `swift tools/generate-media-manifest.swift`

## New Or Updated Evidence

\(updatedEvidence.isEmpty ? "- No highlighted evidence entries found." : updatedEvidence)

## Verification

- `xcodebuild -project iOSAppHackingLab.xcodeproj -scheme iOSAppHackingLab -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' -derivedDataPath .build/XcodeDerivedData CODE_SIGNING_ALLOWED=NO build`
- `swift run iOSAppHackingLab --self-check`
- `swift tools/verify-demo-media.swift`
- `swift tools/generate-media-manifest.swift`
- `swift tools/generate-release-draft.swift --version \(version) --date \(date)`

## Safety Notes

- Scope remains limited to `com.jungyeons.iosapphackinglab`.
- Demo media excludes simulator containers, private notes, real credentials, and unredacted local paths.
- This file is a release draft body only. Creating or publishing the GitHub release is a separate manual or confirmed step.

"""

try fileManager.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try draft.write(to: outputURL, atomically: true, encoding: .utf8)

let relativeOutput = outputURL.path.replacingOccurrences(of: repositoryRoot.path + "/", with: "")
print("Wrote \(relativeOutput)")

func currentDateString() -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
}
