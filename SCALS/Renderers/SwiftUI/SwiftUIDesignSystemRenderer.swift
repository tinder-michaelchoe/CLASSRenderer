//
//  SwiftUIDesignSystemRenderer.swift
//  ScalsRendererFramework
//
//  SwiftUI-specific protocol for design system component rendering.
//  This extends the platform-agnostic DesignSystemProvider with SwiftUI rendering capabilities.
//

import SwiftUI

// MARK: - SwiftUI Design System Renderer Protocol

/// SwiftUI-specific protocol for design system component rendering.
///
/// Extends `DesignSystemProvider` with SwiftUI-specific rendering capabilities.
/// Design system implementations that want to provide native SwiftUI components
/// should conform to this protocol.
///
/// Example implementation:
/// ```swift
/// struct LightspeedProvider: SwiftUIDesignSystemRenderer {
///     static let identifier = "lightspeed"
///
///     func resolveStyle(_ reference: String) -> IR.Style? {
///         // Map "button.primary" -> IR.Style with colors, padding, etc.
///     }
///
///     func canRender(_ node: RenderNode, styleId: String?) -> Bool {
///         guard let styleId, styleId.hasPrefix("@") else { return false }
///         return node.kind == .button && styleId.contains("button.")
///     }
///
///     func render(_ node: RenderNode, styleId: String?, context: SwiftUIRenderContext) -> AnyView? {
///         // Return native LightspeedButton wrapped with action handling
///     }
/// }
/// ```
public protocol SwiftUIDesignSystemRenderer: DesignSystemProvider {
    /// Render a node using native design system components.
    ///
    /// Called when `canRender` returns `true`. The returned view should:
    /// - Be a pure SwiftUI component (no SCALS dependency)
    /// - Handle dark mode internally using `@Environment(\.colorScheme)`
    /// - Wire up action handling via the provided context
    ///
    /// - Parameters:
    ///   - node: The render node to render
    ///   - styleId: The style ID for component variant selection
    ///   - context: SCALS render context with StateStore, ActionContext, etc.
    /// - Returns: SwiftUI view, or nil to fall back to default rendering
    @MainActor
    func render(_ node: RenderNode, styleId: String?, context: SwiftUIRenderContext) -> AnyView?
}

// MARK: - Default Implementation

public extension SwiftUIDesignSystemRenderer {
    /// Default: return nil (fall back to standard rendering)
    @MainActor
    func render(_ node: RenderNode, styleId: String?, context: SwiftUIRenderContext) -> AnyView? {
        return nil
    }
}

// MARK: - Backward Compatibility

/// For backward compatibility, `DesignSystemProvider` implementations that
/// also want to render SwiftUI components can still use the combined approach
/// by conforming to `SwiftUIDesignSystemRenderer`.
///
/// The renderer layer checks if the provider conforms to `SwiftUIDesignSystemRenderer`
/// and calls the `render` method appropriately.
