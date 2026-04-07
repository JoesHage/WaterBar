// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "WaterBar",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "WaterBarKit",
            targets: ["WaterBarKit"]
        ),
        .executable(
            name: "WaterBar",
            targets: ["WaterBar"]
        ),
    ],
    targets: [
        .target(
            name: "WaterBarKit",
            resources: [
                .process("Resources"),
            ]
        ),
        .executableTarget(
            name: "WaterBar",
            dependencies: ["WaterBarKit"]
        ),
        .testTarget(
            name: "WaterBarKitTests",
            dependencies: ["WaterBarKit"]
        ),
    ]
)
