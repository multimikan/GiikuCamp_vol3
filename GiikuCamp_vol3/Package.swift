// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GiikuCamp_vol3",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GiikuCamp_vol3",
            targets: ["GiikuCamp_vol3"]),
    ],
    dependencies: [
        // Firebase関連のパッケージ
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.19.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GiikuCamp_vol3",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
            ]),
        .testTarget(
            name: "GiikuCamp_vol3Tests",
            dependencies: ["GiikuCamp_vol3"]),
    ]
)
