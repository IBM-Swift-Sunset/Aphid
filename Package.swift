import PackageDescription

let package = Package(
    name: "Aphid",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", majorVersion: 0, minor: 5),
    ],
    exclude: ["Aphid.xcodeproj", "README.md", "Sources/Info.plist"]
)
