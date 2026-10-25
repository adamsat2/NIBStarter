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
        // Products define the executables and libraries a package produces, making them visible to other packages.
        // component 1: runtime libraries
        .library(
            name: "NIBStarter",
            targets: ["NIBStarter", "NIBStarterObjC"]
        ),
        .library(
            name: "NIBStarterObjC",
            targets: ["NIBStarterObjC"]
        ),
        // component 2: validator CLI & plugin
        .executable(
            name: "nib-validator",
            targets: ["NIBValidator"]
        ),
        .plugin(
            name: "NIBValidatorPlugin",
            targets: ["NIBValidatorPlugin"]
        ),
        // component 3: scaffolding CLI & command plugin
        .executable(
            name: "nibstarter",
            targets: ["NIBStarterCLI"]
        ),
        .plugin(
            name: "NIBConvertPlugin",
            targets: ["NIBConvertPlugin"]
        ),
        .plugin(
            name: "NIBInstallTemplatesPlugin",
            targets: ["NIBInstallTemplatesPlugin"]
        ),
    ],
    dependencies: [
        // AST parsing for component 2
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        // CLI Command parser for component 3
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        // Xcode project manipulation for component 3
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "8.16.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // MARK: - component 1: Runtime
        .target(
            name: "NIBStarter",
            dependencies: []
        ),
        .target(
            name: "NIBStarterObjC",
            dependencies: [],
            publicHeadersPath: "include"
        ),
        
        // MARK: - component 2: Validator
        .target(
            name: "NIBValidatorCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
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
        
        // MARK: - component 3: CLI & Command Plugins
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
                    description: "Convert Storyboards to NIBStarter and set up programmatic bootstrapping"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Strip Storyboards and scaffold NIB starter files")
                ]
            ),
            dependencies: ["NIBStarterCLI"]
        ),
        .plugin(
            name: "NIBInstallTemplatesPlugin",
            capability: .command(
                intent: .custom(
                    verb: "nibstarter-install-templates",
                    description: "Install NIBStarter file templates into Xcode"
                )
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
                "NIBStarterCLI"
            ]
        ),
    ]
)
