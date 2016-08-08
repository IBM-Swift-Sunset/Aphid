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

class AphidTests: XCTestCase, MQTTDelegate {

    private var aphid: Aphid!
    
    var testCase = ""
    var receivedCount = 0
    
    let topic = "plants/basilplant"
    let message = "Basilplant #1 needs to be watered"
   
    weak var expectation: XCTestExpectation!
    
    var tokens = [String]()
    
    static var allTests: [(String, (AphidTests) -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
            ("testKeepAlive", testKeepAlive),
            ("testDisconnect", testDisconnect),
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
        expectation = expectation(withDescription: "Received Connack")

        do {
            try aphid.connect()

        } catch {
            throw error
        }

        // Wait for completion
        waitForExpectations(withTimeout: 30) {
            error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }

        do {
            try aphid.disconnect()
            sleep(5)
        } catch {
            throw error

        }
    }

    func testKeepAlive() throws {
        
        testCase = "ping"
        receivedCount = 0
        expectation = expectation(withDescription: "Keep Alive Ping")
        
        do {
            let _ = try aphid.connect()
            
        } catch {
            throw error
        }
        
        // Wait for completion
        waitForExpectations(withTimeout: 60) {
            error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testSubscribePublish() throws {

        testCase = "SubscribePublish"
        expectation = expectation(withDescription: "Received a message")
        
        do {
            try aphid.connect()
            try aphid.subscribe(topic: [topic], qoss: [.atMostOnce])
            try aphid.publish(topic: topic, withMessage: message, qos: QosType.exactlyOnce)
            
        } catch {
            throw error
        }
        
        // Wait for completion
        waitForExpectations(withTimeout: 30) {
            error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testQosExactlyOnce() throws {
        
        testCase = "qos 2"
        receivedCount = 0
        expectation = expectation(withDescription: "Received message exactly Once")
        
        do {
            try aphid.connect()
            try aphid.subscribe(topic: [topic], qoss: [.atMostOnce])
            try aphid.publish(topic: topic, withMessage: message, qos: .exactlyOnce)
            
        } catch {
            throw error
        }
        
        // Wait for completion
        waitForExpectations(withTimeout: 30) {
            error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testDisconnect() throws {

        testCase = "disconnect"

        do {
            try aphid.connect()
            try aphid.disconnect()
        } catch {
            throw error
        }
    }
    
    // Protocol Functions
    func didLoseConnection() {
        print("Connection lost")
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
        if testCase == "SubscribePublish" && topic == self.topic && message == self.message {
            expectation.fulfill()
        }
        print(topic, message)
    }
}
