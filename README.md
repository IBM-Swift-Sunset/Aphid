# Aphid

A lightweight MQTT 3.1.1 client written in pure Swift 3

[![Build Status](https://travis-ci.org/IBM-Swift/Aphid.svg?branch=master)](https://travis-ci.org/IBM-Swift/Aphid)
![](https://img.shields.io/badge/Swift-3.0%20RELEASE-orange.svg?style=flat)
![](https://img.shields.io/badge/platform-Linux,%20macOS,%20ARM%20Linux-blue.svg?style=flat)

## Setup your project to use Aphid 

1. On Linux, install OpenSSL (if not already installed):

    ```bash
    sudo apt-get install openssl
    ```

2. In Package.swift, add Aphid as a dependency for your project.

    ```swift
    import PackageDescription

    let package = Package(
        name: "ProjectName",
        dependencies: [
            .Package(url: "https://github.com/IBM-Swift/Aphid.git", majorVersion: 0)
        ])
    ```
3. Create XCode project to build library (Optional)

    ```bash
    $ swift package generate-xcodeproj
    ```

4. In Sources/main.swift, import the Aphid module.

    ```swift
    import Aphid
    ```

5. Note: build locally with:

    ```bash
    swift build
    ```

## Examples

Example usage can be found in our [AphidClient Repository](https://github.com/IBM-Swift/AphidClient)

## MQTT brokers

There are several MQTT brokers you can use remotely such as the [IBM IoT Foundation](http://www.ibm.com/cloud-computing/bluemix/internet-of-things/) on Bluemix.

If testing locally, we recommend the [Mosquitto broker](https://mosquitto.org/):

    - macOS: `brew install mosquitto`
    - Ubuntu Linux: `apt-get install mosquitto`
    
## Installing and using on the Raspberry Pi 3:

Applications that need to run on an ARM system must be compiled with the Swift compiler targetting the ARM platform. Here are some articles to get you started.

- [Building Swift 3.0 on an ARMv7 system](http://dev.iachieved.it/iachievedit/building-swift-3-0-on-an-armv7-system/)
- [Compiling an Aphid application on the Raspberry Pi 3](https://github.com/IBM-Swift/Aphid/wiki/Compiling-an-Aphid-Application-on-the-Pi-3)

## License

Copyright 2016 IBM

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
