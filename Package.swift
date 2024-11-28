// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SlideshowGallery",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "SlideshowGallery",
            targets: ["SlideshowGallery"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            from: "8.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SlideshowGallery",
            dependencies: [],
            path: "Sources/SlideshowGallery"),
        .testTarget(
            name: "SlideshowGalleryTests",
            dependencies: ["SlideshowGallery"],
            path: "Tests/SlideshowGalleryTests"
        ),
    ]
)
