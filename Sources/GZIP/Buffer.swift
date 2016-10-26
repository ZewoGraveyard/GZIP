import Axis
import Foundation

extension Buffer {
    init(_ data: Data) {
        let buf = data.withUnsafeBytes { (ptr: UnsafePointer<Byte>) -> UnsafeBufferPointer<Byte> in
            return UnsafeBufferPointer(start: ptr, count: data.count)
        }
        
        self.init(buf)
    }
}

extension Buffer {
    
    public func gzipCompressed() throws -> Buffer {
        return try autoreleasepoolIfAvailable {
            guard self.count > 0 else { return Buffer() }
            let uncompressor = GzipMode.compress.processor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: Data(self), isLast: true)
            
            return Buffer(outData)
        }
    }
    
    public func gzipUncompressed() throws -> Buffer {
        return try autoreleasepoolIfAvailable {
            guard self.count > 0 else { return Buffer() }
            let uncompressor = GzipMode.uncompress.processor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: Data(self), isLast: true)
            return Buffer(outData)
        }
    }
}
