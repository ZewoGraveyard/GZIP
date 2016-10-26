import Axis
import Foundation

public final class GzipStream: Axis.InputStream {
    
    private let rawStream: Axis.InputStream
    private let processor: GzipProcessor
    
    public private (set) var closed: Bool = false
    
    public init(rawStream: Axis.InputStream, mode: GzipMode) throws {
        self.rawStream = rawStream
        self.processor = mode.processor()
        try self.processor.initialize()
    }
    
    public func close() {
        processor.close()
        rawStream.close()
        self.closed = true
    }
    
    public func open(deadline: Double) throws {
        
    }
    
    public func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> UnsafeBufferPointer<Byte> {
        
        guard !closed, let readPointer = readBuffer.baseAddress else {
            return UnsafeBufferPointer()
        }
        
        let chunk = try rawStream.read(upTo: readBuffer.count, deadline: deadline)
        
        if processor.closed {
            throw GzipError.unknown(message: "Gzip stream already closed", code: 10)
        }
        
        let isLast = rawStream.closed || processor.closed
        let outputData = try processor.process(data: Data(chunk.bytes), isLast: isLast)
        
        let count = outputData.copyBytes(to: readBuffer)
        
        if rawStream.closed {
            processor.close()
            closed = true
        }
        
        return UnsafeBufferPointer(start: readPointer, count: count)
    }
}


