import XCTest
@testable import GZIPTests

XCTMain([
	 testCase(GZIPTests.allTests),
	 testCase(GzipMiddlewareTests.allTests),
	 testCase(StreamTests.allTests),
])
