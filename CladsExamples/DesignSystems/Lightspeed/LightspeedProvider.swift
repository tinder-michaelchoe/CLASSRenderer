//
//  LightspeedProvider.swift
//  CladsExamples
//
//  Combined DesignSystemProvider for the Lightspeed design system.
//  Provides both style token resolution and native component rendering.
//

import CLADS
import SwiftUI

/// Combined design system provider for Lightspeed.
///
/// Implements both style token resolution AND full component rendering.
/// Design system components handle dark mode internally.
///
/// Conforms to `SwiftUIDesignSystemRenderer` to provide native SwiftUI component rendering.
///
/// Usage:
/// ```swift
/// let provider = LightspeedProvider()
///
/// // Inject into CLADS view
/// CladsRendererView(
///     document: document,
///     actionRegistry: registry,
///     componentRegistry: componentRegistry,
///     swiftuiRendererRegistry: swiftuiRegistry,
///     designSystemProvider: provider
/// )
/// ```
public struct LightspeedProvider: SwiftUIDesignSystemRenderer {
    
    public static let identifier = "lightspeed"
    
    public init() {}
    
    // MARK: - Style Token Resolution (fallback)
    
    /// Resolves @-prefixed style references to IR.Style.
    /// Called when canRender() returns false or provider.render() returns nil.
    public func resolveStyle(_ reference: String) -> IR.Style? {
        print("🎨 LightspeedProvider.resolveStyle: '\(reference)'")
        let parts = reference.split(separator: ".").map(String.init)
        guard let category = parts.first else { 
            print("   ❌ No category found")
            return nil 
        }
        
        let result: IR.Style?
        switch category {
        case "button": result = resolveButtonStyle(parts)
        case "text": result = resolveTextStyle(parts)
        case "textField": result = resolveTextFieldStyle(parts)
        default: result = nil
        }
        
        if let style = result {
            print("   ✅ Resolved: fontFamily=\(style.fontFamily ?? "nil"), fontSize=\(style.fontSize ?? 0)")
        } else {
            print("   ❌ No style resolved")
        }
        return result
    }
    
    private func resolveButtonStyle(_ parts: [String]) -> IR.Style? {
        guard parts.count >= 2 else { return nil }
        var style = IR.Style()
        
        switch parts[1] {
        case "primary":
            style.backgroundColor = IR.Color(hex: "#6366F1")
            style.textColor = IR.Color(hex: "#FFFFFF")
            style.cornerRadius = 12
            style.paddingTop = 14
            style.paddingBottom = 14
            style.paddingLeading = 24
            style.paddingTrailing = 24
            
        case "secondary":
            style.backgroundColor = IR.Color(hex: "#F3F4F6")
            style.textColor = IR.Color(hex: "#374151")
            style.cornerRadius = 12
            style.borderWidth = 1
            style.borderColor = IR.Color(hex: "#D1D5DB")
            style.paddingTop = 14
            style.paddingBottom = 14
            style.paddingLeading = 24
            style.paddingTrailing = 24
            
        case "destructive":
            style.backgroundColor = IR.Color(hex: "#EF4444")
            style.textColor = IR.Color(hex: "#FFFFFF")
            style.cornerRadius = 12
            style.paddingTop = 14
            style.paddingBottom = 14
            style.paddingLeading = 24
            style.paddingTrailing = 24
            
        default:
            return nil
        }
        
        return style
    }
    
