// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SportsScraper",
    targets: [
        Target(
            name: "SportsScraperServer",
            dependencies: [ .Target(name: "SportsScraperAPI")]
        ),
        Target(
            name: "SportsScraperAPI"
        )
    ],
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", majorVersion: 4, minor: 0),
        .Package(url: "https://github.com/honghaoz/Ji.git", majorVersion: 2),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Swift/Kitura-Request.git", majorVersion: 0),
        .Package(url: "https://github.com/Zewo/CLibXML2.git", majorVersion: 0, minor: 6)
    ]
)
