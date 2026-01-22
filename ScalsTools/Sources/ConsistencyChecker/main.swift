//
//  main.swift
//  ConsistencyChecker
//
//  Tool to check component consistency across the SCALS framework
//

import ArgumentParser
import Foundation
import ScalsToolsCore

@main
struct ConsistencyChecker: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clads-consistency-checker",
        abstract: "Check component consistency across the SCALS framework",
        discussion: """
        This tool analyzes component resolvers, renderers, and tests to ensure
        they follow consistent patterns and conventions.

        It checks:
        - Naming conventions
        - Test coverage requirements
        - File organization
        """
    )

    @Option(name: .long, help: "Path to the SCALS framework directory")
    var frameworkPath: String = ".."

    @Flag(name: .long, help: "Show verbose output")
    var verbose: Bool = false

    func run() async throws {
        Console.section("SCALS Component Consistency Checker")

        let baseURL = URL(fileURLWithPath: frameworkPath)
        Console.info("Analyzing framework at: \(baseURL.path)")

        var issues = 0

        // Check component resolvers
        Console.subsection("Checking Component Resolvers")
        let modulesURL = baseURL.appendingPathComponent("ScalsModules/ComponentResolvers")

        guard FileSystemUtilities.fileExists(at: modulesURL) else {
            Console.error("ScalsModules/ComponentResolvers directory not found")
            throw ExitCode(1)
        }

        let resolverFiles = try FileSystemUtilities.findFiles(withExtension: "swift", in: modulesURL)
        Console.info("Found \(resolverFiles.count) resolver files")

        for file in resolverFiles {
            let fileName = file.lastPathComponent
            guard fileName.hasSuffix("ComponentResolver.swift") else { continue }

            if verbose {
                Console.info("Checking \(fileName)")
            }

            // Extract component name
            let componentName = fileName
                .replacingOccurrences(of: "ComponentResolver.swift", with: "")

            // Check for corresponding test file
            let testFileName = "\(componentName)ComponentResolutionTests.swift"
            let testsURL = baseURL.appendingPathComponent("SCALSTests/Resolution/\(testFileName)")

            if !FileSystemUtilities.fileExists(at: testsURL) {
                Console.warning("Missing test file: \(testFileName)")
                issues += 1
            } else if verbose {
                Console.success("Test file exists: \(testFileName)")
            }

            // Check renderer implementations
            let swiftUIRenderer = "\(componentName)Renderer.swift"
            let renderersURL = baseURL.appendingPathComponent("SCALS/Renderers/SwiftUI/NodeRenderers/\(swiftUIRenderer)")

            if !FileSystemUtilities.fileExists(at: renderersURL) {
                Console.warning("Missing SwiftUI renderer: \(swiftUIRenderer)")
                issues += 1
            } else if verbose {
                Console.success("SwiftUI renderer exists: \(swiftUIRenderer)")
            }
        }

        // Summary
        Console.section("Summary")
        if issues == 0 {
            Console.success("No issues found! All components are consistent.")
        } else {
            Console.warning("Found \(issues) issue(s)")
        }

        if issues > 0 {
            throw ExitCode(1)
        }
    }
}
