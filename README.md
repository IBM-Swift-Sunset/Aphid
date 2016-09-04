# Aphid

A lightweight MQTT 3.1.1 client written in pure Swift 3

[![Build Status](https://travis-ci.org/IBM-Swift/Aphid.svg?branch=master)](https://travis-ci.org/IBM-Swift/Aphid)
![](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)
![](https://img.shields.io/badge/Snapshot-9-03-blue.svg?style=flat)

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

## Installing and using on the Raspberry Pi 3:

Unfortunately there are some issues with the Swift Package Manager and Dispatch library that requires a lot of manual steps for your application to build. For a working set of steps, please refer to:

[Compiling an Aphid application on the Raspberry Pi 3](https://github.com/IBM-Swift/Aphid/wiki/Compiling-an-Aphid-Application-on-the-Pi-3)

## Setup your project to use Aphid 

> Requires `swift-DEVELOPMENT-SNAPSHOT-2016-09-03-a toolchain` (Minimum REQUIRED for latest release)

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
3. Create XCode project to build library (Optional)

    ```
    $ swift package generate-xcodeproj \
            -Xswiftc -I/usr/local/opt/openssl/include \
            -Xlinker -L/usr/local/opt/openssl/lib
    ```

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
