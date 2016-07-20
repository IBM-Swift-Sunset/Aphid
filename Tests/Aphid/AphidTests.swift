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
    var pingCount = 0
    
    let topic = "/basilplant/"
    let message = "Water Me Pretty Please!!"
   
    var expectation: XCTestExpectation!
    
    static var allTests: [(String, (AphidTests) -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
            ("testKeepAlive", testKeepAlive),
            ("testDisconnect", testDisconnect),
            ("testSubscribePublish", testSubscribePublish),
        ]
    }
    
    override func setUp() {
        super.setUp()

        aphid = Aphid(clientId: "tester2")
        aphid.setWill(topic: "/lwt/",message: "OH NO I CLOSED", willQoS: .atMostOnce, willRetain: false)
        aphid.delegate = self

    }

    func testConnect() {
        
        testCase = "connect"
        expectation = expectation(withDescription: "Received Connack")

        do {
            try aphid.connect()

        } catch {

        }

        // Wait for completion
        waitForExpectations(withTimeout: 30) {
            error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }

        do {
            try aphid.disconnect(uint: 1)
            sleep(5)
        } catch {
            print(error)

        }
    }

    func testKeepAlive() {
        
        testCase = "ping"
        expectation = expectation(withDescription: "Keep Alive Ping")
        
        do {
            let _ = try aphid.connect()
            
        } catch {
            
        }
        
        // Wait for completion
        waitForExpectations(withTimeout: 60) {
            error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testSubscribePublish() {

        testCase = "SubscribePublish"
        expectation = expectation(withDescription: "Received a message")
        
        do {
            try aphid.connect()
            try aphid.subscribe(topic: [topic], qoss: [.atMostOnce])
            try aphid.publish(topic: topic, message: message)
            
        } catch {
            
        }
        
        // Wait for completion
        waitForExpectations(withTimeout: 30) {
            error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testDisconnect() {

        testCase = "disconnect"

        do {
            try aphid.connect()
            try aphid.disconnect(uint: 1)
        } catch {

        }
    }
    
    // Protocol Functions
    func didLoseConnection() {
        print("connection lost")
    }
    func didConnect() {
        
    }
    func didCompleteDelivery(token: String) {
        if testCase == "connect" && token == "connack"{
            expectation.fulfill()
        } else if testCase == "ping" {
            pingCount += 1
            if pingCount >= 3 {
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
