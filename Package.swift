import PackageDescription

let package = Package(
    name: "Aphid",
    dependencies: [
        .Package(url: "https://github.com/sandmman/BlueSSLService.git", majorVersion: 0, minor: 3),
    ],
    exclude: ["Aphid.xcodeproj", "README.md", "Sources/Info.plist"]
)
