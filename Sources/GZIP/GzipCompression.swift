import Foundation
import Czlib

private let CHUNK_SIZE: Int = 16384
private let STREAM_SIZE: Int32 = Int32(MemoryLayout<z_stream>.size)

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
    
    func process(data: Data, isLast: Bool) throws -> Data {
        let mode = isLast ? Z_FINISH : Z_SYNC_FLUSH
        let processChunk: () -> Int32 = { inflate(&self._stream.pointee, mode) }
        let loop: (Int32) -> Bool = { _ in self._stream.pointee.avail_in > 0 }
        let shouldEnd: (Int32) -> Bool = { _ in isLast }
        let end: () -> () = { inflateEnd(&self._stream.pointee) }
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
    
    func process(data: Data, isLast: Bool) throws -> Data {
        let mode = isLast ? Z_FINISH : Z_SYNC_FLUSH
        let processChunk: () -> Int32 = {
            deflate(&self._stream.pointee, mode) }
        let loop: (Int32) -> Bool = { _ in self._stream.pointee.avail_out == 0 }
        let shouldEnd: (_ result: Int32) -> Bool = { _ in isLast }
        let end: () -> () = { deflateEnd(&self._stream.pointee) }
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
    
    func _clearMemory() {
        _stream.deinitialize(count: 1)
        _stream.deallocate(capacity: 1)
    }
    
    func _process(data: Data,
                  processChunk: () -> Int32,
                  loop: (Int32) -> Bool,
                  shouldEnd: (Int32) -> Bool,
                  end: () -> ()) throws -> Data {
        guard data.count > 0 else { return Data() }
        
        _stream.pointee.next_in = data.withUnsafeBytes { (input: UnsafePointer<Bytef>) in UnsafeMutablePointer<Bytef>(mutating: input) }
        
        _stream.pointee.avail_in = uInt(data.count)
        
        var output = Data(capacity: CHUNK_SIZE)
        output.count = CHUNK_SIZE
        
        let chunkStart = _stream.pointee.total_out
        
        var result: Int32 = 0
        repeat {
            
            if _stream.pointee.total_out >= uLong(output.count) {
                output.count += CHUNK_SIZE;
            }
            
            let writtenThisChunk = _stream.pointee.total_out - chunkStart
            let availOut = uLong(output.count) - writtenThisChunk
            _stream.pointee.avail_out = uInt(availOut)
            _stream.pointee.next_out = output.withUnsafeMutableBytes{ (out: UnsafeMutablePointer<Bytef>) in
                out.advanced(by: Int(writtenThisChunk))
            }
            
            result = processChunk()
            guard result >= 0 || (result == Z_BUF_ERROR && _stream.pointee.avail_out == 0) else {
                throw GzipError(code: result, message: _stream.pointee.msg)
            }
            
        } while loop(result)
        
        guard result == Z_STREAM_END || result == Z_OK else {
            throw GzipError.stream(message: "Wrong result code \(result)")
        }
        if shouldEnd(result) {
            end()
            closed = true
        }
        let chunkCount = _stream.pointee.total_out - chunkStart
        output.count = Int(chunkCount)
        return output
    }
}


