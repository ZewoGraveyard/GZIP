import XCTest
import C7
import Foundation
@testable import gzip

class gzipTests: XCTestCase {
    
    func testCompressAndUncompress_NSData() throws {
        let inputString = "hello world hello world hello world hello world hello errbody"
        let input = inputString.toData()
        let output = try input.gzipCompressed()
        let recoveredInput = try output.gzipUncompressed()
        let recoveredString = recoveredInput.toString()
        XCTAssertEqual(recoveredString, inputString)
    }
    
    func testEmpty() throws {
        let inputString = ""
        let input = inputString.toData()
        let output = try input.gzipCompressed()
        let recoveredInput = try output.gzipUncompressed()
        let recoveredString = recoveredInput.toString()
        XCTAssertEqual(recoveredString, inputString)
    }
    
    func testDecompress_IncorrectData() throws {
        let inputString = "foo"
        let input = inputString.toData()
        XCTAssertThrowsError(try input.gzipUncompressed())
    }

    func testCompressAndUncompress_C7Data() throws {
        let inputString = "hello world hello world hello world hello world hello errbody"
        let input = inputString.data
        let output = try input.gzipCompressed()
        let recoveredInput = try output.gzipUncompressed()
        let recoveredString = String(recoveredInput)
        XCTAssertEqual(recoveredString, inputString)
    }
    
    func testPerformance_NSData() throws {
        let inputString = Array(repeating: "hello world ", count: 100000).joined(separator: ", ")
        let input: NSData = inputString.toData()
        
        measure {
            let output = try! input.gzipCompressed()
            _ = try! output.gzipUncompressed()
        }
    }

    func testPerformance_C7Data() throws {
        let inputString = Array(repeating: "hello world ", count: 100000).joined(separator: ", ")
        let input: C7.Data = inputString.data
        
        measure {
            let output = try! input.gzipCompressed()
            _ = try! output.gzipUncompressed()
        }
    }
    
//    func testNoLeaks_NSData() throws {
//        for _ in 0..<100 {
//            try autoreleasepool {
//                let inputString = Array(repeating: "hello world ", count: 100000).joined(separator: ", ")
//                let input = inputString.toData()
//                let output = try input.gzipCompressed()
//                let recoveredInput = try output.gzipUncompressed()
//                let recoveredString = recoveredInput.toString()
//                XCTAssertEqual(recoveredString, inputString)
//                sleep(1)
//            }
//        }
//    }
//    
//    func testNoLeaks_Data() throws {
//        for _ in 0..<100 {
//            try autoreleasepool {
//                let inputString = Array(repeating: "hello world ", count: 100000).joined(separator: ", ")
//                let input = inputString.data
//                let output = try input.gzipCompressed()
//                let recoveredInput = try output.gzipUncompressed()
//                let recoveredString = String(recoveredInput)
//                XCTAssertEqual(recoveredString, inputString)
//                sleep(1)
//            }
//        }
//    }

}

extension String {
    func toData() -> NSData {
        return self.data(using: NSUTF8StringEncoding)!
    }
}

extension NSData {
    func toString() -> String {
        return String(data: self, encoding: NSUTF8StringEncoding)!
    }
}

extension gzipTests {
	static var allTests : [(String, (gzipTests) -> () throws -> Void)] {
		return [
			("testCompressAndUncompress_NSData", testCompressAndUncompress_NSData),
			("testEmpty", testEmpty),
			("testDecompress_IncorrectData", testDecompress_IncorrectData),
			("testCompressAndUncompress_C7Data", testCompressAndUncompress_C7Data),
			("testPerformance_NSData", testPerformance_NSData),
			("testPerformance_C7Data", testPerformance_C7Data)
		]
	}
}
