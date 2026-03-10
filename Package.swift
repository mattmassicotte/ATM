// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "ATM",
	platforms: [
		.macOS(.v10_15),
		.macCatalyst(.v13),
		.iOS(.v13),
		.tvOS(.v13),
		.watchOS(.v6),
		.visionOS(.v1),
	],
	products: [
		.library(name: "ATM", targets: ["ATM"]),
	],
	dependencies: [
		.package(url: "https://github.com/mattmassicotte/TaskGate", revision: "b6259ff6b1927e5752b9ab0ff03f794c16547f19"),
	],
	targets: [
		.target(
			name: "ATM",
			dependencies: ["TaskGate"],
			swiftSettings: [
				.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
			]
		),
		.testTarget(
			name: "ATMTests",
			dependencies: ["ATM"],
			swiftSettings: [
				.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
			]
		),
	]
)
