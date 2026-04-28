#!/usr/bin/env swift

import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

func usage() -> Never {
    fputs("Usage: swift tools/make-captioned-demo-gif.swift [--mobile-crop] output.gif frame.png::Caption [...]\n", stderr)
    exit(64)
}

var arguments = Array(CommandLine.arguments.dropFirst())
let shouldCropForMobile = arguments.first == "--mobile-crop"
if shouldCropForMobile {
    arguments.removeFirst()
}

guard arguments.count >= 2 else {
    usage()
}

let outputPath = arguments[0]
let frameSpecs = Array(arguments.dropFirst())
let outputURL = URL(fileURLWithPath: outputPath)
let frameDelay = shouldCropForMobile ? 1.15 : 1.55
let maxPixelHeight: CGFloat = shouldCropForMobile ? 640 : 720

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
          let rendered = render(image: image, caption: caption, shouldCropForMobile: shouldCropForMobile)
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

func render(image: NSImage, caption: String, shouldCropForMobile: Bool) -> CGImage? {
    let sourceSize = image.size
    let sourceRect: NSRect
    if shouldCropForMobile {
        let cropHeight = min(sourceSize.height, 1_760)
        sourceRect = NSRect(
            x: 0,
            y: sourceSize.height - cropHeight,
            width: sourceSize.width,
            height: cropHeight
        )
    } else {
        sourceRect = NSRect(origin: .zero, size: sourceSize)
    }

    let scale = maxPixelHeight / sourceRect.height
    let size = NSSize(width: sourceRect.width * scale, height: maxPixelHeight)
    let output = NSImage(size: size)

    output.lockFocus()
    NSColor.white.setFill()
    NSRect(origin: .zero, size: size).fill()

    image.draw(
        in: NSRect(origin: .zero, size: size),
        from: sourceRect,
        operation: .copy,
        fraction: 1.0
    )

    let captionHeight: CGFloat = shouldCropForMobile ? 74 : 86
    let captionRect = NSRect(x: 0, y: 0, width: size.width, height: captionHeight)
    NSColor(calibratedWhite: 0.0, alpha: 0.72).setFill()
    captionRect.fill()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byWordWrapping

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: shouldCropForMobile ? 13 : 18, weight: .semibold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ]
    let textRect = captionRect.insetBy(dx: shouldCropForMobile ? 12 : 18, dy: shouldCropForMobile ? 14 : 18)
    caption.draw(in: textRect, withAttributes: attributes)

    output.unlockFocus()

    guard let tiff = output.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff)
    else {
        return nil
    }
    return bitmap.cgImage
}
