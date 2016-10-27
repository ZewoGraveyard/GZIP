import XCTest
import HTTP
@testable import GZIP

public class GzipMiddlewareTests : XCTestCase {
    let middleware = GzipMiddleware()

    func testHeaderAdded() throws {
        let request = Request()

        _ = try middleware.respond(to: request, chainingTo: BasicResponder { request in
            XCTAssert(request.headers.contains{
                $0.key.string == "Accept-Encoding" && $0.value == "gzip"
            })
            return Response()
        })
    }

    func testGzipBuffer() throws {
        let request = Request()
        let inputData = "H4sICElFQ1cAA2ZpbGUudHh0AMtIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==".fromBase64()
        
        let response = try middleware.respond(to: request, chainingTo: BasicResponder { request in
            return Response(headers: ["Content-Encoding": "gzip"], body: Body.buffer(Buffer(inputData)))
        })
        
        switch response.body {
        case .buffer(let buf):
            XCTAssertEqual(String(buf), "hello world foo bar foo foo\n")
        default:
            XCTFail()
        }
    }
    
    func testGzipStream() throws {
        let request = Request()
        let inputData = "H4sICElFQ1cAA2ZpbGUudHh0AMtIzcnJVyjPL8pJUUjLz1dISiwC00DMBQBN/m/HHAAAAA==".fromBase64()
        
        let response = try middleware.respond(to: request, chainingTo: BasicResponder { request in
            return Response(headers: ["Content-Encoding": "gzip"], body: Body.reader(DrainStream(inputData)))
        })
        
        switch response.body {
        case .reader(let stream):
            let buf = try stream.drain(deadline: .never)
            XCTAssertEqual(String(buf), "hello world foo bar foo foo\n")
        default:
            XCTFail()
        }
    }
}

extension GzipMiddlewareTests {
    public static var allTests: [(String, (GzipMiddlewareTests) -> () throws -> Void)] {
        return [
           ("testHeaderAdded", testHeaderAdded),
           ("testGzipBuffer", testGzipBuffer),
           ("testGzipStream", testGzipStream),
        ]
    }
}
