/**
 Copyright IBM Corporation 2016

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


import XCTest
@testable import Aphid

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

class AphidTests: XCTestCase, MQTTDelegate {

    private var aphid: Aphid!
    
    var testCase = ""
    var receivedCount = 0
    
    let topic = "plants/basilplant"

    let message = "{\"payload\":\"An5oww==\",\"fields\":{\"beaconId\":2,\"humidy\":55.5234375,\"temp\":24.536250000000003},\"port\":1,\"counter\":633,\"dev_eui\":\"C0EE400001010916\",\"metadata\":[{\"frequency\":868.1,\"datarate\":\"SF12BW125\",\"codingrate\":\"4/5\",\"gateway_timestamp\":2806201428,\"gateway_time\":\"2016-08-11T16:16:01.687021Z\",\"channel\":0,\"server_time\":\"2016-08-11T16:16:01.710438775Z\",\"rssi\":-30,\"lsnr\":9.8,\"rfchain\":1,\"crc\":1,\"modulation\":\"LORA\",\"gateway_eui\":\"B827EBFFFEC139EF\",\"altitude\":8,\"longitude\":-1.7645,\"latitude\":54.9837}]}"

    weak var expectation: XCTestExpectation!
    weak var disconnectExpectation: XCTestExpectation!

    var tokens = [String]()
    
    static var allTests: [(String, (AphidTests) -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
            ("testKeepAlive", testKeepAlive),
            ("testSubscribePublish", testSubscribePublish),
            ("testQosExactlyOnce",testQosExactlyOnce),
        ]
    }
    
    override func setUp() {
        super.setUp()

        let clientId = "Aaron"
        aphid = Aphid(clientId: clientId)

        aphid.setWill(topic: "lastWillAndTestament/",message: "Client \(clientId) Closed Unexpectedly", willQoS: .atMostOnce, willRetain: false)

        aphid.delegate = self

    }

    func testConnect() throws {
        
        testCase = "connect"
        expectation = expectation(description: "Received Connack")
    
        try aphid.connect()

        waitForExpectations(timeout: 30) {
            error in

            error != nil ? print("Error: \(error!.localizedDescription)") : self.disconnect()
        }
    }

    func testKeepAlive() throws {
        
        testCase = "ping"
        receivedCount = 0
        expectation = expectation(description: "Keep Alive Ping")
        
        
        try aphid.connect()

        waitForExpectations(timeout: 90) {
            error in

            error != nil ? print("Error: \(error!.localizedDescription)") : self.disconnect()
        }
    }
    
    func testSubscribePublish() throws {

        testCase = "SubscribePublish"
        expectation = expectation(description: "Received a message")

        try aphid.connect()

        aphid.subscribe(topic: [topic], qoss: [.atMostOnce])

        aphid.publish(topic: topic, withMessage: message, qos: QosType.exactlyOnce)

        waitForExpectations(timeout: 60) {
            error in

            error != nil ? print("Error: \(error!.localizedDescription)") : self.disconnect()
        }
    }
    
    func testQosExactlyOnce() throws {
        
        testCase = "qos 2"
        receivedCount = 0
        expectation = expectation(description: "Received message exactly Once")

        try aphid.connect()

        aphid.subscribe(topic: [topic], qoss: [.atMostOnce])

        aphid.publish(topic: topic, withMessage: message, qos: .exactlyOnce)

        waitForExpectations(timeout: 30) {
            error in

            error != nil ? print("Error: \(error!.localizedDescription)") : self.disconnect()
        }
    }

    func disconnect() {
        disconnectExpectation = expectation(description: "Disconnected")
        
        aphid.disconnect()
        
        waitForExpectations(timeout: 20) {
            error in

            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    // Protocol Functions
    func didLoseConnection(error: Error?) {
        disconnectExpectation.fulfill()
    }

    func didConnect() {
        if testCase == "connect"  && receivedCount == 0{
            receivedCount += 1
            expectation.fulfill()
        }
    }

    func didCompleteDelivery(token: String) {
        if testCase == "ping" && token == "pingresp" {
            receivedCount += 1
            if receivedCount >= 3 {
                expectation.fulfill()
            }
        } else if testCase == "qos 2" && (token == "pubrec" ||
                  token == "pubcomp") && !tokens.contains(token) {
            tokens.append(token)
            if tokens.count == 2 {
                expectation.fulfill()
            }
        }
    }

    func didReceiveMessage(topic: String, message: String) {
        if testCase == "SubscribePublish" {
            expectation.fulfill()
        }
    }
}
