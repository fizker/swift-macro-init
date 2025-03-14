// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
	name: "swift-macro-init",
	platforms: [
		.iOS(.v13),
		.macCatalyst(.v13),
		.macOS(.v10_15),
		.tvOS(.v13),
		.watchOS(.v6),
	],
	products: [
		.library(
			name: "InitMacro",
			targets: ["InitMacro"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
	],
	targets: [
		.macro(
			name: "InitMacroImplementation",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax")
			]
		),

		.executableTarget(
			name: "Consumer",
			dependencies: [
				"InitMacro",
			]
		),

		.target(name: "InitMacro", dependencies: ["InitMacroImplementation"]),

		.testTarget(
			name: "InitTests",
			dependencies: [
				"InitMacroImplementation",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			]
		),
	]
)
