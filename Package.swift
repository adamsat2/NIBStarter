// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NIBStarter",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        // Runtime Libraries (iOS & macOS)
        .library(
            name: "NIBStarter",
            targets: ["NIBStarter"]
        ),
        .library(
            name: "NIBStarterObjC",
            targets: ["NIBStarterObjC"]
        ),
        // Build-Time Validator Executable & Plugins
        .executable(
            name: "nib-validator",
            targets: ["NIBValidator"]
        ),
        // Developer CLI (Templates + Storyboard Stripper)
        .executable(
            name: "nibstarter",
            targets: ["NIBStarterCLI"]
        ),
        // Build Tool & Command Plugins
        .plugin(
            name: "NIBValidatorPlugin",
            targets: ["NIBValidatorPlugin"]
        ),
        .plugin(
            name: "NIBValidateCommandPlugin",
            targets: ["NIBValidateCommandPlugin"]
        ),
        .plugin(
            name: "NIBConvertPlugin",
            targets: ["NIBConvertPlugin"]
        ),
        .plugin(
            name: "NIBInstallTemplatesPlugin",
            targets: ["NIBInstallTemplatesPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "8.24.0")
    ],
    targets: [
        // MARK: - Component 1: Runtime
        .target(
            name: "NIBStarter",
            dependencies: []
        ),
        .target(
            name: "NIBStarterObjC",
            dependencies: [],
            publicHeadersPath: "include"
        ),

        // MARK: - Component 2: Build-Time & Command Validator
        .target(
            name: "NIBValidatorCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .executableTarget(
            name: "NIBValidator",
            dependencies: [
                "NIBValidatorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .plugin(
            name: "NIBValidatorPlugin",
            capability: .buildTool(),
            dependencies: ["NIBValidator"]
        ),
        .plugin(
            name: "NIBValidateCommandPlugin",
            capability: .command(
                intent: .custom(
                    verb: "nibstarter-validate",
                    description: "Validate XIB Contracts with NIBStarter"
                ),
                permissions: []
            ),
            dependencies: ["NIBValidator"]
        ),

        // MARK: - Component 3 & 4: Developer CLI & Command Plugins
        .executableTarget(
            name: "NIBStarterCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "XcodeProj", package: "XcodeProj")
            ]
        ),
        .plugin(
            name: "NIBConvertPlugin",
            capability: .command(
                intent: .custom(
                    verb: "nibstarter-convert",
                    description: "Convert Storyboards to NIBStarter"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Strips Storyboards, updates project configuration, and generates starter NIB files.")
                ]
            ),
            dependencies: ["NIBStarterCLI"]
        ),
        .plugin(
            name: "NIBInstallTemplatesPlugin",
            capability: .command(
                intent: .custom(
                    verb: "nibstarter-install-templates",
                    description: "Install NIBStarter Xcode Templates"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Installs NIBStarter file templates.")
                ]
            ),
            dependencies: ["NIBStarterCLI"]
        ),

        // MARK: - Tests
        .testTarget(
            name: "NIBStarterTests",
            dependencies: [
                "NIBStarter",
                "NIBStarterObjC",
                "NIBValidatorCore",
                "NIBStarterCLI",
                .product(name: "XcodeProj", package: "XcodeProj")
            ]
        )
    ]
)
