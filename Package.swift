// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SiteLedger",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SiteLedger",
            targets: ["SiteLedger"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.19.0")
    ],
    targets: [
        .target(
            name: "SiteLedger",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ])
    ]
)
