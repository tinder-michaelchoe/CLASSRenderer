# CLADS Design System Integration Guide

This guide explains how to integrate external design systems with CLADS, enabling both style tokens and full native component rendering.

## Overview

CLADS supports design system integration through the `DesignSystemProvider` protocol. A design system provider can:

1. **Style Tokens** - Map design system style references to `IR.Style` values
2. **Full Components** - Render native SwiftUI components with full fidelity (animations, states, behaviors)

The `@` prefix convention distinguishes design system styles from local document styles:

```json
{
  "type": "button",
  "text": "Sign Up",
  "styleId": "@button.primary"  // Design system reference
}
```

vs.

```json
{
  "type": "button",
  "text": "Sign Up", 
  "styleId": "localButtonStyle"  // Local document style
}
```

## The @ Prefix Convention

- **`@` prefix** → Design system style (e.g., `@button.primary`, `@text.heading1`)
- **No prefix** → Local style from document's `styles` dictionary

The `StyleResolver` automatically detects the prefix and delegates to the appropriate source.

## Creating a DesignSystemProvider

### Protocol Definition

The design system integration is split into two protocols for platform-agnostic architecture:

**Platform-Agnostic Core Protocol** (`DesignSystemProvider`):

```swift
public protocol DesignSystemProvider {
    /// Unique identifier (e.g., "lightspeed", "obsidian")
    static var identifier: String { get }
    
    /// Resolve style reference to IR.Style tokens
    func resolveStyle(_ reference: String) -> IR.Style?
    
    /// Check if provider can render this node natively
    func canRender(_ node: RenderNode, styleId: String?) -> Bool
}
```

**SwiftUI-Specific Rendering Protocol** (`SwiftUIDesignSystemRenderer`):

```swift
public protocol SwiftUIDesignSystemRenderer: DesignSystemProvider {
    /// Render using native design system component
    @MainActor
    func render(_ node: RenderNode, styleId: String?, context: SwiftUIRenderContext) -> AnyView?
}
```

This separation allows:
- The core `DesignSystemProvider` to be used on any platform (including WebAssembly)
- SwiftUI-specific rendering to be added only when needed
- Future UIKit or HTML renderers to define their own rendering protocols

### Implementation Example

```swift
// Conform to SwiftUIDesignSystemRenderer for SwiftUI rendering support
public struct MyDesignSystemProvider: SwiftUIDesignSystemRenderer {
    public static let identifier = "myDesignSystem"
    
    public init() {}
    
    // MARK: - Style Token Resolution (Platform-Agnostic)
    
    public func resolveStyle(_ reference: String) -> IR.Style? {
        // Parse reference like "button.primary" or "text.heading1"
        let parts = reference.split(separator: ".").map(String.init)
        guard let category = parts.first else { return nil }
        
        switch category {
        case "button": return resolveButtonStyle(parts)
        case "text": return resolveTextStyle(parts)
        default: return nil
        }
    }
    
    private func resolveButtonStyle(_ parts: [String]) -> IR.Style? {
        guard parts.count >= 2 else { return nil }
        var style = IR.Style()
        
        switch parts[1] {
        case "primary":
            // Use IR.Color for platform-agnostic color representation
            style.backgroundColor = IR.Color(hex: "#6366F1")
            style.textColor = IR.Color(hex: "#FFFFFF")
            style.cornerRadius = 12
            style.paddingTop = 14
            style.paddingBottom = 14
        case "secondary":
            style.backgroundColor = IR.Color(hex: "#F3F4F6")
            style.textColor = IR.Color(hex: "#374151")
            style.cornerRadius = 12
        default:
            return nil
        }
        return style
    }
    
    // MARK: - Component Rendering Support (Platform-Agnostic)
    
    public func canRender(_ node: RenderNode, styleId: String?) -> Bool {
        guard let styleId, styleId.hasPrefix("@") else { return false }
        let ref = String(styleId.dropFirst())
        
        switch node {
        case .button: return ref.hasPrefix("button.")
        default: return false
        }
    }
    
    // MARK: - SwiftUI Rendering (SwiftUIDesignSystemRenderer)
    
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
    
    @MainActor
    private func renderButton(_ node: ButtonNode, ref: String, context: SwiftUIRenderContext) -> AnyView? {
        // Parse style variant from reference
        let parts = ref.split(separator: ".").map(String.init)
        guard parts.count >= 2, parts[0] == "button" else { return nil }
        
        let style: MyButton.Style = parts[1] == "primary" ? .primary : .secondary
        
        // Wrap native component with CLADS action handling
        return AnyView(
            MyButton(
                label: node.label,
                style: style,
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
```

## Creating Design System Components

Design system components should be **pure SwiftUI** with no CLADS dependency:

```swift
import SwiftUI

/// Pure design system button - no CLADS dependency
public struct MyButton: View {
    public enum Style { case primary, secondary }
    
    let label: String
    let style: Style
    let onTap: () -> Void
    
    // Handle dark mode internally
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    public var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(12)
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    // Dark mode adaptive colors
    private var backgroundColor: Color {
        switch (style, colorScheme) {
        case (.primary, .light): return Color(hex: "#6366F1")
        case (.primary, .dark):  return Color(hex: "#818CF8")
        case (.secondary, .light): return Color(hex: "#F3F4F6")
        case (.secondary, .dark):  return Color(hex: "#374151")
        @unknown default: return Color(hex: "#6366F1")
        }
    }
    
    private var foregroundColor: Color {
        switch (style, colorScheme) {
        case (.primary, _): return .white
        case (.secondary, .light): return Color(hex: "#374151")
        case (.secondary, .dark):  return Color(hex: "#F9FAFB")
        @unknown default: return .white
        }
    }
}
```

