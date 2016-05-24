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
    
    func testUncompressGzip_Fixture() throws {
        let data = NSData(base64Encoded: "H4sICElFQ1cAA2ZpbGUudHh0AMtIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==", options: [])!
        let output = try data.gzipUncompressed()
        let outputString = output.toString()
        XCTAssertEqual(outputString, "hello world foo bar foo foo\n")
    }
    
    func testCompressGzip_Fixture() throws {
        let data = "hello world foo bar foo foo\n".data(using: NSUTF8StringEncoding)!
        let output = try data.gzipCompressed()
        let outputString = output.base64EncodedString([])
        XCTAssertEqual(outputString, "H4sIAAAAAAAAA8tIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==")
    }
    
    func testStream_Uncompress_C7Data() throws {
        let inputData = "H4sICElFQ1cAA2ZpbGUudHh0AMtIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==".fromBase64toC7Data()
        let sourceStream = Drain(for: inputData)
        let outStream = try GzipUncompressingStream(rawStream: sourceStream)
        let outData = Drain(for: outStream).data
        let outputString = String(outData)
        XCTAssertEqual(outputString, "hello world foo bar foo foo\n")
    }
    
    #if os(Linux)
    //TODO: once a snapshot after 05-09 gets released, remove this as
    //performance tests are already implemented in corelibs-xctest (just not
    //yet released)
    #else
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
    #endif
    
//    func testNoLeaks_NSData() throws {
//        for _ in 0..<100 {
//            try autoreleasepoolIfAvailable {
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
//            try autoreleasepoolIfAvailable {
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
        return self.data(using: NSUTF8StringEncoding) ?? NSData()
    }
    
    func fromBase64toC7Data() -> Data {
        return NSData(base64Encoded: self, options: [])!.toC7DataCopyBytes()
    }
}

extension NSData {
    func toString() -> String {
        return String(data: self, encoding: NSUTF8StringEncoding) ?? ""
    }
}

extension gzipTests {
	static var allTests : [(String, (gzipTests) -> () throws -> Void)] {
		var all = [
			("testCompressAndUncompress_NSData", testCompressAndUncompress_NSData),
			("testEmpty", testEmpty),
			("testDecompress_IncorrectData", testDecompress_IncorrectData),
			("testCompressAndUncompress_C7Data", testCompressAndUncompress_C7Data),
			("testUncompressGzip_Fixture", testUncompressGzip_Fixture),
			("testCompressGzip_Fixture", testCompressGzip_Fixture)
        ]
        #if os(Linux)
            //TODO: once a snapshot after 05-09 gets released, remove this as
            //performance tests are already implemented in corelibs-xctest (just not
            //yet released)
        #else
            all += [
                ("testPerformance_NSData", testPerformance_NSData),
                ("testPerformance_C7Data", testPerformance_C7Data)
            ]
        #endif
        return all
	}
}
