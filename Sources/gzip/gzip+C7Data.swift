import C7
import Foundation

extension C7.Data: Gzippable {
    public func gzipCompressed() throws -> C7.Data {
        return try self
            .toNSData()
            .gzipCompressed()
            .toC7Data()
    }
    
    public func gzipUncompressed() throws -> C7.Data {
        return try self
            .toNSData()
            .gzipUncompressed()
            .toC7Data()
    }
}

// TODO: investigate how to properly *not* copy data when handing them
// between C7.Data and NSData. Right now we err on the side of caution,
// doing a bit more copying, but we know there are no leaks/crashes.


// WIP: Still makes a copy, but there's gotta be a way to not have to make it

extension NSData {
    func toC7Data() -> C7.Data {
        let start = UnsafePointer<UInt8>(self.bytes)
        let bytes = UnsafeBufferPointer<UInt8>(start: start, count: self.length)
        let array = Array<UInt8>(bytes) // <-- How do I stop this from copying?
        let data = Data(array)
        return data
    }
}

extension C7.Data {
    func toNSData() -> NSData {
        // This version does *not* make a copy, so it basically toll-free & is still safe
        let bytes = self.bytes
        let mutable = UnsafeMutablePointer<UInt8>(bytes)
        return NSData(bytesNoCopy: mutable, length: bytes.count, freeWhenDone: false)
        
        // Copying version below, just in case of issues
        //return NSData(bytes: bytes, length: bytes.count)
    }
}

