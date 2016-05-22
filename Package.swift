import PackageDescription

let package = Package(
    name: "gzip",
    dependencies: [
    	.Package(url: "https://github.com/czechboy0/zlib.git", majorVersion: 0, minor: 1)
    ]
)
