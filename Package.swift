// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppWhitehackLab",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AppWhitehackLab", targets: ["AppWhitehackLab"])
    ],
    targets: [
        .executableTarget(
            name: "AppWhitehackLab",
            path: "Sources/AppWhitehackLab"
        )
    ]
)
