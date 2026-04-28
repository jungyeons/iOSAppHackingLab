#!/usr/bin/env swift

import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

func usage() -> Never {
    fputs("Usage: swift tools/make-captioned-demo-gif.swift output.gif frame.png::Caption [...]\n", stderr)
    exit(64)
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 2 else {
    usage()
}

let outputPath = arguments[0]
let frameSpecs = Array(arguments.dropFirst())
let outputURL = URL(fileURLWithPath: outputPath)
let frameDelay = 1.55
let maxPixelHeight: CGFloat = 720

guard let gifType = UTType.gif.identifier as CFString?,
      let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, gifType, frameSpecs.count, nil) else {
    fputs("Could not create GIF destination.\n", stderr)
    exit(1)
}

CGImageDestinationSetProperties(
    destination,
    [
        kCGImagePropertyGIFDictionary: [
            kCGImagePropertyGIFLoopCount: 0
        ]
    ] as CFDictionary
)

for spec in frameSpecs {
    let parts = spec.components(separatedBy: "::")
    guard let path = parts.first, !path.isEmpty else {
        usage()
    }
    let caption = parts.dropFirst().joined(separator: "::")

    guard let image = NSImage(contentsOfFile: path),
          let rendered = render(image: image, caption: caption)
    else {
        fputs("Could not render \(path).\n", stderr)
        exit(1)
    }

    CGImageDestinationAddImage(
        destination,
        rendered,
        [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frameDelay
            ]
        ] as CFDictionary
    )
}

guard CGImageDestinationFinalize(destination) else {
    fputs("Could not finalize \(outputPath).\n", stderr)
    exit(1)
}

print("Wrote \(outputPath)")

func render(image: NSImage, caption: String) -> CGImage? {
    let sourceSize = image.size
    let scale = maxPixelHeight / sourceSize.height
    let size = NSSize(width: sourceSize.width * scale, height: maxPixelHeight)
    let output = NSImage(size: size)

    output.lockFocus()
    NSColor.white.setFill()
    NSRect(origin: .zero, size: size).fill()

    image.draw(
        in: NSRect(origin: .zero, size: size),
        from: NSRect(origin: .zero, size: sourceSize),
        operation: .copy,
        fraction: 1.0
    )

    let captionHeight: CGFloat = 86
    let captionRect = NSRect(x: 0, y: 0, width: size.width, height: captionHeight)
    NSColor(calibratedWhite: 0.0, alpha: 0.72).setFill()
    captionRect.fill()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byWordWrapping

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ]
    let textRect = captionRect.insetBy(dx: 18, dy: 18)
    caption.draw(in: textRect, withAttributes: attributes)

    output.unlockFocus()

    guard let tiff = output.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff)
    else {
        return nil
    }
    return bitmap.cgImage
}
