// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PrintBro",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "PrintBro"),
        .testTarget(name: "PrintBroTests", dependencies: ["PrintBro"]),
    ]
)
