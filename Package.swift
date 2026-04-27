// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "iOSAppHackingLab",
    platforms: [
        .iOS(.v17),
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
