import XCTest
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
        XCTAssertEqual(output.count, 0)
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
    
    let unzippedString = "hello world foo bar foo foo"
    var unzippedData: Data {
        return unzippedString.data(using: String.Encoding.utf8)!
    }
    let zippedString = "H4sIAAAAAAAA/8tIzcnJVyjPL8pJUUjLz1dISiwC00AMAFeJPLcbAAAA"
    var zippedData: Data {
        return Data(base64Encoded: zippedString)!
    }
    
    func testChunks_compress() throws {
        let data = unzippedData //27 bytes
        let processor = GzipMode.compress.processor()
        try processor.initialize()
        var outData: Data = Data()
        let chunkSize = 5
        let rounds = Int(floor(Double(data.count) / Double(chunkSize)))
        for i in 0...rounds {
            let end = min((i+1)*chunkSize, data.count)
            let chunk = data.subdata(i*chunkSize..<end)
            let processedChunk = try processor.process(data: chunk, isLast: i == rounds)
            outData.append(processedChunk.toFoundationData())
        }
        let str = outData.base64EncodedString()
        
        //this is longer as the chunks are smaller
        //generally, large chunks allow better compression
        XCTAssertEqual(str, "H4sIAAAAAAAAA8pIzcnJBwAAAP//UijPL8oBAAAA//9KUUjLzwcAAAD//1JISixSAAAAAP//AtFpAAAAAP//y88HAFeJPLcbAAAA")
    }
    
    //ensure we can keep compressing and once we know all data has been fed,
    //we just send empty data to get the buffered encoded data out
    func testChunks_compress_flushWithEmpty() throws {
        let data = unzippedData //27 bytes
        let processor = GzipMode.compress.processor()
        try processor.initialize()
        var outData: Data = Data()
        let chunkSize = 5
        let rounds = Int(floor(Double(data.count) / Double(chunkSize)))
        for i in 0...rounds {
            let end = min((i+1)*chunkSize, data.count)
            let chunk = data.subdata(i*chunkSize..<end)
            let processedChunk = try processor.process(data: chunk, isLast: false)
            outData.append(processedChunk.toFoundationData())
        }
        
        //flush
        let finalChunk = try processor.flush().toFoundationData()
        outData.append(finalChunk)
        
        let str = outData.base64EncodedString()
        
        //ensure safe flush is safe to call
        XCTAssertNil(try processor.safeFlush())
        XCTAssertNil(try processor.safeFlush())
        XCTAssertNil(try processor.safeFlush())
        
        //this is longer as the chunks are smaller
        //generally, large chunks allow better compression
        XCTAssertEqual(str, "H4sIAAAAAAAAA8pIzcnJBwAAAP//UijPL8oBAAAA//9KUUjLzwcAAAD//1JISixSAAAAAP//AtFpAAAAAP//ys8HAAAA//8DAFeJPLcbAAAA")
    }
    
    func testChunks_uncompress() throws {
        let data = zippedData
        let processor = GzipMode.uncompress.processor()
        try processor.initialize()
        var outData: Data = Data()
        let chunkSize = 5
        let rounds = Int(floor(Double(data.count) / Double(chunkSize)))
        for i in 0...rounds {
            let end = min((i+1)*chunkSize, data.count)
            let chunk = data.subdata(i*chunkSize..<end)
            let processedChunk = try processor.process(data: chunk, isLast: i == rounds)
            outData.append(processedChunk.toFoundationData())
        }
        let str = outData.toString()
        
        XCTAssertEqual(str, unzippedString)
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
}

extension Data {
    func subdata(_ range: Range<Int>) -> NSData {
        let sub: [UInt8] = Array(self[range])
        return Data(bytes: sub).toNSData()
    }
}

extension String {
    func toData() -> Foundation.Data {
        return self.data(using: String.Encoding.utf8) ?? Foundation.Data()
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
        ("testUncompressGzip_Fixture", testUncompressGzip_Fixture),
        ("testCompressGzip_Fixture", testCompressGzip_Fixture),
        ("testPerformance_NSData", testPerformance_NSData),
        ("testPerformance_FoundationData", testPerformance_FoundationData),
        ("testChunks_compress", testChunks_compress),
        ("testChunks_compress_flushWithEmpty", testChunks_compress_flushWithEmpty),
        ("testChunks_uncompress", testChunks_uncompress)
    ]
}
