# Alpaca Swift

This is a fork of [@AndrewBarba](https://github.com/AndrewBarba) alpaca-swift package. It is up to date (As of October 2024) to the Alpaca documentation.
A fully-typed, Linux compatible, [AlpacaSwift](https://alpaca.markets) library written in Swift 5.5.

#### Features

- Swift Package Manager
- 100% async/await
- SwiftNIO HTTP client via [AsyncHTTPClient](https://github.com/swift-server/async-http-client.git)
- 100% Unit Test Coverage

#### Documentation

[https://andrewbarba.github.io/alpaca-swift/](https://andrewbarba.github.io/alpaca-swift/)

## Requirements

- iOS 15.0+ | macOS 12.0+ | tvOS 15.0+ | watchOS 8.0+
- Xcode 8

## Integration
#### Swift Package Manager

You can use [The Swift Package Manager](https://swift.org/package-manager) to install `Alpaca` by adding the proper description to your `Package.swift` file:

```swift
// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "AlpacaSwift",
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
        )
    ],
    swiftLanguageVersions: [.version("5.5")]
)

```
Then run `swift build` whenever you get prepared.

Note that SwiftyJSON is a required dependency
