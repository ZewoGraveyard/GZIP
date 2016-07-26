import S4

public enum GzipMiddlewareError: Error {
    case unsupportedStreamType
}

public struct GzipMiddleware: Middleware {
    
    public init() { }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        var req = request
        req.headers["Accept-Encoding"] = "gzip"
        
        var response = try next.respond(to: req)
        
        guard response.headers["Content-Encoding"] == "gzip" else {
            return response
        }
        
        let zipped = response.body
        switch zipped {
        case .buffer(let data):
            let uncompressedData = try data.gzipUncompressed()
            response.body = .buffer(uncompressedData)
        case .receiver(let stream):
            let uncompressedStream: ReceivingStream = try GzipStream(rawStream: stream, mode: .uncompress)
            response.body = .receiver(uncompressedStream)
        default:
            throw GzipMiddlewareError.unsupportedStreamType
        }
        return response
    }
}
