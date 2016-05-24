import C7
import Foundation

public final class GzipStream: ReceivingStream {
    
    private let rawStream: Stream
    private let processor: GzipProcessor
    
    public var closed: Bool = false
    
    public init(rawStream: Stream, mode: GzipMode) throws {
        self.rawStream = rawStream
        self.processor = mode.processor()
        try self.processor.initialize()
    }
    
    public func receive(upTo byteCount: Int, timingOut deadline: Double) throws -> Data {
        let chunk: Data
        do {
            chunk = try rawStream.receive(upTo: byteCount, timingOut: deadline)
        } catch StreamError.closedStream(let data) {
            chunk = data
        }

        if processor.closed {
            throw GzipError.Unknown(message: "Gzip stream already closed", code: 10)
        }

        let isLast = rawStream.closed || processor.closed
        let nsChunk = chunk.toNSDataCopyBytes()
        let outputNSData = try processor
            .process(data: nsChunk, isLast: isLast)
        let output = outputNSData
            .toC7DataCopyBytes()
        
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


