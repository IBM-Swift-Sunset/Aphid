import XCTest
@testable import Aphid

class AphidTests: XCTestCase {
    let aphid: Aphid = Aphid(clientId: "tester")
    

    func testConnect() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let aphid = Aphid(clientId: "tester")
        
        do {
            let _ = try aphid.connect()
            let _ = aphid.publish(topic: "/basilplant/", message: "Water Me Please!!")
            let _ = aphid.ping()
            let _ = aphid.subscribe(topic: ["/basilplant/"], qoss: [.atMostOnce])
            let _ = aphid.unsubscribe(topic: ["/basilplant/"])
        } catch {
     
        }
    }
    /*func testPublish() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        print("////// Test Publish //////")
        let aphid = Aphid(clientId: "tester")
        do {
            print(aphid.publish(message: "hello"))
            
        } catch {
            
        }
        
    }*/

    static var allTests : [(String, (AphidTests) -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
            //("testPublish", testPublish),
        ]
    }
}
