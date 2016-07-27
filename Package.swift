import PackageDescription

let package = Package(
    name: "gzip",
    dependencies: [
    	.Package(url: "https://github.com/Zewo/zlib.git", majorVersion: 0, minor: 3),
    	.Package(url: "https://github.com/open-swift/C7.git", majorVersion: 0, minor: 10),
    	.Package(url: "https://github.com/open-swift/S4.git", majorVersion: 0, minor: 11)
    ]
)
