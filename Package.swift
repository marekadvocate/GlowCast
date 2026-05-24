// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlowCast",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "GlowCastCore"),
        .executableTarget(
            name: "GlowCast",
            dependencies: ["GlowCastCore"]
        ),
        .testTarget(
            name: "GlowCastCoreTests",
            dependencies: ["GlowCastCore"]
        ),
    ]
)
