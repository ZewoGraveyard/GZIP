import C7
import Czlib
import Foundation

public final class GzipUncompressingStream: Stream {
    
    private let rawStream: Stream
    private let uncompressor: GzipUncompressor
    
    public var closed: Bool = false
    
    public init(rawStream: Stream) throws {
        self.rawStream = rawStream
        self.uncompressor = GzipUncompressor()
        try self.uncompressor.initialize()
    }
    
    public func receive(upTo byteCount: Int, timingOut deadline: Double) throws -> Data {
        let chunk = try self
            .rawStream
            .receive(upTo: byteCount, timingOut: deadline)
            .toNSDataCopyBytes()
        let output = try uncompressor
            .uncompress(chunk: chunk)
            .toC7DataCopyBytes()
        if uncompressor._closed {
            self.closed = true
        }
        return output
    }
    
    public func send(_ data: Data, timingOut deadline: Double) throws {
        
    }
    
    public func flush(timingOut deadline: Double) throws {
        try rawStream.flush(timingOut: deadline)
    }
    
    public func close() throws {
        try rawStream.close()
    }
    
}

//private let CHUNK_SIZE: Int = 16384
private let CHUNK_SIZE: Int = 16
private let STREAM_SIZE: Int32 = Int32(sizeof(z_stream))

final class GzipUncompressor {
    
    private var _stream: z_stream
    private var _closed: Bool = false
    
    init() {
        _stream = z_stream()
    }
    
    func initialize() throws {
        let result = inflateInit2_(
            &_stream,
            MAX_WBITS + 32,
            ZLIB_VERSION,
            STREAM_SIZE
        )
        guard result == Z_OK else {
            throw GzipError(code: result, message: _stream.msg)
        }
    }
    
    func uncompress(chunk: NSData) throws -> NSData {
        
        let rawInput = UnsafeMutablePointer<Bytef>(chunk.bytes)
        _stream.next_in = rawInput
        _stream.avail_in = uInt(chunk.length)
        
        guard let output = NSMutableData(capacity: CHUNK_SIZE) else {
            throw GzipError.Memory(message: "Not enough memory")
        }
        output.length = CHUNK_SIZE
        let rawOutput = UnsafeMutablePointer<Bytef>(output.mutableBytes)
        
        _stream.next_out = rawOutput
        let writtenStart = _stream.total_out
        
        var result: Int32 = 0
        while true {
            
            _stream.avail_out = uInt(CHUNK_SIZE)
            result = inflate(&_stream, Z_SYNC_FLUSH)
            
            if _stream.avail_in > 0 {
                output.length += CHUNK_SIZE
            } else {
                break
            }
        }
        
        guard result == Z_STREAM_END || result == Z_OK else {
            throw GzipError.Stream(message: "Wrong result code \(result)")
        }
        if result == Z_STREAM_END {
            inflateEnd(&_stream)
            _closed = true
        }
        let writtenCount = _stream.total_out - writtenStart
        output.length = Int(writtenCount)
        return output
    }
    
    deinit {
        if !_closed {
            inflateEnd(&_stream)
            _closed = true
        }
    }
}

