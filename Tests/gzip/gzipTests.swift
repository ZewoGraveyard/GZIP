import XCTest
import C7
import Foundation
@testable import gzip

class gzipTests: XCTestCase {

	func testCompress1() throws {
        let inputString = "hello world hello world hello world hello world hello errbody"
        let input = Data(inputString)
        let output = try input.gzipCompressed()
        let outputString = String(output)
        let recoveredInput = try output.gzipUncompressed()
        let recoveredString = String(recoveredInput)
        print(recoveredString)
        XCTAssertEqual(recoveredString, inputString)
	}
}

extension gzipTests {
	static var allTests : [(String, (gzipTests) -> () throws -> Void)] {
		return [
			("testCompress1", testCompress1),
		]
	}
}
