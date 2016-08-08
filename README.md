# Aphid

A lightweight MQTT 3.1.1 client written in pure Swift 3.

[![Build Status](https://travis-ci.org/IBM-Swift/Aphid.svg?branch=migration%2F8-04)](https://travis-ci.org/IBM-Swift/Aphid)
![](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)
![](https://img.shields.io/badge/Snapshot-8/04-blue.svg?style=flat)

## Features:

  - [x] MQTT 3.1
  - [x] MQTT 3.1.1
  - [x] LWT
  - [x] SSL/TLS
  - [ ] Message Persistence
  - [ ] Automatic Reconnect
  - [ ] Offline Buffering
  - [ ] WebSocket Support
  - [x] Standard TCP Support
  - [x] Non-Blocking API
  - [ ] Blocking API
  - [ ] High Availability

## Setup

> Requires `swift-DEVELOPMENT-SNAPSHOT-2016-08-04-a toolchain` (Minimum REQUIRED for latest release)

1. Install openssl on macOS with `brew install openssl` or on linux with `sudo apt-get install openssl`

2. In Package.swift, add Aphid as a dependency for your project.

    ```Swift
    import PackageDescription

    let package = Package(
        name: "ProjectName",
        dependencies: [
            .Package(url: "https://github.com/IBM-Swift/Aphid.git", majorVersion: 0, minor: 1)
        ])
    ```
3. Navigate to your XCode project build settings then in both the `SSLService` and `Aphid` Targets add:

    Add `/usr/local/opt/openssl/include` to its Header Search Paths
    Add `/usr/local/opt/openssl/lib` to its Library Search Paths

    Note: If interested in the test cases, `AphidTestCases` target will also need `/usr/local/opt/openssl/lib` added to its Library Search Paths

4. In Sources/main.swift, import the Aphid module.

    ``` Swift
        import Aphid
    ```

Note: build locally with `swift build -Xcc -I/usr/local/opt/openssl/include -Xlinker -L/usr/local/opt/openssl/lib`
## Usage

Example usage can be found in our [AphidClient Repository](https://github.com/IBM-Swift/AphidClient)


## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).
