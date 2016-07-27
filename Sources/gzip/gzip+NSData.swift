import Foundation

extension NSData: Gzippable {
    
    public func gzipCompressed() throws -> NSData {
        return try autoreleasepoolIfAvailable {
            guard self.length > 0 else { return NSData() }
            let uncompressor = GzipCompressor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: self, isLast: true)
            return outData
        }
    }
    
    public func gzipUncompressed() throws -> NSData {
        return try autoreleasepoolIfAvailable {
            guard self.length > 0 else { return NSData() }
            let uncompressor = GzipUncompressor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: self, isLast: true)
            return outData
        }
    }
}

extension NSData {
    public func toFoundationData() -> Foundation.Data {
        #if os(Linux)
        return Data._unconditionallyBridgeFromObjectiveC(self)
        #else
        return Data(referencing: self)
        #endif
    }
}

extension Foundation.Data {
    public func toNSData() -> NSData {
        #if os(Linux)
        return self._bridgeToObjectiveC()
        #else
        return NSData(data: self)
        #endif
    }
}

extension Data: Gzippable {
    
    public func gzipCompressed() throws -> Data {
        return try self.toNSData().gzipCompressed().toFoundationData()
    }
    
    public func gzipUncompressed() throws -> Data {
        return try self.toNSData().gzipUncompressed().toFoundationData()
    }
}
