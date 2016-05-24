import C7
import Foundation

public final class GzipStream: Stream {
    
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
        
        let nsChunk = chunk.toNSDataCopyBytes()
        let output = try processor
            .process(data: nsChunk)
            .toC7DataCopyBytes()
        if processor.closed || rawStream.closed {
            self.closed = true
        }
        return output
    }
    
    public func send(_ data: Data, timingOut deadline: Double) throws {
        let nsChunk = data.toNSDataCopyBytes()
        let output = try processor
            .process(data: nsChunk)
            .toC7DataCopyBytes()
        if processor.closed || rawStream.closed {
            self.closed = true
        }
        try rawStream.send(output, timingOut: deadline)
    }
    
    public func flush(timingOut deadline: Double) throws {
        try rawStream.flush(timingOut: deadline)
    }
    
    public func close() throws {
        try rawStream.close()
    }
}


