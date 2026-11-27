// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "PopCornBox",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PopCornBox",
            targets: ["PopCornBox"]
        )
    ],
    dependencies: [
        // Firebase
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: 10.25.0),
        // Google Sign-In
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: 7.0.0)
    ],
    targets: [
        .target(
            name: "PopCornBox",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            path: "PopcornBox"
        ),
        .testTarget(
            name: "PopcornBoxTests",
            dependencies: ["PopCornBox"],
            path: "PopcornBoxTests"
        ),
        .testTarget(
            name: "PopcornBoxUITests",
            dependencies: ["PopCornBox"],
            path: "PopcornBoxUITests"
        )
    ]
)
