// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iOSAppHackingLab",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "iOSAppHackingLab", targets: ["iOSAppHackingLab"])
    ],
    targets: [
        .executableTarget(
            name: "iOSAppHackingLab",
            path: "Sources/iOSAppHackingLab"
        )
    ]
)
