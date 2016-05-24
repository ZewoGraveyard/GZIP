import Foundation

extension NSData: Gzippable {
    
    public func gzipCompressed() throws -> NSData {
        return try autoreleasepoolIfAvailable {
            guard self.length > 0 else { return NSData() }
            let uncompressor = GzipCompressor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: self)
            return outData
        }
    }
    
    public func gzipUncompressed() throws -> NSData {
        return try autoreleasepoolIfAvailable {
            guard self.length > 0 else { return NSData() }
            let uncompressor = GzipUncompressor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: self)
            return outData
        }
    }
}
