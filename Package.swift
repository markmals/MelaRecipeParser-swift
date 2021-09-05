// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MelaRecipeParser",
    platforms: [.macOS(.v10_12), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)],
    products: [.library(name: "MelaRecipeParser", targets: ["MelaRecipeParser"])],
    dependencies: [.package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.12")],
    targets: [.target(name: "MelaRecipeParser", dependencies: ["ZIPFoundation"])]
)
