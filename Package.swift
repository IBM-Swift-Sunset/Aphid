import PackageDescription

let package = Package(
    name: "Aphid",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/BlueSSLService.git", majorVersion: 0, minor: 10),
    ],
    exclude: ["Aphid.xcodeproj", "README.md", "Sources/Info.plist"]
)
