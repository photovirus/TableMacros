// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "TableMacros",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TableMacros",
            targets: ["TableMacros"]
        ),
//        .library(
//            name: "TableMacrosMacros",
//            targets: ["TableMacrosMacros"]
//        ),
//        .library(
//            name: "SharedModels",
//            targets: ["SharedModels"]
//        ),
    ],
    dependencies: [
        // Depend on the latest Swift 5.9 prerelease of SwiftSyntax
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0-swift-5.9-DEVELOPMENT-SNAPSHOT-2023-04-25-b"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "TableMacrosMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "SharedModels",
            ]
        ),

        .target(
            name: "SharedModels"
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "TableMacros",
            dependencies: [
                "TableMacrosMacros",
                "SharedModels"
            ]
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "TableMacrosTests",
            dependencies: [
                "TableMacrosMacros",
                "SharedModels",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
