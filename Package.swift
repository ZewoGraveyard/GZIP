import PackageDescription

let package = Package(
    name: "gzip",
    dependencies: [
    	.Package(url: "https://github.com/Zewo/zlib.git", majorVersion: 0, minor: 3)
    ]
)
