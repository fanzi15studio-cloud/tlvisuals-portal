// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "tesla-display",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "tesla-display", targets: ["TeslaDisplay"])
    ],
    targets: [
        .executableTarget(
            name: "TeslaDisplay",
            path: "Sources/TeslaDisplay"
        )
    ]
)
