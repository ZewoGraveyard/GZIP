import HTTP
import Foundation

public enum GzipMiddlewareError: Error {
    case unsupportedStreamType
}

public struct GzipMiddleware: Middleware {
    
    public init() { }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        var req = request
        req.headers["Accept-Encoding"] = "gzip"
        
        var response = try next.respond(to: req)
        
        guard response.headers["Content-Encoding"]?.contains("gzip") ?? false else { return response }
        
        let zipped = response.body
        switch zipped {
        case .buffer(let data):
            let uncompressedData = try data.gzipUncompressed()
            response.body = .buffer(uncompressedData)
        case .reader(let stream):
            let uncompressedStream = try GzipStream(rawStream: stream, mode: .uncompress)
            response.body = .reader(uncompressedStream)
        default:
            throw GzipMiddlewareError.unsupportedStreamType
        }
        return response
    }
}
