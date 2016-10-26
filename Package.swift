import PackageDescription

let package = Package(
    name: "GZIP",
    dependencies: [
        .Package(url: "https://github.com/Zewo/HTTP.git", majorVersion: 0, minor: 14),
    	.Package(url: "https://github.com/Zewo/CZlib.git", majorVersion: 0, minor: 4),
    	.Package(url: "https://github.com/Zewo/Axis.git", majorVersion: 0, minor: 14),

    ]
)
