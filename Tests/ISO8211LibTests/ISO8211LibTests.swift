import XCTest
@testable import ISO8211Lib

final class ISO8211LibTests: XCTestCase {
    func testAddition() throws {
        XCTAssertEqual(ISO8211Lib().addition(value1: 10, value2: 10), 20)
    }
    
    func testSubtraction() throws {
        XCTAssertEqual(ISO8211Lib().subtraction(value1: 100, value2: 10), 90)
    }
    
    func testMultiplication() throws {
        XCTAssertEqual(ISO8211Lib().multiplication(value1: 10, value2: 10), 100)
    }
    
    func testDivision() throws {
        XCTAssertEqual(ISO8211Lib().division(value1: 10, value2: 2), 5)
    }
}
