import C7
import Foundation

public final class GzipStream: ReceivingStream {
    
    private let rawStream: ReceivingStream
    private let processor: GzipProcessor
    
    public var closed: Bool = false
    
    public init(rawStream: ReceivingStream, mode: GzipMode) throws {
        self.rawStream = rawStream
        self.processor = mode.processor()
        try self.processor.initialize()
    }
    
    public func receive(upTo byteCount: Int, timingOut deadline: Double) throws -> C7.Data {
        let chunk: C7.Data
        do {
            chunk = try rawStream.receive(upTo: byteCount, timingOut: deadline)
        } catch StreamError.closedStream(let data) {
            chunk = data
        }

        if processor.closed {
            throw GzipError.unknown(message: "Gzip stream already closed", code: 10)
        }

        let isLast = rawStream.closed || processor.closed
        let nsChunk = chunk.toNSData()
        let outputNSData = try processor
            .process(data: nsChunk, isLast: isLast)
        let output = outputNSData
            .toC7Data()
        
        if rawStream.closed {
            processor.close()
            closed = true
        }
        return output
    }
        
    public func close() throws {
        processor.close()
        try rawStream.close()
        self.closed = true
    }
}


