# gzip

[![Build Status](https://travis-ci.org/Zewo/gzip.svg?branch=master)](https://travis-ci.org/Zewo/gzip)
![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20OS%20X-blue.svg)
![Package Managers](https://img.shields.io/badge/package%20managers-SwiftPM-yellow.svg)

[![Blog](https://img.shields.io/badge/blog-honzadvorsky.com-green.svg)](http://honzadvorsky.com)
[![Twitter Czechboy0](https://img.shields.io/badge/twitter-czechboy0-green.svg)](http://twitter.com/czechboy0)

> gzip data compression from Swift, OS X & Linux ready

# Usage
Works on `NSData` and `C7.Data`, or anything [`Gzippable`](https://github.com/czechboy0/gzip/blob/master/Sources/gzip/gzip%2BNSData.swift#L42-46)

```swift
let myData = ... //NSData, Data or C7.Data
let myGzipCompressedData = try myData.gzipCompressed() //NSData, Data or C7.Data
...
let myGzipUncompressedData = try myGzipCompressedData.gzipUncompressed() //NSData, Data or C7.Data
... //PROFIT!
```

Also contains a `GzipStream` class which conforms to `C7.ReceivingStream`, so it can be easily attached in a pipeline, like

```swift
let gzippedStream = ... //e.g. from S4.Body
let uncompressedStream = try GzipStream(rawStream: gzippedStream, mode: .uncompress)
... //PROFIT!
```

Also contains a `S4` compatible `Middleware`, which automatically adds the right headers to the request and decompresses the response if it's compressed.

```swift
let client = HTTPSClient.Client("https://my.server")
let response = client.get("/compressed", middleware: GzipMiddleware())
response.body.becomeBuffer() //<- Already decompressed data
```

# Details

As this library uses a SwiftPM-compatible source of [zlib](https://github.com/Zewo/zlib), you don't need to install anything manually before using it. Even though both OS X and Linux have a preinstalled version of `zlib`, unfortunately each has a different version, making its potential use inconsistent. In our case everything is compiled from source, so you can be sure to get the same results everywhere. :100:

# Installation

## Swift Package Manager

```swift
.Package(url: "https://github.com/Zewo/gzip.git", majorVersion: 0, minor: 4)
```

:gift_heart: Contributing
------------
Please create an issue with a description of your problem or open a pull request with a fix.

:+1: Thanks
------
This project was initially inspired by [NSData+GZIP](https://github.com/1024jp/NSData-GZIP), thank you!

:v: License
-------
MIT

:alien: Author
------
Honza Dvorsky - http://honzadvorsky.com, [@czechboy0](http://twitter.com/czechboy0)

