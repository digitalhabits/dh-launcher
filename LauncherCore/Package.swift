// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LauncherCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "LauncherCore", targets: ["LauncherCore"]),
    ],
    targets: [
        .target(
            name: "LauncherCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "LauncherCoreTests",
            dependencies: ["LauncherCore"]
        ),
    ]
)
