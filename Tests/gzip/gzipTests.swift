import XCTest
import C7
import Foundation
@testable import gzip

class gzipTests: XCTestCase {

	func testCompress1() throws {
        let input = Data("hello world hello world hello world hello world hello errbody")
		let data = try gzip.compress(data: input)
        let str = data.base64String()
        print(str)
//        XCTAssertEqual(data.bytes, [])
	}
//err, still looking for a way to *test* if the results are correct :D
//    H4sIAAAAAAAA/8tIzcnJVyjPL8pJUcggmp1aVJSUn1IJAISpv6M9AAAA
//    H4sIAAAAAAAAA8tIzcnJVyjPL8pJUcggmp1aVJSUn1IJAISpv6M9AAAA
//    H4sIAHg1QlcAA8tIzcnJVyjPL8pJUcggmp1aVJSUn1IJAISpv6M9AAAA
//    H4sICBsuQlcAA2QxLnR4dADLSM3JyVcozy/KSVHIII3NBQAAyM2ZPAAAAA
}
extension gzipTests {
	static var allTests : [(String, (gzipTests) -> () throws -> Void)] {
		return [
			("testCompress1", testCompress1),
		]
	}
}

extension NSData {
    func base64String() -> String {
        return self.base64EncodedString(NSDataBase64EncodingOptions())
    }
}
