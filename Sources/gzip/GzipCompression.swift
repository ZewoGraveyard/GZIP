import Foundation
import Czlib

private let CHUNK_SIZE: Int = 16384
//private let CHUNK_SIZE: Int = 16
private let STREAM_SIZE: Int32 = Int32(sizeof(z_stream))

final class GzipUncompressor: GzipProcessor {
    
    internal var _stream: UnsafeMutablePointer<z_stream>
    internal var closed: Bool = false
    
    init() {
        _stream = _makeStream()
    }
    
    func initialize() throws {
        let result = inflateInit2_(
            &_stream.pointee,
            MAX_WBITS + 32, //+32 to detect gzip header
            ZLIB_VERSION,
            STREAM_SIZE
        )
        guard result == Z_OK else {
            throw GzipError(code: result, message: _stream.pointee.msg)
        }
    }
    
    func process(data: NSData, isLast: Bool) throws -> NSData {
        let processChunk: @noescape () -> Int32 = { return inflate(&_stream.pointee, Z_FINISH) }
        let shouldEnd: @noescape (result: Int32) -> Bool = { $0 == Z_STREAM_END }
        let end: @noescape () -> () = { inflateEnd(&_stream.pointee) }
        return try self._process(data: data, processChunk: processChunk, shouldEnd: shouldEnd, end: end)
    }
    
    func close() {
        if !closed {
            inflateEnd(&_stream.pointee)
            closed = true
        }
    }
    
    deinit {
        close()
        _stream.deinitialize()
    }
}

final class GzipCompressor: GzipProcessor {
    
    internal var _stream: UnsafeMutablePointer<z_stream>
    internal var closed: Bool = false
    
    init() {
        _stream = _makeStream()
    }
    
    func initialize() throws {
        let result = deflateInit2_(
            &_stream.pointee,
            Z_DEFAULT_COMPRESSION,
            Z_DEFLATED,
            MAX_WBITS + 16, //+16 to specify gzip header
            MAX_MEM_LEVEL,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            STREAM_SIZE
        )
        guard result == Z_OK else {
            throw GzipError(code: result, message: _stream.pointee.msg)
        }
    }
    
    func process(data: NSData, isLast: Bool) throws -> NSData {
        let mode = isLast ? Z_FINISH : Z_SYNC_FLUSH
        let processChunk: @noescape () -> Int32 = { return deflate(&_stream.pointee, mode) }
        let shouldEnd: @noescape (result: Int32) -> Bool = { _ in isLast }
        let end: @noescape () -> () = { deflateEnd(&_stream.pointee) }
        return try self._process(data: data, processChunk: processChunk, shouldEnd: shouldEnd, end: end)
    }

    func close() {
        if !closed {
            deflateEnd(&_stream.pointee)
            closed = true
        }
    }
    
    deinit {
        close()
    }
}

func _makeStream() -> UnsafeMutablePointer<z_stream> {
    
    let stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
    let ptr = UnsafeMutablePointer<z_stream>.init(allocatingCapacity: sizeof(z_stream))
    ptr.initialize(with: stream)
    return ptr
}

extension GzipProcessor {
    
    func _process(data: NSData,
                  processChunk: @noescape () -> Int32,
                  shouldEnd: @noescape (result: Int32) -> Bool,
                  end: @noescape () -> ()) throws -> NSData {
        guard data.length > 0 else { return NSData() }
        
        let rawInput = UnsafeMutablePointer<Bytef>(data.bytes)
        _stream.pointee.next_in = rawInput
        _stream.pointee.avail_in = uInt(data.length)
        
        guard let output = NSMutableData(capacity: CHUNK_SIZE) else {
            throw GzipError.Memory(message: "Not enough memory")
        }
        output.length = CHUNK_SIZE
        let rawOutput = UnsafeMutablePointer<Bytef>(output.mutableBytes)
        
        _stream.pointee.next_out = rawOutput
        let writtenStart = _stream.pointee.total_out
        
        var result: Int32 = 0
        while true {
            
            _stream.pointee.avail_out = uInt(CHUNK_SIZE)
            result = processChunk()

            if result < 0 {
                throw GzipError(code: result, message: _stream.pointee.msg)
            }
            
            if _stream.pointee.avail_in > 0 {
                output.length += CHUNK_SIZE
            } else {
                break
            }
        }
        
        guard result == Z_STREAM_END || result == Z_OK else {
            throw GzipError.Stream(message: "Wrong result code \(result)")
        }
        if shouldEnd(result: result) {
            end()
            closed = true
        }
        let writtenCount = _stream.pointee.total_out - writtenStart
        output.length = Int(writtenCount)
        return output
    }
}


