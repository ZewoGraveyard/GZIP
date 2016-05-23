import C7
import Foundation

extension Data: Gzippable {
    
    public func gzipCompressed() throws -> Data {
        return try self
            .toNSDataCopyBytes()
            .gzipCompressed()
            .toC7DataCopyBytes()
    }
    
    public func gzipUncompressed() throws -> Data {
        return try self
            .toNSDataCopyBytes()
            .gzipUncompressed()
            .toC7DataCopyBytes()
    }
}

// TODO: investigate how to properly *not* copy data when handing them
// between C7.Data and NSData. Right now we err on the side of caution,
// doing a bit more copying, but we know there are no leaks/crashes.

extension NSData {
    
    // Safe, copies bytes, so pretty slow.
    func toC7DataCopyBytes() -> C7.Data {
        return Data(Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(self.bytes), count: self.length)))
    }
    
    //TODO: find a way to hand over the data to C7.Data but making sure
    //the bytes don't get deallocated when NSData goes away.
    //Some CFRetain maybe? We need to avoid the copying.
    func toC7DataNoCopyBytes() -> C7.Data {
        let count = self.length
        var array = Array(repeating: UInt8(0), count: count)
        self.getBytes(&array, length:count)
        return Data(array)
    }
}

extension C7.Data {
    
    // Safe, copies bytes, so pretty slow.
    func toNSDataCopyBytes() -> NSData {
        return NSData(bytes: self.bytes, length: self.count)
    }
    
    // Potentially unsafe, only use if the lifetime of the returned NSData
    // will be strictly shorter than self
    func toNSDataNoCopyBytes() -> NSData {
        let mutable = UnsafeMutablePointer<UInt8>(self.bytes)
        //don't dealloc when NSData goes away, as the lifetime of the encapsulating
        //data is strictly greater than of this temporary wrapper
        return NSData(bytesNoCopy: mutable, length: self.count, freeWhenDone: false)
    }
}

