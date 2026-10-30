// swift-tools-version:6.2

import PackageDescription
import Foundation

// Agentastic fork: this manifest differs from upstream so that Bazel's
// rules_swift_package_manager (1.11.x) builds the same sources SwiftPM does.
// That ruleset does not run build-tool plugins and ignores package traits: it
// would drop the plugin's generated sources and apply every trait-conditioned
// setting (SWIFTTERM_EMBEDDED, SWIFTTERM_WASM, the Embedded feature) to all
// builds. So:
// - The SwiftTermBuildInfoPlugin output is checked in under
//   Sources/SwiftTerm/Generated. Regenerate it after a sync with:
//     SWIFTTERM_BUILD_BRANCH=agentastic SWIFTTERM_BUILD_COMMIT=<upstream sha> \
//     SWIFTTERM_BUILD_DIRTY=false swift run SwiftTermBuildInfoGenerator \
//       "$PWD" "$PWD/Sources/SwiftTerm/Generated/SwiftTermBuildInfo.swift" \
//       "$PWD/Sources/SwiftTerm/Generated/SwiftTermTerminfo.swift"
// - There are no traits, no swift-png dependency (only non-Apple platforms
//   used it, behind `canImport`), and no Embedded or WASM variants.

let environment = ProcessInfo.processInfo.environment

// A package manifest is compiled and run on the HOST, so `os(Linux)` is false
// when cross-compiling from macOS to Linux. Allow Apple sources to be excluded
// explicitly for that case.
let excludeAppleSources =
    environment["SWIFTTERM_EXCLUDE_APPLE"] == "1"
#if os(Linux) || os(Windows)
let platformExcludes = ["Apple", "Mac", "iOS"]
#else
let platformExcludes: [String] = excludeAppleSources ? ["Apple", "Mac", "iOS"] : []
#endif

let buildInfoTargets: [Target] = [
    .executableTarget(
        name: "SwiftTermBuildInfoGenerator",
        path: "Sources/SwiftTermBuildInfoGenerator"
    ),
    .plugin(
        name: "SwiftTermBuildInfoPlugin",
        capability: .buildTool(),
        dependencies: ["SwiftTermBuildInfoGenerator"]
    )
]

let swiftTermTarget: Target = .target(
    name: "SwiftTerm",
    path: "Sources/SwiftTerm",
    exclude: platformExcludes + [
        "Mac/README.md",
        "Apple/Metal/Shaders.metal",
    ]
)

#if os(Windows)
let products: [Product] = [
    .executable(name: "SwiftTermFuzz", targets: ["SwiftTermFuzz"]),
    .library(name: "SwiftTerm", targets: ["SwiftTerm"]),
]

let targets: [Target] = [
    swiftTermTarget,
    .executableTarget(
        name: "SwiftTermFuzz",
        dependencies: ["SwiftTerm"],
        path: "Sources/SwiftTermFuzz"
    ),
    .testTarget(
        name: "SwiftTermTests",
        dependencies: ["SwiftTerm"],
        path: "Tests/SwiftTermTests",
        resources: [
            .copy("Fixtures/xterm-ghostty.infocmp"),
            .copy("Fixtures/esctest-known-good.txt"),
            .copy("Fixtures/GhosttyFuzzCorpus"),
            .copy("KittyGraphics/Fixtures")
        ]
    )
] + buildInfoTargets
#else
let products: [Product] = [
    .executable(name: "SwiftTermFuzz", targets: ["SwiftTermFuzz"]),
    .executable(name: "termcast", targets: ["Termcast"]),
    .library(name: "SwiftTerm", targets: ["SwiftTerm"]),
]

let targets: [Target] = [
    swiftTermTarget,
    .executableTarget(
        name: "SwiftTermFuzz",
        dependencies: ["SwiftTerm"],
        path: "Sources/SwiftTermFuzz"
    ),
    .executableTarget(
        name: "Termcast",
        dependencies: [
            "SwiftTerm",
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ],
        path: "Sources/Termcast"
    ),
    .testTarget(
        name: "SwiftTermTests",
        dependencies: ["SwiftTerm"],
        path: "Tests/SwiftTermTests",
        resources: [
            .copy("Fixtures/xterm-ghostty.infocmp"),
            .copy("Fixtures/esctest-known-good.txt"),
            .copy("Fixtures/GhosttyFuzzCorpus"),
            .copy("KittyGraphics/Fixtures")
        ]
    )
] + buildInfoTargets
#endif

let package = Package(
    name: "SwiftTerm",
    platforms: [
        .iOS(.v14),
        // The snapshot Embedded Swift standard library needs macOS 14. Do not
        // raise the package minimum for that: Embedded macOS builds pass an
        // explicit `--triple arm64-apple-macosx14.0` (or later) instead.
        .macOS(.v11),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: products,
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3"),
    ],
//        .package(url: "https://github.com/swiftlang/swift-subprocess", revision: "426790f3f24afa60b418450da0afaa20a8b3bdd4")
    targets: targets,
    swiftLanguageModes: [.v6]
)
