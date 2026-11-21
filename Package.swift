// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PrintBro",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PrintBroCore"),
        .executableTarget(name: "PrintBro", dependencies: ["PrintBroCore"]),
        .testTarget(name: "PrintBroTests", dependencies: ["PrintBroCore"]),
    ]
)
