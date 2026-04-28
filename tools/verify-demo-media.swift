#!/usr/bin/env swift

import Foundation
import ImageIO

struct MediaIssue: CustomStringConvertible {
    let path: String
    let message: String

    var description: String {
        "\(path): \(message)"
    }
}

let fileManager = FileManager.default
let repositoryRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let artifactsURL = repositoryRoot.appendingPathComponent("artifacts", isDirectory: true)
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

if mediaFiles.isEmpty {
    fputs("No demo media found in artifacts\n", stderr)
    exit(1)
}

var issues: [MediaIssue] = []

for fileURL in mediaFiles {
    let path = fileURL.path.replacingOccurrences(of: repositoryRoot.path + "/", with: "")
    guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
        issues.append(MediaIssue(path: path, message: "could not open image source"))
        continue
    }

    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
        issues.append(MediaIssue(path: path, message: "could not read image properties"))
        continue
    }

    guard
        let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
        let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue
    else {
        issues.append(MediaIssue(path: path, message: "missing pixel dimensions"))
        continue
    }

    let byteCount = ((try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    let isGIF = fileURL.pathExtension.lowercased() == "gif"
    let minimumWidth = isGIF ? 300 : 1_000
    let minimumHeight = isGIF ? 600 : 2_000

    if width < minimumWidth || height < minimumHeight {
        issues.append(
            MediaIssue(
                path: path,
                message: "expected at least \(minimumWidth)x\(minimumHeight), got \(width)x\(height)"
            )
        )
    }

    if height <= width {
        issues.append(MediaIssue(path: path, message: "expected portrait simulator media, got \(width)x\(height)"))
    }

    if byteCount <= 0 {
        issues.append(MediaIssue(path: path, message: "file is empty"))
    }

    print("ok \(path) \(width)x\(height) \(byteCount) bytes")
}

if !issues.isEmpty {
    fputs("Demo media dimension check failed:\n", stderr)
    for issue in issues {
        fputs("- \(issue)\n", stderr)
    }
    exit(1)
}

print("Demo media dimension check passed for \(mediaFiles.count) files.")
