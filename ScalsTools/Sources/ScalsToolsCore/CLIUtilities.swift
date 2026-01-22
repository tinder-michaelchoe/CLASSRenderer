//
//  CLIUtilities.swift
//  ScalsToolsCore
//
//  Common utilities for CLI tools
//

import Foundation

/// Console output utilities with colors and formatting
public enum Console {
    public static func success(_ message: String) {
        print("✅ \(message)")
    }

    public static func error(_ message: String) {
        print("❌ \(message)")
    }

    public static func warning(_ message: String) {
        print("⚠️  \(message)")
    }

    public static func info(_ message: String) {
        print("ℹ️  \(message)")
    }

    public static func section(_ title: String) {
        print("\n" + String(repeating: "=", count: 60))
        print(title)
        print(String(repeating: "=", count: 60) + "\n")
    }

    public static func subsection(_ title: String) {
        print("\n--- \(title) ---")
    }

    public static func progress(_ message: String) {
        print("⏳ \(message)")
    }
}

/// File system utilities
public enum FileSystemUtilities {
    public static func findFile(named: String, in directory: URL) throws -> URL? {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == named {
                return fileURL
            }
        }

        return nil
    }

    public static func findFiles(
        withExtension extension: String,
        in directory: URL
    ) throws -> [URL] {
        let fileManager = FileManager.default
        var results: [URL] = []

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == `extension` {
                results.append(fileURL)
            }
        }

        return results
    }

    public static func readFile(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    public static func writeFile(at url: URL, content: String) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    public static func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}

/// String utilities
public extension String {
    /// Convert PascalCase to snake_case
    var snakeCase: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: count)
        return regex.stringByReplacingMatches(
            in: self,
            range: range,
            withTemplate: "$1_$2"
        ).lowercased()
    }

    /// Convert snake_case to PascalCase
    var pascalCase: String {
        split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
    }

    /// Convert snake_case to camelCase
    var camelCase: String {
        let pascal = pascalCase
        return pascal.prefix(1).lowercased() + pascal.dropFirst()
    }

    /// Indent each line by the specified number of spaces
    func indented(by spaces: Int = 4) -> String {
        let indent = String(repeating: " ", count: spaces)
        return split(separator: "\n")
            .map { indent + $0 }
            .joined(separator: "\n")
    }
}

/// Code formatting utilities
public enum CodeFormatter {
    public static func formatSwiftCode(_ code: String) -> String {
        // Basic formatting - in production, use swift-format
        code.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func formatJSON(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(
                  withJSONObject: object,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let result = String(data: formatted, encoding: .utf8) else {
            return json
        }
        return result
    }
}

/// Progress tracking
public final class ProgressTracker {
    private let total: Int
    private var current: Int = 0
    private let title: String

    public init(total: Int, title: String = "Progress") {
        self.total = total
        self.title = title
    }

    public func increment(_ message: String? = nil) {
        current += 1
        let percentage = (Double(current) / Double(total)) * 100
        let progress = String(format: "%.0f%%", percentage)

        if let message = message {
            Console.progress("[\(progress)] \(message)")
        } else {
            Console.progress("[\(progress)] \(current)/\(total)")
        }
    }

    public func complete() {
        Console.success("\(title) complete! (\(total) items)")
    }
}
