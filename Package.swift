// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "ATM",
	products: [
		.library(name: "ATM", targets: ["ATM"]),
	],
	targets: [
		.target(name: "ATM"),
		.testTarget(name: "ATMTests", dependencies: ["ATM"]),
	]
)
