# HTMLRenderer

Render SCALS documents to HTML/CSS with iOS-style appearance.

## Overview

The HTML renderer converts a `RenderTree` to HTML and CSS that visually matches the native iOS SwiftUI renderer. It uses iOS design tokens derived from Apple's Human Interface Guidelines to ensure consistent styling across platforms.

### Key Features

- **iOS-Fidelity Styling**: CSS generated from Apple HIG design tokens
- **Dark Mode Support**: Automatic dark mode via CSS `prefers-color-scheme`
- **Semantic HTML**: Accessible HTML structure with ARIA roles
- **Complete Documents**: Generates full HTML documents ready for `WKWebView`

## Basic Usage

```swift
import SCALS

// Parse JSON and resolve to RenderTree
let definition = try Document.Definition(jsonString: jsonText)
let resolver = Resolver(
    document: definition,
    componentRegistry: ComponentResolverRegistry.default
)
let renderTree = try resolver.resolve()

// Generate HTML
let htmlRenderer = HTMLRenderer()
let output = htmlRenderer.render(renderTree)

// Use in WKWebView
webView.loadHTMLString(output.fullDocument, baseURL: nil)
```

## Output Structure

The ``HTMLOutput`` struct provides three representations:

| Property | Description |
|----------|-------------|
| `html` | Just the body content (without `<html>`, `<head>`, etc.) |
| `css` | Generated CSS styles including iOS base styles |
| `fullDocument` | Complete HTML document ready to render |

## Customization

### Disable Base Stylesheet

If you want to provide your own CSS, you can disable the iOS base stylesheet:

```swift
let renderer = HTMLRenderer(includeBaseStylesheet: false)
```

### Custom Node Rendering

Custom components can implement the ``HTMLRendering`` protocol:

```swift
struct MyCustomNode: CustomRenderNode, HTMLRendering {
    static var kind = RenderNodeKind(rawValue: "myCustom")
    
    func renderHTML() -> String {
        return "<div class=\"my-custom\">Custom content</div>"
    }
}
```

### Custom CSS Generation

Custom components can implement the ``CSSGenerating`` protocol:

```swift
struct MyCustomNode: CustomRenderNode, CSSGenerating {
    static var kind = RenderNodeKind(rawValue: "myCustom")
    
    func generateCSS() -> String {
        return ".my-custom { color: blue; }"
    }
}
```

## iOS Design Tokens

The renderer includes comprehensive iOS design tokens in ``iOSDesignTokens``:

### Typography

| Style | Size | Weight |
|-------|------|--------|
| Large Title | 34px | 700 |
| Title 1 | 28px | 700 |
| Title 2 | 22px | 700 |
| Title 3 | 20px | 600 |
| Headline | 17px | 600 |
| Body | 17px | 400 |
| Callout | 16px | 400 |
| Subheadline | 15px | 400 |
| Footnote | 13px | 400 |
| Caption 1 | 12px | 400 |
| Caption 2 | 11px | 400 |

### System Colors

The renderer uses iOS system colors as CSS custom properties:

- `--ios-blue`: #007AFF
- `--ios-green`: #34C759
- `--ios-red`: #FF3B30
- `--ios-orange`: #FF9500
- `--ios-purple`: #AF52DE

### Semantic Colors

Light and dark mode adaptive colors:

- `--ios-label`: Primary text color
- `--ios-secondary-label`: Secondary text color
- `--ios-background`: Primary background
- `--ios-separator`: Divider/separator color

## Topics

### Essentials

- ``HTMLRenderer``
- ``HTMLOutput``

### Design Tokens

- ``iOSDesignTokens``
- ``CSSFont``

### Node Rendering

- ``HTMLNodeRenderer``
- ``HTMLRendering``

### CSS Generation

- ``CSSGenerator``
- ``CSSGenerating``

### IR Conversions

- ``IR/Color/cssRGBA``
- ``IR/Style/cssRules()``
