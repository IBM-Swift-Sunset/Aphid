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
            /*let _ = try aphid.connect()
                guard let result = self.updated else {
                    XCTFail("Expected delegate to be called")
                    return
                }
                
                XCTAssertTrue(result)*/
            let _ = try aphid.connect()
            //let _ = aphid.loop()
            //let _ = aphid.publish(topic: "/basilplant/", message: "Water Me Please!!")
            let _ = aphid.ping()
            //let _ = aphid.subscribe(topic: ["/basilplant/"], qoss: [.atMostOnce])
            //let _ = aphid.unsubscribe(topic: ["/basilplant/"])
            print("Executed all instruction")
        } catch {
     
        }
        sleep(10)
    }
    func connectionLost() throws {
        print("connection lost")
    }
    func deliveryComplete(token: String) {
        print("delivery Complete")
        updated = true
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
