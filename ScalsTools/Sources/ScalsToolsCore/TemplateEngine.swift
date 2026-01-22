//
//  TemplateEngine.swift
//  ScalsToolsCore
//
//  Template engine for code generation
//

import Foundation
import Stencil

/// Template engine for generating code from templates
public final class TemplateEngine {
    private let environment: Environment

    public init() {
        // Create environment with custom filters
        let ext = Extension()

        // Register custom filters
        ext.registerFilter("snakeCase") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.snakeCase
        }

        ext.registerFilter("pascalCase") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.pascalCase
        }

        ext.registerFilter("camelCase") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.camelCase
        }

        ext.registerFilter("indent") { (value: Any?, arguments: [Any?]) in
            guard let string = value as? String else { return value }
            let spaces = arguments.first as? Int ?? 4
            return string.indented(by: spaces)
        }

        self.environment = Environment(extensions: [ext])
    }

    public func render(template: String, context: [String: Any]) throws -> String {
        try environment.renderTemplate(string: template, context: context)
    }

    public func renderFile(at url: URL, context: [String: Any]) throws -> String {
        let template = try String(contentsOf: url, encoding: .utf8)
        return try render(template: template, context: context)
    }
}

/// Template provider for built-in templates
public enum Templates {
    // We'll add template strings here for each tool
}
