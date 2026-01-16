//
//  DesignSystemProviderTests.swift
//  CLADSTests
//
//  Tests for the DesignSystemProvider protocol and integration.
//

import Testing
import SwiftUI
@testable import CLADS

// MARK: - Mock Design System Provider

/// A minimal mock provider for testing (platform-agnostic)
struct MockDesignSystemProvider: DesignSystemProvider {
    static let identifier = "mock"
    
    var styleMapping: [String: IR.Style] = [:]
    var canRenderCallback: ((RenderNode, String?) -> Bool)?
    
    func resolveStyle(_ reference: String) -> IR.Style? {
        return styleMapping[reference]
    }
    
    func canRender(_ node: RenderNode, styleId: String?) -> Bool {
        return canRenderCallback?(node, styleId) ?? false
    }
}

/// A mock provider that also supports SwiftUI rendering
struct MockSwiftUIDesignSystemRenderer: SwiftUIDesignSystemRenderer {
    static let identifier = "mockSwiftUI"
    
    var styleMapping: [String: IR.Style] = [:]
    var canRenderCallback: ((RenderNode, String?) -> Bool)?
    var renderCallback: ((RenderNode, String?, SwiftUIRenderContext) -> AnyView?)?
    
    func resolveStyle(_ reference: String) -> IR.Style? {
        return styleMapping[reference]
    }
    
    func canRender(_ node: RenderNode, styleId: String?) -> Bool {
        return canRenderCallback?(node, styleId) ?? false
    }
    
    @MainActor
    func render(_ node: RenderNode, styleId: String?, context: SwiftUIRenderContext) -> AnyView? {
        return renderCallback?(node, styleId, context)
    }
}

// MARK: - Style Resolution Tests

@Suite struct StyleResolverDesignSystemTests {
    
    @Test func resolveAtPrefixedStyleDelegatestoProvider() {
        // Given
        var mockProvider = MockDesignSystemProvider()
        var expectedStyle = IR.Style()
        expectedStyle.cornerRadius = 12
        expectedStyle.backgroundColor = IR.Color(hex: "#6366F1")
        mockProvider.styleMapping["button.primary"] = expectedStyle
        
        let resolver = StyleResolver(styles: nil, designSystemProvider: mockProvider)
        
        // When
        let resolved = resolver.resolve("@button.primary")
        
        // Then
        #expect(resolved.cornerRadius == 12)
        #expect(resolved.backgroundColor == IR.Color(hex: "#6366F1"))
    }
    
    @Test func resolveAtPrefixedStyleReturnsEmptyWhenNotFound() {
        // Given
        let mockProvider = MockDesignSystemProvider()
        let resolver = StyleResolver(styles: nil, designSystemProvider: mockProvider)
        
        // When
        let resolved = resolver.resolve("@unknown.style")
        
        // Then - should return empty style, not crash
        #expect(resolved.cornerRadius == nil)
        #expect(resolved.backgroundColor == nil)
    }
    
    @Test func resolveLocalStyleIgnoresProvider() {
        // Given
        var mockProvider = MockDesignSystemProvider()
        var dsStyle = IR.Style()
        dsStyle.cornerRadius = 999  // Should NOT be used
        mockProvider.styleMapping["localStyle"] = dsStyle
        
        let localStyles: [String: Document.Style] = [
            "localStyle": Document.Style(cornerRadius: 8)
        ]
        let resolver = StyleResolver(styles: localStyles, designSystemProvider: mockProvider)
        
        // When
        let resolved = resolver.resolve("localStyle")  // No @ prefix
        
        // Then - should use local style, not design system
        #expect(resolved.cornerRadius == 8)
    }
    
    @Test func resolveWithInlineOverride() {
        // Given
        var mockProvider = MockDesignSystemProvider()
        var dsStyle = IR.Style()
        dsStyle.cornerRadius = 12
        dsStyle.backgroundColor = IR.Color(hex: "#6366F1")
        mockProvider.styleMapping["button.primary"] = dsStyle
        
        let resolver = StyleResolver(styles: nil, designSystemProvider: mockProvider)
        
        // When - resolve with inline override
        let inline = Document.Style(backgroundColor: "#FF0000")
        let resolved = resolver.resolve("@button.primary", inline: inline)
        
        // Then - inline wins for backgroundColor, DS style kept for cornerRadius
        #expect(resolved.cornerRadius == 12)
        #expect(resolved.backgroundColor == IR.Color(hex: "#FF0000"))
    }
    