    private func resolveTextStyle(_ parts: [String]) -> IR.Style? {
        guard parts.count >= 2 else { return nil }
        var style = IR.Style()
        
        switch parts[1] {
        case "heading1":
            // Large display heading - Merriweather Bold
            style.fontFamily = "Merriweather120pt-Bold"
            style.fontSize = 32
            style.textColor = IR.Color(hex: "#111827")
            
        case "heading2":
            // Section heading - Merriweather SemiBold
            style.fontFamily = "Merriweather120pt-SemiBold"
            style.fontSize = 24
            style.textColor = IR.Color(hex: "#111827")
            
        case "heading3":
            // Subsection heading - Merriweather Medium
            style.fontFamily = "Merriweather120pt-Medium"
            style.fontSize = 20
            style.textColor = IR.Color(hex: "#1F2937")
            
        case "body":
            // Body text - Merriweather Regular
            style.fontFamily = "Merriweather120pt-Regular"
            style.fontSize = 16
            style.textColor = IR.Color(hex: "#374151")
            
        case "bodyItalic":
            // Emphasized body text - Merriweather Italic
            style.fontFamily = "Merriweather120pt-Italic"
            style.fontSize = 16
            style.textColor = IR.Color(hex: "#374151")
            
        case "caption":
            // Small labels - Merriweather Light
            style.fontFamily = "Merriweather120pt-Light"
            style.fontSize = 12
            style.textColor = IR.Color(hex: "#6B7280")
            
        case "quote":
            // Pull quotes - Merriweather Light Italic
            style.fontFamily = "Merriweather120pt-LightItalic"
            style.fontSize = 18
            style.textColor = IR.Color(hex: "#4B5563")
            
        case "label":
            // Form labels - Merriweather Medium
            style.fontFamily = "Merriweather120pt-Medium"
            style.fontSize = 14
            style.textColor = IR.Color(hex: "#374151")
            
        default:
            return nil
        }
        
        return style
    }
    
    private func resolveTextFieldStyle(_ parts: [String]) -> IR.Style? {
        var style = IR.Style()
        style.backgroundColor = IR.Color(hex: "#F9FAFB")
        style.cornerRadius = 8
        style.borderWidth = 1
        style.borderColor = IR.Color(hex: "#D1D5DB")
        style.fontSize = 16
        style.textColor = IR.Color(hex: "#111827")
        style.paddingTop = 12
        style.paddingBottom = 12
        style.paddingLeading = 16
        style.paddingTrailing = 16
        return style
    }
    
    // MARK: - Full Component Rendering
    
    /// Check if this provider can render the given node with native components.
    public func canRender(_ node: RenderNode, styleId: String?) -> Bool {
        guard let styleId, styleId.hasPrefix("@") else { return false }
        let ref = String(styleId.dropFirst())
        
        switch node {
        case .button:
            return ref.hasPrefix("button.")
        // Add more component types as implemented:
        // case .text: return ref.hasPrefix("text.")
        // case .textField: return ref.hasPrefix("textField.")
        default:
            return false
        }
    }
    
    /// Render a node using native Lightspeed components.
    @MainActor
    public func render(_ node: RenderNode, styleId: String?, context: SwiftUIRenderContext) -> AnyView? {
        guard let styleId, styleId.hasPrefix("@") else { return nil }
        let ref = String(styleId.dropFirst())
        
        switch node {
        case .button(let buttonNode):
            return renderButton(buttonNode, ref: ref, context: context)
        default:
            return nil
        }
    }
    
    // MARK: - Component Wrappers
    
    /// Wraps LightspeedButton with CLADS action handling.
    @MainActor
    private func renderButton(_ node: ButtonNode, ref: String, context: SwiftUIRenderContext) -> AnyView? {
        let parts = ref.split(separator: ".").map(String.init)
        guard parts.count >= 2, parts[0] == "button" else { return nil }
        
        let style: LightspeedButton.Style
        switch parts[1] {
        case "primary": style = .primary
        case "secondary": style = .secondary
        case "destructive": style = .destructive
        default: style = .primary
        }
        
        // Wrapper injects CLADS action handling into pure Lightspeed component
        return AnyView(
            LightspeedButton(
                label: node.label,
                style: style,
                isLoading: false,
                isDisabled: false,
                onTap: {
                    if let action = node.onTap {
                        Task { @MainActor in
                            switch action {
                            case .reference(let actionId):
                                await context.actionContext.executeAction(id: actionId)
                            case .inline(let actionDef):
                                await context.actionContext.executeAction(actionDef)
                            }
                        }
                    }
                }
            )
        )
    }
}
