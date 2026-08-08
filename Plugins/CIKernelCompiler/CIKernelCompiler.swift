import Foundation
import PackagePlugin

/// Compiles the Core Image Metal kernels that live in the package's `Kernels` directory.
///
/// They are kept outside `Sources` on purpose: a `.metal` file inside a target's directory gets
/// picked up by Xcode's default Metal build rule, which compiles it without `-fcikernel` and so
/// produces a library Core Image cannot load. A directory that belongs to no target is invisible to
/// both build systems, leaving this plugin as the only thing that compiles it.
@main
struct CIKernelCompiler: BuildToolPlugin {

    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let kernels = context.package.directory.appending("Kernels")
        let script = kernels.appending("build-cikernel.sh")

        let names = try FileManager.default
            .contentsOfDirectory(atPath: kernels.string)
            .filter { $0.hasSuffix(".ci.metal") }
            .sorted()

        return names.map { name in
            let source = kernels.appending(name)
            // "ImageProcKernel.ci.metal" -> "ImageProcKernel.ci.metallib"
            let output = context.pluginWorkDirectory
                .appending("\(name.dropLast(".metal".count)).metallib")

            return .buildCommand(
                displayName: "Compiling CIKernel \(name)",
                executable: Path("/bin/sh"),
                arguments: [script.string, source.string, output.string,
                            context.pluginWorkDirectory.string],
                environment: ["XCRUN_NO_CACHE": "1"],
                inputFiles: [source, script],
                outputFiles: [output])
        }
    }
}
