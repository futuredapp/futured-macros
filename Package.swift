// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "FuturedMacros",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "FuturedMacros",
            targets: [
                "EnumIdentable",
                "FlattenProperties"
            ]
        ),
        .library(
            name: "EnumIdentable",
            targets: ["EnumIdentable"]
        ),
        .library(
            name: "FlattenProperties",
            targets: ["FlattenProperties"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "EnumIdentableMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "EnumIdentable", dependencies: ["EnumIdentableMacros"]),

        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "FlattenPropertiesMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "FlattenProperties", dependencies: ["FlattenPropertiesMacros"]),


        .testTarget(
            name: "EnumIdentableTests",
            dependencies: [
                "EnumIdentableMacros", // Test target depends on the macro implementation directly
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),

        // Test target for FlattenProperties
        .testTarget(
            name: "FlattenPropertiesTests", // Matches your folder/file structure
            dependencies: [
                "FlattenPropertiesMacros", // Test target depends on the macro implementation directly
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
