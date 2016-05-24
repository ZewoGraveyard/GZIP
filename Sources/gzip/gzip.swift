import Czlib
import Foundation

public enum GzipMode {
    case compress
    case uncompress
    
    internal func processor() -> GzipProcessor {
        switch self {
        case .compress: return GzipCompressor()
        case .uncompress: return GzipUncompressor()
        }
    }
}

public protocol Gzippable {
    associatedtype DataType
    func gzipCompressed() throws -> DataType
    func gzipUncompressed() throws -> DataType
}

protocol GzipProcessor {
    func initialize() throws
    func process(data: NSData) throws -> NSData
    var closed: Bool { get }
}

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
    
    internal init(code: Int32, message cmessage: UnsafePointer<CChar>)
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

