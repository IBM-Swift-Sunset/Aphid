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
    var updated: Bool? = nil
    
    var expectation1: XCTestExpectation!

    override func setUp() {
        super.setUp()
        
        aphid = Aphid(clientId: "tester")
        
        aphid.delegate = self

    }
    
    func testConnect() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        expectation1 = expectation(withDescription: "Received a message")

        do {
            let _ = try aphid.connect()
            //let _ = aphid.ping()
            //let _ = aphid.publish(topic: "/basilplant/", message: "Water Me Please!!")
            //let _ = aphid.ping()
            let _ = aphid.subscribe(topic: ["/basilplant/"], qoss: [.atMostOnce])
            let _ = aphid.publish(topic: "/basilplant/", message: "Water Me Please!!")
            //let _ = aphid.unsubscribe(topic: ["/basilplant/"])
            while true {
                
            }

        } catch {
     
        }
        
        sleep(30)
        // Wait for completion
        waitForExpectations(withTimeout: 30) {
            error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
        
        do {
            try aphid.disconnect(uint: 1)

        } catch {
            print(error)
            
        }
    }
    
    
    func connectionLost() throws {
        print("connection lost")
    }
    
    
    func deliveryComplete(token: String) {
        if token == "2: dup: false qos: 0 retain false remainingLength 2" {
            expectation1.fulfill()
        }
        print(token)
        
    }
    
    func messageArrived(topic: String, message: String) throws {
        //expectation1.fulfill()
        print(topic, message)
    }

    static var allTests : [(String, (AphidTests) -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
        ]
    }
}
