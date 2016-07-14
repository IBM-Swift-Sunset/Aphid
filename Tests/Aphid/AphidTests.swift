import XCTest
@testable import Aphid

class AphidTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let aphid = Aphid(clientId: "tester")
        
        do {
            try aphid.connect()

        } catch {
            
        }
        
    }


    static var allTests : [(String, (AphidTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
