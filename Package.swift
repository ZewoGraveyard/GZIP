import PackageDescription

let package = Package(
    name: "gzip",
    dependencies: [
    	.Package(url: "https://github.com/czechboy0/zlib.git", majorVersion: 0, minor: 1),
    	.Package(url: "https://github.com/open-swift/C7.git", majorVersion: 0, minor: 7)
    ]
)
