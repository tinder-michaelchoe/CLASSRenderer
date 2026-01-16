//
//  StyleResolver.swift
//  CladsRendererFramework
//
//  **Important**: This file should remain platform-agnostic. Do NOT import
//  SwiftUI or UIKit here. Platform-specific conversions belong in the
//  renderer layer (see `Renderers/SwiftUI/IRTypeConversions.swift`).
//

import Foundation

/// Resolves styles with single-parent inheritance support and optional design system integration.
///
/// Style IDs can be:
/// - Local references (e.g., "primaryButton") - looked up in document's styles dictionary
/// - Design system references (e.g., "@button.primary") - delegated to DesignSystemProvider
///
/// Design system styles use the `@` prefix convention to distinguish them from local styles.
public struct StyleResolver {
    private let styles: [String: Document.Style]
    private let designSystemProvider: (any DesignSystemProvider)?

    public init(
        styles: [String: Document.Style]?,
        designSystemProvider: (any DesignSystemProvider)? = nil
    ) {
        self.styles = styles ?? [:]
        self.designSystemProvider = designSystemProvider
    }

    /// Resolve a style by ID, following the inheritance chain.
    ///
    /// For `@`-prefixed styleIds, delegates to the design system provider.
    /// For local styleIds, looks up in the document's styles dictionary.
    ///
    /// - Parameter styleId: Style identifier (may have `@` prefix for design system)
    /// - Returns: Resolved IR.Style
    public func resolve(_ styleId: String?) -> IR.Style {
        guard let styleId = styleId else {
            return IR.Style()
        }

        // Check for design system reference (@-prefixed)
        if styleId.hasPrefix("@") {
            let reference = String(styleId.dropFirst())
            if let dsStyle = designSystemProvider?.resolveStyle(reference) {
                return dsStyle
            }
            // Design system style not found, return empty style
            return IR.Style()
        }

        // Local document style
        guard let style = styles[styleId] else {
            return IR.Style()
        }
        return resolve(style: style, visited: [])
    }

    /// Resolve a style by ID with inline style overrides.
    ///
    /// Inline styles always take precedence over resolved styles.
    ///
    /// - Parameters:
    ///   - styleId: Style identifier (may have `@` prefix for design system)
    ///   - inline: Inline style overrides
    /// - Returns: Resolved IR.Style with inline overrides merged
    public func resolve(_ styleId: String?, inline: Document.Style?) -> IR.Style {
        var resolved = resolve(styleId)

        // Merge inline overrides (inline wins)
        if let inline = inline {
            resolved.merge(from: inline)
        }

        return resolved
    }

    private func resolve(style: Document.Style, visited: Set<String>) -> IR.Style {
        // Start with parent style if inheriting
        var resolved: IR.Style
        if let parentId = style.inherits,
           !visited.contains(parentId),
           let parentStyle = styles[parentId] {
            var newVisited = visited
            newVisited.insert(parentId)
            resolved = resolve(style: parentStyle, visited: newVisited)
        } else {
            resolved = IR.Style()
        }

        // Override with current style values
        resolved.merge(from: style)
        return resolved
    }
}
