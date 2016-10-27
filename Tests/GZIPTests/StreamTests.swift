import XCTest
import Foundation
import Axis
@testable import GZIP

class StreamTests: XCTestCase {

    func testCompressAndUncompress_Data() throws {
        let inputString = "hello world foo bar foo foo\n"
        let input: Data = inputString.data
        let output = try input.gzipCompressed()
        let recoveredInput = try output.gzipUncompressed()
        let recoveredString = String(recoveredInput)
        XCTAssertEqual(recoveredString, inputString)
    }

    func testStream_Uncompress_Data() throws {
        let inputData = "H4sICElFQ1cAA2ZpbGUudHh0AMtIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==".fromBase64()
        let sourceStream = DrainStream(inputData)
        let outStream = try GzipStream(rawStream: sourceStream, mode: .uncompress)
        let outData = try outStream.drain(deadline: .never)
        let outputString = String(outData)
        XCTAssertEqual(outputString, "hello world foo bar foo foo\n")
    }

    func testStream_Compress_Data() throws {
        let inputData = "hello world foo bar foo foo\n".data
        let sourceStream = DrainStream(inputData)
        let outStream = try GzipStream(rawStream: sourceStream, mode: .compress)
        let outData = try outStream.drain(deadline: .never).data
        let outputString = outData.base64EncodedString(options: [])
        
        XCTAssertEqual(outputString, "H4sIAAAAAAAAA8tIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==")
    }

    func testLarge_Stream_Identity() throws {
        let inputString = Array(repeating: "hello world ", count: 3000).joined(separator: ", ")
        let inputData = inputString.data
        let input = DrainStream(inputData)
        let compressStream = try GzipStream(rawStream: input, mode: .compress)
        let uncompressStream = try GzipStream(rawStream: compressStream, mode: .uncompress)
        let outputData = try uncompressStream.drain(deadline: .never).data
        let outputString = String(outputData)
        XCTAssertEqual(inputString, outputString)
    }

    func testPerformance_Data() throws {
        let inputString = Array(repeating: "hello world ", count: 100000).joined(separator: ", ")
        let input: Data = inputString.data

        measure {
            let output = try! input.gzipCompressed()
            _ = try! output.gzipUncompressed()
        }
    }
}

extension Data {
    var buffer: Buffer {
        var buf: Buffer = Buffer()
        
        self.withUnsafeBytes { (b: UnsafePointer<Byte>) in
            let bb = UnsafeBufferPointer(start: b, count: self.count)
            buf = Buffer(bb)
        }
        
        return buf
    }
    
    var string: String {
        return String(data: self, encoding: String.Encoding.utf8) ?? ""
    }
}

extension Buffer {
    var data: Data {
        return withUnsafeBytes { (ptr: UnsafePointer<Byte>) in
            let buf = UnsafeBufferPointer(start: ptr, count: self.count)
            return Data(buffer: buf)
        }
    }
}


extension String {
    var data: Data {
        return self.data(using: String.Encoding.utf8)!
    }
    
    init(_ data: Data) {
        self.init(data: data, encoding: String.Encoding.utf8)!
    }

    init(_ buffer: Buffer) {
        
        let data = buffer.withUnsafeBytes { (buf: UnsafePointer<Byte>) in
            Data(bytes: buf, count: buffer.count)
        }
        
        self.init(data: data, encoding: String.Encoding.utf8)!
    }

    func fromBase64() -> Data {
        return Data(base64Encoded: self, options: [])!
    }
}

public final class DrainStream: Axis.InputStream {
    private var buffer: Data
    public private (set) var closed: Bool = false
    
    public func open(deadline: Double) throws {
        
    }
    
    public init(_ buffer: Data) {
        self.buffer = buffer
    }
    
    public func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> UnsafeBufferPointer<Byte> {
        
        let byteCount = buffer.count
        let result: Data
        
        if readBuffer.count >= byteCount {
            result = buffer
            close()
        }
        else {
            result = Data(buffer[0..<readBuffer.count])
            buffer.removeFirst(readBuffer.count)
        }
        
        let count = result.copyBytes(to: readBuffer)
        
        return UnsafeBufferPointer(start: readBuffer.baseAddress, count: count)
    }
    
    public func close() {
        closed = true
    }
}

extension StreamTests {
    public static var allTests: [(String, (StreamTests) -> () throws -> Void)] {
        return [
            ("testCompressAndUncompress_Data", testCompressAndUncompress_Data),
            ("testStream_Uncompress_Data", testStream_Uncompress_Data),
            ("testStream_Compress_Data", testStream_Compress_Data),
            ("testLarge_Stream_Identity", testLarge_Stream_Identity),
            ("testPerformance_Data", testPerformance_Data)
        ]
    }
}
