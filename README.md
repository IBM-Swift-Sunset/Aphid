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

## Setup your project to use Aphid 

> Requires `swift-DEVELOPMENT-SNAPSHOT-2016-08-04-a toolchain` (Minimum REQUIRED for latest release)

1. Install OpenSSL:

    - macOS: `brew install openssl`
    - Ubuntu Linux: `sudo apt-get install openssl`

2. In Package.swift, add Aphid as a dependency for your project.

    ```Swift
    import PackageDescription

    let package = Package(
        name: "ProjectName",
        dependencies: [
            .Package(url: "https://github.com/IBM-Swift/Aphid.git", majorVersion: 0, minor: 2)
        ])
    ```
3. Setup XCode to build library (Optional)

    Navigate to your XCode project build settings then in both the `SSLService` and `Aphid` Targets add:

    - Add `/usr/local/opt/openssl/include` to its Header Search Paths
    - Add `/usr/local/opt/openssl/lib` to its Library Search Paths

    Note: If interested in the test cases, `AphidTestCases` target will also need `/usr/local/opt/openssl/lib` added to its Library Search Paths

4. In Sources/main.swift, import the Aphid module.

    ``` Swift
        import Aphid
    ```

5. Note: build locally with:

    - macOS: `swift build -Xcc -I/usr/local/opt/openssl/include -Xlinker -L/usr/local/opt/openssl/lib`
    - Linux: `swift build -Xcc -fblocks`

## Examples

Example usage can be found in our [AphidClient Repository](https://github.com/IBM-Swift/AphidClient)

## MQTT brokers

There are several MQTT brokers you can use remotely such as the [IBM IoT Foundation](http://www.ibm.com/cloud-computing/bluemix/internet-of-things/) on Bluemix.

If testing locally, we recommend the [Mosquitto broker](https://mosquitto.org/):

    - macOS: `brew install mosquitto`
    - Ubuntu Linux: `apt-get install mosquitto`

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).
