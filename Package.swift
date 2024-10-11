// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "alpaca-swift",
    platforms: [
        .iOS("15.0"),
        .macOS("12.0"),
        .tvOS("15.0"),
        .watchOS("8.0")
    ],
    products: [
        .library(name: "AlpacaSwift", targets: ["AlpacaSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.2")
    ],
    targets: [
        .target(
            name: "AlpacaSwift",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ]
        ),
        .testTarget(
            name: "AlpacaSwiftTests",
            dependencies: ["AlpacaSwift"]
        )
    ],
    swiftLanguageVersions: [.version("5.5")]
)
