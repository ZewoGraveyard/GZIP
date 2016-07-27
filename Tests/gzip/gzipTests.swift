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
        do {
            _ = try input.gzipUncompressed()
        } catch GzipError.data(message: let message) {
            //all good
            XCTAssertEqual(message, "incorrect header check")
            return
        }
        XCTFail("Should have thrown")
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
        let data = Data(base64Encoded: "H4sICElFQ1cAA2ZpbGUudHh0AMtIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==", options: [])!
        let output = try data.gzipUncompressed()
        let outputString = output.toString()
        XCTAssertEqual(outputString, "hello world foo bar foo foo\n")
    }

    func testCompressGzip_Fixture() throws {
        let data = "hello world foo bar foo foo\n".data(using: String.Encoding.utf8)!
        let output = try data.gzipCompressed()
        #if os(Linux)
        let outputString = output.base64EncodedString([])
        #else
        let outputString = output.base64EncodedString(options: [])
        #endif
        XCTAssertEqual(outputString, "H4sIAAAAAAAAA8tIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==")
    }

    func testStream_Uncompress_C7Data() throws {
        let inputData = "H4sICElFQ1cAA2ZpbGUudHh0AMtIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==".fromBase64toC7Data()
        let sourceStream = Drain(for: inputData)
        let outStream = try GzipStream(rawStream: sourceStream, mode: .uncompress)
        let outData = Drain(for: outStream).data
        let outputString = String(outData)
        XCTAssertEqual(outputString, "hello world foo bar foo foo\n")
    }

    func testStream_Compress_C7Data() throws {
        let inputData = "hello world foo bar foo foo\n".data
        let sourceStream = Drain(for: inputData)
        let outStream = try GzipStream(rawStream: sourceStream, mode: .compress)
        let outData = Drain(for: outStream).data
        #if os(Linux)
        let outputString = outData.toNSData().base64EncodedString([])
        #else
        let outputString = outData.toNSData().base64EncodedString(options: [])
        #endif
        XCTAssertEqual(outputString, "H4sIAAAAAAAAA8tIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==")
    }

    func testLarge_Stream_Identity() throws {
        let inputString = Array(repeating: "hello world ", count: 3000).joined(separator: ", ")
        let inputData = inputString.data
        let input = Drain(for: inputData)
        let compressStream = try GzipStream(rawStream: input, mode: .compress)
        let uncompressStream = try GzipStream(rawStream: compressStream, mode: .uncompress)
        let outputData = Drain(for: uncompressStream).data
        let outputString = String(outputData)
        XCTAssertEqual(inputString, outputString)
    }

    func testPerformance_NSData() throws {
        let inputString = Array(repeating: "hello world ", count: 100000).joined(separator: ", ")
        let input: NSData = inputString.toData().toNSData()

        measure {
            let output = try! input.gzipCompressed()
            _ = try! output.gzipUncompressed()
        }
    }
    
    func testPerformance_FoundationData() throws {
        let inputString = Array(repeating: "hello world ", count: 100000).joined(separator: ", ")
        let input: Foundation.Data = inputString.toData()
        
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
//                let inputString = Array(repeating: "hello world ", count: 10000).joined(separator: ", ")
//                let input = inputString.data
//                let output = try input.gzipCompressed()
//                let recoveredInput = try output.gzipUncompressed()
//                let recoveredString = String(recoveredInput)
//                XCTAssertEqual(recoveredString, inputString)
//                sleep(1)
//            }
//        }
//    }

//    func testNoCopying_toNSData() throws {
//        let inputString = Array(repeating: "hello world ", count: 1000000).joined(separator: ", ")
//        for _ in 0..<100 {
//            func yo() -> NSData {
//                let input = inputString.data
//                sleep(1)
//                return input.toNSData()
//            }
//            let dat = yo()
//            sleep(1)
//            print("bump")
//        }
//    }

//    func testNoCopying_toC7Data() throws {
//        let inputString = Array(repeating: "hello world ", count: 1000000).joined(separator: ", ")
//        for _ in 0..<100 {
//            func yo() -> C7.Data {
//                return autoreleasepoolIfAvailable {
//                    let input = inputString.data(using: NSUTF8StringEncoding)!
//                    sleep(1)
//                    return input.toC7DataCopyBytes()
//                }
//            }
//            let dat = yo()
//            sleep(1)
//            print("bump")
//        }
//    }
}

extension String {
    func toData() -> Foundation.Data {
        return self.data(using: String.Encoding.utf8) ?? Foundation.Data()
    }

    func fromBase64toC7Data() -> C7.Data {
        return NSData(base64Encoded: self, options: [])!.toC7Data()
    }
}

extension Foundation.Data {
    func toString() -> String {
        return String(data: self, encoding: String.Encoding.utf8) ?? ""
    }
}

extension gzipTests {
    static var allTests = [
        ("testCompressAndUncompress_NSData", testCompressAndUncompress_NSData),
        ("testEmpty", testEmpty),
        ("testDecompress_IncorrectData", testDecompress_IncorrectData),
        ("testCompressAndUncompress_C7Data", testCompressAndUncompress_C7Data),
        ("testUncompressGzip_Fixture", testUncompressGzip_Fixture),
        ("testCompressGzip_Fixture", testCompressGzip_Fixture),
        ("testStream_Uncompress_C7Data", testStream_Uncompress_C7Data),
        ("testStream_Compress_C7Data", testStream_Compress_C7Data),
        ("testLarge_Stream_Identity", testLarge_Stream_Identity),
        ("testPerformance_NSData", testPerformance_NSData),
        ("testPerformance_FoundationData", testPerformance_FoundationData),
        ("testPerformance_C7Data", testPerformance_C7Data)
    ]
}
