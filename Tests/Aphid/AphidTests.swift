import XCTest
@testable import Aphid

class AphidTests: XCTestCase {
    func testConnect() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        print("////// Test Connect //////")
        let aphid = Aphid(clientId: "tester")
        
        do {
            print(try aphid.connect())
            print(aphid.publish(message: "a/b"))
            aphid.ping()
            print(aphid.subscribe(topic: ["a/b","c/d"], qoss: [.atLeastOnce,.exactlyOnce]))
            print(aphid.unsubscribe(topic: "a/b"))
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
