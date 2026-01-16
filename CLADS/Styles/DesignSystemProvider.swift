//
//  DesignSystemProvider.swift
//  CLADS
//
//  Protocol for design system integration.
//  Enables external design systems to provide style tokens.
//
//  **Important**: This file should remain platform-agnostic. SwiftUI-specific
//  rendering methods are defined in `Renderers/SwiftUI/SwiftUIDesignSystemRenderer.swift`.
//

import Foundation

// MARK: - Design System Style Provider Protocol (Platform-Agnostic)

/// Platform-agnostic protocol for design system style resolution.
///
/// A `DesignSystemProvider` resolves `@`-prefixed style references to `IR.Style` tokens.
/// This protocol is platform-agnostic and can be used across different renderers.
///
/// For SwiftUI-specific component rendering, see `SwiftUIDesignSystemRenderer` in the renderer layer.
///
/// Example implementation:
/// ```swift
/// struct LightspeedStyleProvider: DesignSystemProvider {
///     static let identifier = "lightspeed"
///
///     func resolveStyle(_ reference: String) -> IR.Style? {
///         // Map "button.primary" -> IR.Style with colors, padding, etc.
///     }
/// }
/// ```
public protocol DesignSystemProvider {
    /// Unique identifier for this design system (e.g., "lightspeed", "obsidian")
    static var identifier: String { get }

    // MARK: - Style Token Resolution

    /// Resolve a style reference to `IR.Style` for rendering.
    ///
    /// Called when a component has an `@`-prefixed styleId.
    ///
    /// - Parameter reference: Style path without "@" prefix (e.g., "button.primary")
    /// - Returns: Resolved `IR.Style` or nil if not found
    func resolveStyle(_ reference: String) -> IR.Style?
    
    // MARK: - Component Rendering Support (Platform-Agnostic)
    
    /// Check if this provider can render the given node with native components.
    ///
    /// Return `true` if a renderer-specific method (like `SwiftUIDesignSystemRenderer.render`)
    /// should be called for this node.
    /// Return `false` to fall back to standard CLADS rendering with style tokens.
    ///
    /// - Parameters:
    ///   - node: The render node to check
    ///   - styleId: The style ID (expected to have "@" prefix for design system references)
    /// - Returns: `true` if this provider has a native component for this node+style
    func canRender(_ node: RenderNode, styleId: String?) -> Bool
}

// MARK: - Default Implementations

public extension DesignSystemProvider {
    /// Default: can't render any nodes (fall back to style tokens only)
    func canRender(_ node: RenderNode, styleId: String?) -> Bool {
        return false
    }
}

// MARK: - RenderNode StyleId Extension

public extension RenderNode {
    /// The styleId for this render node, if applicable.
    ///
    /// Used by renderers to check for design system style references.
    var styleId: String? {
        switch self {
        case .button(let n): return n.styleId
        case .text(let n): return n.styleId
        case .image(let n): return n.styleId
        case .textField(let n): return n.styleId
        case .toggle(let n): return n.styleId
        case .slider(let n): return n.styleId
        case .container, .sectionLayout, .gradient, .spacer, .divider, .custom:
            return nil
        }
    }
}
