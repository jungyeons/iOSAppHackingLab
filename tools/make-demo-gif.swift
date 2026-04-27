import Foundation
import ImageIO
import UniformTypeIdentifiers

func usage() -> Never {
    fputs("Usage: swift tools/make-demo-gif.swift output.gif frame1.png frame2.png [...]\n", stderr)
    exit(64)
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 3 else {
    usage()
}

let outputPath = arguments[0]
let inputPaths = Array(arguments.dropFirst())
let outputURL = URL(fileURLWithPath: outputPath)
let frameDelay = 1.15
let maxPixelSize = 720

guard let gifType = UTType.gif.identifier as CFString?,
      let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, gifType, inputPaths.count, nil) else {
    fputs("Could not create GIF destination.\n", stderr)
    exit(1)
}

let gifProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [
        kCGImagePropertyGIFLoopCount: 0
    ]
]
CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

let frameProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [
        kCGImagePropertyGIFDelayTime: frameDelay
    ]
]

for path in inputPaths {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        fputs("Could not read \(path).\n", stderr)
        exit(1)
    }

    let thumbnailOptions: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
    ]

    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
        fputs("Could not decode \(path).\n", stderr)
        exit(1)
    }

    CGImageDestinationAddImage(destination, image, frameProperties as CFDictionary)
}

guard CGImageDestinationFinalize(destination) else {
    fputs("Could not finalize \(outputPath).\n", stderr)
    exit(1)
}

print("Wrote \(outputPath)")
