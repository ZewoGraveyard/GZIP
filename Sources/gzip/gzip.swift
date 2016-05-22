import Czlib
import C7
import Foundation

private let CHUNK_SIZE: Int = 2 ^ 14
private let STREAM_SIZE: Int32 = Int32(sizeof(z_stream))

public struct gzip {
    
    public static func compress(data: Data) throws -> NSData {
        
        var mutableData: [Bytef] = data.bytes
        let raw = mutableData.withUnsafeMutableBufferPointer { $0 }.baseAddress
        
        var stream = z_stream(
            next_in: raw,
            avail_in: uInt(mutableData.count),
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
            //throw error
            print("error")
            throw GzipError.unknown
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
        
        //TODO: don't use NSData, use Data instead, once we get it working
        //also ensure that no unnecessary copying is happening
//        let outData = Data(data.arrayOfBytes())
//        return outData
    }
    
}

enum GzipError: ErrorProtocol {
    case unknown
}

extension NSData {
    func arrayOfBytes() -> [UInt8] {
        return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(self.bytes), count: self.length))
    }
}
