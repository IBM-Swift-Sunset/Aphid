# Aphid

A lightweight MQTT 3.1.1 client written in pure Swift 3.

[![Build Status](https://travis-ci.org/IBM-Swift/Aphid.svg?branch=master)](https://travis-ci.org/IBM-Swift/Aphid)
![](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)
![](https://img.shields.io/badge/Snapshot-8/07-blue.svg?style=flat)

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

## ARM Devices (like Raspberry Pi) (Swift 3 Pre Release)

1. Install the following system linux libraries:

  `$ sudo apt-get install autoconf libtool libcurl4-openssl-dev libbsd-dev libblocksruntime-dev`

2. Install the required Swift version from swift.org.

  After installing it (i.e. extracting the .tar.gz file), make sure you update your PATH environment variable so that it includes the extracted tools: export PATH=/<path to uncompress tar contents>/usr/bin:$PATH.

3. Clone, build and install the libdispatch library.

  `$ export SWIFT_HOME=<path-to-swift-toolchain>`

  `$ git clone https://github.com/apple/swift-corelibs-libdispatch.git`

4. Add the following in libdispatch src/shims/linux_stubs.h :
 
  ```
  #ifndef PAGE_SIZE
  #define PAGE_SIZE 4096
  #endif
  ```
5. Add the following to <path to swift>/usr/lib/swift/clang/include/stdarg.h:
  
  ```
  #ifndef _VA_LIST
  #include <_G_config.h>  //Adding this line 
  typedef __builtin_va_list va_list;
  #define _VA_LIST
  #endif
  ```
5. Build and install the libdispatch library. (Get back to root of swift-corelibs-libdispatch directory)

  `$ sh ./autogen.sh && ./configure --with-swift-toolchain=$SWIFT_HOME/usr --prefix=$SWIFT_HOME/usr && make && make install`

6. Then move Dispatch.swiftmodule from  `<path to swift>/usr/lib/swift/linux/arm7vl` to `<path to swift>/usr/lib/swift/linux/arm7v`
