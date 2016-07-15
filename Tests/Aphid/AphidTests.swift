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
    let aphid: Aphid = Aphid(clientId: "tester")
    var updated: Bool? = nil

    func testConnect() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let aphid = Aphid(clientId: "tester")
        
        let delegate = self
        aphid.delegate = delegate

        do {
            let _ = try aphid.connect()
            let _ = aphid.loop()
            let _ = aphid.publish(topic: "/basilplant/", message: "Water Me Please!!")
            let _ = aphid.ping()
            let _ = aphid.subscribe(topic: ["/basilplant/"], qoss: [.atMostOnce])
            let _ = aphid.unsubscribe(topic: ["/basilplant/"])
            print("Executed all instruction")
        } catch {
     
        }
        sleep(10)
    }
    func connectionLost() throws {
        print("connection lost")
    }
    func deliveryComplete(token: String) {
        print(token)
        
    }
    func messageArrived(topic: String, message: String) throws {
        print("Message Arrived")
    }

    static var allTests : [(String, (AphidTests) -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
            //("testPublish", testPublish),
        ]
    }
}
