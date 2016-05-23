import Czlib
import Foundation

private let CHUNK_SIZE: Int = 2 ^ 14
private let STREAM_SIZE: Int32 = Int32(sizeof(z_stream))

public enum GzipError: ErrorProtocol {
    //Reference: http://www.zlib.net/manual.html
    
    /// The stream structure was inconsistent.
    case Stream(message: String)
    
    ///The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
    case Data(message: String)
    
    /// There was not enough memory.
    case Memory(message: String)
    
    /// No progress is possible or there was not enough room in the output buffer.
    case Buffer(message: String)
    
    /// The zlib library version is incompatible with the version assumed by the caller.
    case Version(message: String)
    
    /// An unknown error occurred.
    case Unknown(message: String, code: Int)
    
    private init(code: Int32, message cmessage: UnsafePointer<CChar>)
    {
        let message =  String(validatingUTF8: cmessage) ?? "unknown gzip error"
        switch code {
        case Z_STREAM_ERROR: self = .Stream(message: message)
        case Z_DATA_ERROR: self = .Data(message: message)
        case Z_MEM_ERROR: self = .Memory(message: message)
        case Z_BUF_ERROR: self = .Buffer(message: message)
        case Z_VERSION_ERROR: self = .Version(message: message)
        default: self = .Unknown(message: message, code: Int(code))
        }
    }
}

public protocol Gzippable {
    associatedtype DataType
    func gzipCompressed() throws -> DataType
    func gzipUncompressed() throws -> DataType
}

extension NSData: Gzippable {
    
    public func gzipCompressed() throws -> NSData {
        return try autoreleasepool {
            guard self.length > 0 else { return NSData() }

            var stream = makeStream()
            let result = deflateInit2_(
                &stream,
                Z_DEFAULT_COMPRESSION,
                Z_DEFLATED,
                MAX_WBITS + 16,
                MAX_MEM_LEVEL,
                Z_DEFAULT_STRATEGY,
                ZLIB_VERSION,
                STREAM_SIZE
            )
            guard result == Z_OK else {
                throw GzipError(code: result, message: stream.msg)
            }
            
            let data = NSMutableData(length: CHUNK_SIZE)!
            while stream.avail_out == 0 {
                if Int(stream.total_out) >= data.length {
                    data.length += CHUNK_SIZE
                }
                
                stream.next_out = UnsafeMutablePointer<Bytef>(data.mutableBytes).advanced(by: Int(stream.total_out))
                stream.avail_out = uInt(data.length) - uInt(stream.total_out)
                
                deflate(&stream, Z_FINISH)
            }
            
            deflateEnd(&stream)
            data.length = Int(stream.total_out)
            return data
        }
    }
    
    public func gzipUncompressed() throws -> NSData {
        return try autoreleasepool {
            guard self.length > 0 else { return NSData() }
            
            var stream = self.makeStream()
            var result = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, STREAM_SIZE)
            
            guard result == Z_OK else {
                throw GzipError(code: result, message: stream.msg)
            }
            
            let data = NSMutableData(length: self.length * 2)!
            
            repeat {
                if Int(stream.total_out) >= data.length {
                    data.length += self.length / 2
                }
                
                stream.next_out = UnsafeMutablePointer<Bytef>(data.mutableBytes).advanced(by: Int(stream.total_out))
                stream.avail_out = uInt(data.length) - uInt(stream.total_out)
                result = inflate(&stream, Z_SYNC_FLUSH)
            } while result == Z_OK
            
            guard inflateEnd(&stream) == Z_OK && result == Z_STREAM_END else {
                throw GzipError(code: result, message: stream.msg)
            }
            
            data.length = Int(stream.total_out)
            return data
        }
    }
    
    private func makeStream() -> z_stream {
        let raw = UnsafeMutablePointer<Bytef>(self.bytes)
        return z_stream(
            next_in: raw,
            avail_in: uInt(self.length),
            total_in: 0,
            next_out: nil,
            avail_out: 0,
            total_out: 0,
            msg: nil,
            state: nil,
            zalloc: nil,
            zfree: nil,
            opaque: nil,
            data_type: 0,
            adler: 0,
            reserved: 0
        )
    }
}
