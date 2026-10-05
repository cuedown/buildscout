// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BuildScout",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "BuildScout", targets: ["BuildScout"])
    ],
    targets: [
        .executableTarget(
            name: "BuildScout",
            path: "Sources/BuildScout"
        ),
        .testTarget(
            name: "BuildScoutTests",
            dependencies: ["BuildScout"],
            path: "Tests/BuildScoutTests"
        )
    ]
)