    @Test func resolveWithNoProvider() {
        // Given - no provider
        let resolver = StyleResolver(styles: nil, designSystemProvider: nil)
        
        // When
        let resolved = resolver.resolve("@button.primary")
        
        // Then - should return empty style, not crash
        #expect(resolved.cornerRadius == nil)
        #expect(resolved.backgroundColor == nil)
    }
}

// MARK: - RenderNode StyleId Extension Tests

@Suite struct RenderNodeStyleIdTests {
    
    @Test func buttonNodeStyleId() {
        let node = RenderNode.button(ButtonNode(
            label: "Test",
            styleId: "@button.primary",
            styles: ButtonStyles()
        ))
        
        #expect(node.styleId == "@button.primary")
    }
    
    @Test func textNodeStyleId() {
        let node = RenderNode.text(TextNode(
            content: "Test",
            styleId: "@text.heading1"
        ))
        
        #expect(node.styleId == "@text.heading1")
    }
    
    @Test func textFieldNodeStyleId() {
        let node = RenderNode.textField(TextFieldNode(
            placeholder: "Enter text",
            styleId: "@textField.default"
        ))
        
        #expect(node.styleId == "@textField.default")
    }
    
    @Test func imageNodeStyleId() {
        let node = RenderNode.image(ImageNode(
            source: .sfsymbol(name: "star"),
            styleId: "@icon.default"
        ))
        
        #expect(node.styleId == "@icon.default")
    }
    
    @Test func containerNodeHasNilStyleId() {
        let node = RenderNode.container(ContainerNode())
        
        #expect(node.styleId == nil)
    }
    
    @Test func spacerHasNilStyleId() {
        let node = RenderNode.spacer
        
        #expect(node.styleId == nil)
    }
}

// MARK: - DesignSystemProvider Default Implementation Tests

@Suite struct DesignSystemProviderDefaultTests {
    
    /// Provider that only implements resolveStyle (uses defaults for canRender)
    struct TokenOnlyProvider: DesignSystemProvider {
        static let identifier = "tokenOnly"
        
        func resolveStyle(_ reference: String) -> IR.Style? {
            if reference == "test" {
                var style = IR.Style()
                style.cornerRadius = 42
                return style
            }
            return nil
        }
    }
    
    /// Provider that conforms to SwiftUIDesignSystemRenderer (uses defaults for render)
    struct SwiftUITokenOnlyProvider: SwiftUIDesignSystemRenderer {
        static let identifier = "swiftUITokenOnly"
        
        func resolveStyle(_ reference: String) -> IR.Style? {
            if reference == "test" {
                var style = IR.Style()
                style.cornerRadius = 42
                return style
            }
            return nil
        }
    }
    
    @Test func defaultCanRenderReturnsFalse() {
        let provider = TokenOnlyProvider()
        let node = RenderNode.button(ButtonNode(label: "Test", styles: ButtonStyles()))
        
        // Default implementation should return false
        #expect(provider.canRender(node, styleId: "@button.primary") == false)
    }
    
    @Test @MainActor func defaultRenderReturnsNil() {
        let provider = SwiftUITokenOnlyProvider()
        let node = RenderNode.button(ButtonNode(label: "Test", styles: ButtonStyles()))
        
        let stateStore = StateStore()
        let actionContext = ActionContext(
            stateStore: stateStore,
            actionDefinitions: [:],
            registry: ActionRegistry()
        )
        
        let tree = RenderTree(
            root: RootNode(),
            stateStore: stateStore,
            actions: [:]
        )
        
        let context = SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: SwiftUINodeRendererRegistry()
        )
        
        // Default implementation should return nil
        #expect(provider.render(node, styleId: "@button.primary", context: context) == nil)
    }
    
    @Test func tokenOnlyProviderResolvesStyle() {
        let provider = TokenOnlyProvider()
        
        let style = provider.resolveStyle("test")
        #expect(style?.cornerRadius == 42)
        
        let unknown = provider.resolveStyle("unknown")
        #expect(unknown == nil)
    }
}
