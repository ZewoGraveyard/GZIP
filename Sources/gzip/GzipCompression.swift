import Foundation
import Czlib

private let CHUNK_SIZE: Int = 16384
private let STREAM_SIZE: Int32 = Int32(sizeof(z_stream.self))

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
        let mode = isLast ? Z_FINISH : Z_SYNC_FLUSH
        let processChunk: @noescape () -> Int32 = { return inflate(&_stream.pointee, mode) }
        let loop: @noescape (result: Int32) -> Bool = { _ in _stream.pointee.avail_in > 0 }
        let shouldEnd: @noescape (result: Int32) -> Bool = { _ in isLast }
        let end: @noescape () -> () = { inflateEnd(&_stream.pointee) }
        return try self._process(data: data, processChunk: processChunk, loop: loop, shouldEnd: shouldEnd, end: end)
    }
    
    func close() {
        if !closed {
            inflateEnd(&_stream.pointee)
            closed = true
        }
    }
    
    deinit {
        close()
        _clearMemory()
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
        let loop: @noescape (result: Int32) -> Bool = { result in
            let fullOutput = self._stream.pointee.avail_out == 0
            let finishAndOk = mode == Z_FINISH && result == Z_OK
            return fullOutput || finishAndOk
        }
        let shouldEnd: @noescape (result: Int32) -> Bool = { _ in isLast }
        let end: @noescape () -> () = { deflateEnd(&_stream.pointee) }
        return try self._process(data: data, processChunk: processChunk, loop: loop, shouldEnd: shouldEnd, end: end)
    }

    func close() {
        if !closed {
            deflateEnd(&_stream.pointee)
            closed = true
        }
    }
    
    deinit {
        close()
        _clearMemory()
    }
}

func _makeStream() -> UnsafeMutablePointer<z_stream> {
    
    let stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
    let ptr = UnsafeMutablePointer<z_stream>.allocate(capacity: 1)
    ptr.initialize(to: stream)
    return ptr
}

extension GzipProcessor {
    
    /// Call before closing the stream, to ensure all data has been sent out.
    public func safeFlush() throws -> NSData? {
        guard !closed else { return nil }
        return try flush()
    }
    
    /// Call when all data has been submitted, but none of the calls
    /// contains "last: true", meaning there might still be buffered data.
    /// Not safe to call if stream is already closed. 
    /// Use safeFlush() if you're unsure if the stream is closed
    public func flush() throws -> NSData {
        return try self.process(data: NSData(), isLast: true)
    }
    
    func _clearMemory() {
        _stream.deinitialize(count: 1)
        _stream.deallocate(capacity: 1)
    }
    
    func _process(data: NSData,
                  processChunk: @noescape () -> Int32,
                  loop: @noescape (result: Int32) -> Bool,
                  shouldEnd: @noescape (result: Int32) -> Bool,
                  end: @noescape () -> ()) throws -> NSData {
        
        let rawInput = UnsafeMutablePointer<Bytef>(data.bytes)
        _stream.pointee.next_in = rawInput
        _stream.pointee.avail_in = uInt(data.length)
        
        guard let output = NSMutableData(capacity: CHUNK_SIZE) else {
            throw GzipError.memory(message: "Not enough memory")
        }
        output.length = CHUNK_SIZE
        
        let chunkStart = _stream.pointee.total_out
        
        var result: Int32 = 0
        repeat {
            
            if _stream.pointee.total_out >= uLong(output.length) {
                output.length += CHUNK_SIZE;
            }
            
            let writtenThisChunk = _stream.pointee.total_out - chunkStart
            let availOut = uLong(output.length) - writtenThisChunk
            _stream.pointee.avail_out = uInt(availOut)
            _stream.pointee.next_out = UnsafeMutablePointer<Bytef>(output.mutableBytes).advanced(by: Int(writtenThisChunk))
            
            result = processChunk()
            guard result >= 0 || (result == Z_BUF_ERROR && _stream.pointee.avail_out == 0) else {
                throw GzipError(code: result, message: _stream.pointee.msg)
            }
            
        } while loop(result: result)
        
        guard result == Z_STREAM_END || result == Z_OK else {
            throw GzipError.stream(message: "Wrong result code \(result)")
        }
        if shouldEnd(result: result) {
            end()
            closed = true
        }
        let chunkCount = _stream.pointee.total_out - chunkStart
        output.length = Int(chunkCount)
        return output
    }
}


