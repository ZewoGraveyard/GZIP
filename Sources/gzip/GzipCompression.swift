import Foundation
import Czlib

private let CHUNK_SIZE: Int = 16384
//private let CHUNK_SIZE: Int = 16
private let STREAM_SIZE: Int32 = Int32(sizeof(z_stream))

final class GzipUncompressor: GzipProcessor {
    
    private var _stream: z_stream
    internal var closed: Bool = false
    
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
    
    func process(data: NSData) throws -> NSData {
        
        guard data.length > 0 else { return NSData() }
        
        let rawInput = UnsafeMutablePointer<Bytef>(data.bytes)
        _stream.next_in = rawInput
        _stream.avail_in = uInt(data.length)
        
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
            
            if result < 0 {
                throw GzipError(code: result, message: _stream.msg)
            }
            
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
            closed = true
        }
        let writtenCount = _stream.total_out - writtenStart
        output.length = Int(writtenCount)
        return output
    }
    
    deinit {
        if !closed {
            inflateEnd(&_stream)
            closed = true
        }
    }
}

final class GzipCompressor: GzipProcessor {
    
    private var _stream: z_stream
    internal var closed: Bool = false
    
    init() {
        _stream = z_stream()
    }
    
    func initialize() throws {
        //TODO
    }
    
    func process(data: NSData) throws -> NSData {
        
        guard data.length > 0 else { return NSData() }
        
        //TODO
        return NSData()
    }
    
    deinit {
        if !closed {
            inflateEnd(&_stream)
            closed = true
        }
    }
}