### Dark Mode Support

Components handle dark mode internally using `@Environment(\.colorScheme)`. This means:

- No renderer swapping needed
- Colors adapt automatically
- No changes required to CLADS core

## Injecting Your Provider

Pass your provider when creating `CladsRendererView`:

```swift
let provider = MyDesignSystemProvider()

CladsRendererView(
    document: document,
    actionRegistry: registry,
    componentRegistry: componentRegistry,
    swiftuiRendererRegistry: swiftuiRegistry,
    designSystemProvider: provider  // <-- Inject here
)
```

Or from JSON string:

```swift
CladsRendererView(
    jsonString: jsonString,
    actionRegistry: registry,
    componentRegistry: componentRegistry,
    swiftuiRendererRegistry: swiftuiRegistry,
    designSystemProvider: provider
)
```

## Fallback Behavior

CLADS uses a cascading fallback system:

1. **Provider + canRender() returns true** → Native component via `provider.render()`
2. **Provider + canRender() returns false** → Standard component + `IR.Style` from `provider.resolveStyle()`
3. **No provider or unknown style** → Standard component + inline/document styles only

This allows gradual adoption - start with style tokens, then add native components for high-value interactions.

## Best Practices

### 1. Keep Components Pure

Design system components should have no CLADS imports. This keeps them:
- Testable in isolation
- Reusable outside CLADS
- Easy to maintain

### 2. Use the Wrapper Pattern

CLADS wraps your components to inject action handling:

```swift
// Pure component (no CLADS)
MyButton(label: "Save", style: .primary, onTap: { ... })

// CLADS wraps it
MyButton(
    label: node.label,
    style: style,
    onTap: {
        // Execute CLADS action
        await context.actionContext.executeAction(id: actionId)
    }
)
```

### 3. Style Token Fallbacks

Always implement `resolveStyle()` for graceful degradation:
- Works on platforms without native component support
- Works in preview/testing environments
- Provides reasonable defaults

### 4. Dark Mode

Handle dark mode in components using `@Environment(\.colorScheme)`. Don't rely on the CLADS renderer to switch themes.

### 5. Testing

Write tests for:
- Style resolution (`resolveStyle()` returns expected `IR.Style`)
- Component selection (`canRender()` returns correct values)
- Action execution (native components trigger CLADS actions)

Example test:

```swift
@Test func resolveStyleReturnsCorrectTokens() {
    let provider = MyDesignSystemProvider()
    let style = provider.resolveStyle("button.primary")
    
    #expect(style?.cornerRadius == 12)
    #expect(style?.backgroundColor == Color(hex: "#6366F1"))
}

@Test func canRenderReturnsTrueForSupportedNodes() {
    let provider = MyDesignSystemProvider()
    let node = RenderNode.button(ButtonNode(label: "Test", styles: ButtonStyles()))
    
    #expect(provider.canRender(node, styleId: "@button.primary") == true)
    #expect(provider.canRender(node, styleId: "localStyle") == false)  // No @ prefix
}
```

## Directory Structure

Recommended structure for a design system implementation:

```
MyApp/
├── DesignSystems/
│   └── Lightspeed/
│       ├── LightspeedProvider.swift    # Combined DesignSystemProvider
│       └── Components/
│           ├── LightspeedButton.swift  # Pure SwiftUI, dark mode aware
│           ├── LightspeedText.swift
│           └── LightspeedTextField.swift
```

## Example JSON

```json
{
  "id": "design-system-demo",
  "designSystem": "lightspeed",
  "root": {
    "children": [
      {
        "type": "label",
        "text": "Welcome!",
        "styleId": "@text.heading1"
      },
      {
        "type": "button",
        "text": "Get Started",
        "styleId": "@button.primary",
        "actions": { "onTap": "navigateToOnboarding" }
      },
      {
        "type": "button",
        "text": "Learn More",
        "styleId": "@button.secondary",
        "actions": { "onTap": "showLearnMore" }
      }
    ]
  }
}
```

## Future Extensibility

Adding a new design system requires:

1. Create `NewDesignSystemProvider: DesignSystemProvider` (platform-agnostic)
2. Implement `resolveStyle(_:)` for fallback style tokens using `IR.Color`, `IR.FontWeight`, etc.
3. Implement `canRender(_:styleId:)` to indicate which nodes can be rendered natively
4. For SwiftUI: Conform to `SwiftUIDesignSystemRenderer` and implement `render(_:styleId:context:)`
5. Create pure SwiftUI components with dark mode support via `@Environment(\.colorScheme)`
6. Inject provider: `CladsRendererView(..., designSystemProvider: NewDesignSystemProvider())`

**No changes to CLADS core or JSON schema required.**

### Platform-Specific Rendering

For other platforms, define similar protocols:

```swift
// Future UIKit renderer protocol
public protocol UIKitDesignSystemRenderer: DesignSystemProvider {
    func render(_ node: RenderNode, styleId: String?, context: UIKitRenderContext) -> UIView?
}

// Future HTML/DOM renderer protocol (for WebAssembly)
public protocol HTMLDesignSystemRenderer: DesignSystemProvider {
    func render(_ node: RenderNode, styleId: String?, context: HTMLRenderContext) -> HTMLElement?
}
```

This architecture ensures the core `DesignSystemProvider` remains platform-agnostic while allowing platform-specific rendering extensions.
