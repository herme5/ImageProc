// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ImageProc",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ImageProc", targets: ["ImageProc"])
    ],
    targets: [
        .target(
            name: "ImageProc",
            plugins: [.plugin(name: "CIKernelCompiler")]),
        .plugin(
            name: "CIKernelCompiler",
            capability: .buildTool()),
        .testTarget(
            name: "ImageProcTests",
            dependencies: ["ImageProc"],
            resources: [.process("Resources")])
    ]
)
