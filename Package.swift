// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "ATM",
	platforms: [
		.macOS(.v10_15),
	],
	products: [
		.library(name: "ATM", targets: ["ATM"]),
	],
	targets: [
		.target(name: "ATM"),
		.testTarget(name: "ATMTests", dependencies: ["ATM"]),
	]
)
