#!/usr/bin/env swift

import CryptoKit
import Foundation
import ImageIO

struct MediaManifest: Encodable {
    let generatedAt: String
    let repository: String
    let mediaCount: Int
    let media: [MediaEntry]
}

struct MediaEntry: Encodable {
    let path: String
    let type: String
    let width: Int
    let height: Int
    let bytes: Int
    let sha256: String
}

let fileManager = FileManager.default
let repositoryRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let artifactsURL = repositoryRoot.appendingPathComponent("artifacts", isDirectory: true)
let outputURL = artifactsURL.appendingPathComponent("media-manifest.json")
let supportedExtensions = Set(["png", "gif"])

guard fileManager.fileExists(atPath: artifactsURL.path) else {
    fputs("artifacts directory is missing\n", stderr)
    exit(1)
}

let mediaFiles = try fileManager
    .contentsOfDirectory(at: artifactsURL, includingPropertiesForKeys: [.fileSizeKey])
    .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
    .filter { !$0.lastPathComponent.hasPrefix("tmp-") }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

let entries: [MediaEntry] = try mediaFiles.map { fileURL in
    guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
          let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue
    else {
        throw ManifestError.unreadableImage(fileURL.path)
    }

    let data = try Data(contentsOf: fileURL)
    let digest = SHA256.hash(data: data)
        .map { String(format: "%02x", $0) }
        .joined()
    let path = fileURL.path.replacingOccurrences(of: repositoryRoot.path + "/", with: "")

    return MediaEntry(
        path: path,
        type: fileURL.pathExtension.lowercased(),
        width: width,
        height: height,
        bytes: data.count,
        sha256: digest
    )
}

let manifest = MediaManifest(
    generatedAt: ISO8601DateFormatter().string(from: Date()),
    repository: "jungyeons/iOSAppHackingLab",
    mediaCount: entries.count,
    media: entries
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
let manifestData = try encoder.encode(manifest)
try manifestData.write(to: outputURL, options: [.atomic])
print("Wrote \(outputURL.path.replacingOccurrences(of: repositoryRoot.path + "/", with: ""))")

enum ManifestError: Error {
    case unreadableImage(String)
}
