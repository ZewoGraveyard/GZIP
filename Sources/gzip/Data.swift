import Foundation

extension Data: Gzippable {
    public func gzipCompressed() throws -> Data {
        return try autoreleasepoolIfAvailable {
            guard self.count > 0 else { return Data() }
            let uncompressor = GzipCompressor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: self, isLast: true)
            return outData
        }
    }
    
    public func gzipUncompressed() throws -> Data {
        return try autoreleasepoolIfAvailable {
            guard self.count > 0 else { return Data() }
            let uncompressor = GzipUncompressor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: self, isLast: true)
            return outData
        }
    }
}
