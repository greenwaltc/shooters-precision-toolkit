// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "apple_flavors",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "8.27.7")),
        // XcodeProj 8 declares macOS 10.13; later AEXML releases raise that floor.
        .package(url: "https://github.com/tadija/AEXML.git", exact: "4.7.0"),
    ],
    targets: [
        .executableTarget(name: "apple_flavors", dependencies: ["XcodeProj", "AEXML"], path: "Sources"),
    ]
)
