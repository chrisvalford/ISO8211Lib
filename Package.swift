// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ISO8211Lib",
    platforms: [
            .macOS(.v11),
            .iOS(.v12),
        ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ISO8211Lib",
            targets: ["ISO8211Lib"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CppCode",
            dependencies: [],
            path: "Sources/CppCode",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Private"),
            ]),
        .target(
            name: "ISO8211LibWrapper",
            dependencies: ["CppCode"],
            path: "Sources/ISO8211LibWrapper",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Private"),
            ]),
        .target(
            name: "ISO8211Lib",
            dependencies: ["ISO8211LibWrapper"]),
        .testTarget(
            name: "ISO8211LibTests",
            dependencies: ["ISO8211Lib"]),
    ]
)
