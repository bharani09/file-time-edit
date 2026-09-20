// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FileTimeEdit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FileTimeCore", targets: ["FileTimeCore"]),
        .executable(name: "FileTimeEdit", targets: ["FileTimeEdit"])
    ],
    targets: [
        .target(name: "FileTimeCore"),
        .executableTarget(
            name: "FileTimeEdit",
            dependencies: ["FileTimeCore"]
        ),
        .testTarget(
            name: "FileTimeCoreTests",
            dependencies: ["FileTimeCore"]
        )
    ]
)