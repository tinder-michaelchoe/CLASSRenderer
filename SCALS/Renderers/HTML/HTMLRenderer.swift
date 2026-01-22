//
//  HTMLRenderer.swift
//  SCALS
//
//  Renders a RenderTree to HTML/CSS output.
//  Platform-agnostic - can be used for WebAssembly or WKWebView preview.
//

import Foundation

// MARK: - HTML Renderer

/// Renders a RenderTree to HTML string output with iOS-styled CSS.
///
/// Usage:
/// ```swift
/// let renderer = HTMLRenderer()
/// let output = renderer.render(renderTree)
///
/// // Use the full document in a WebView
/// webView.loadHTMLString(output.fullDocument, baseURL: nil)
///
/// // Or use parts separately
/// print(output.html)  // Just the body content
/// print(output.css)   // Generated CSS
/// ```
public struct HTMLRenderer: Renderer {
    public typealias Output = HTMLOutput
    
    private let cssGenerator: CSSGenerator
    private let nodeRenderer: HTMLNodeRenderer
    private let includeBaseStylesheet: Bool
    
    /// Creates a new HTML renderer.
    /// - Parameter includeBaseStylesheet: Whether to include the iOS base stylesheet (default: true)
    public init(includeBaseStylesheet: Bool = true) {
        self.cssGenerator = CSSGenerator()
        self.nodeRenderer = HTMLNodeRenderer()
        self.includeBaseStylesheet = includeBaseStylesheet
    }
    
    /// Renders a RenderTree to HTML output.
    /// - Parameter tree: The render tree to convert to HTML
    /// - Returns: HTMLOutput containing HTML, CSS, and full document
    public func render(_ tree: RenderTree) -> HTMLOutput {
        // Create mutable copies for rendering
        var nodeRenderer = self.nodeRenderer
        var cssGenerator = self.cssGenerator
        
        // Generate HTML body content
        let bodyContent = nodeRenderer.render(tree.root)
        
        // Generate CSS from styles
        var css = ""
        if includeBaseStylesheet {
            css += iOSDesignTokens.baseStylesheet + "\n\n"
        }
        css += cssGenerator.generate(from: tree)
        
        // Create full HTML document
        let fullDocument = wrapInDocument(html: bodyContent, css: css, tree: tree)
        
        return HTMLOutput(
            html: bodyContent,
            css: css,
            fullDocument: fullDocument
        )
    }
    
    // MARK: - Private Methods
    
    private func wrapInDocument(html: String, css: String, tree: RenderTree) -> String {
        let colorScheme = tree.root.colorScheme
        let colorSchemeClass = switch colorScheme {
        case .light: "light-mode"
        case .dark: "dark-mode"
        case .system: ""
        }
        
        let backgroundColor = tree.root.backgroundColor?.cssRGBA ?? "var(--ios-background)"
        
        return """
        <!DOCTYPE html>
        <html lang="en" class="\(colorSchemeClass)">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
            <meta name="color-scheme" content="light dark">
            <title>SCALS Rendered View</title>
            <style>
        \(css)
            </style>
        </head>
        <body style="background-color: \(backgroundColor);">
            <div class="scals-root">
        \(html)
            </div>
        </body>
        </html>
        """
    }
}

// MARK: - HTML Output

/// The output of HTML rendering containing separate parts and combined document.
public struct HTMLOutput {
    /// Just the body content (without <html>, <head>, etc.)
    public let html: String
    
    /// Generated CSS styles
    public let css: String
    
    /// Complete HTML document with DOCTYPE, head, styles, and body
    public let fullDocument: String
    
    public init(html: String, css: String, fullDocument: String) {
        self.html = html
        self.css = css
        self.fullDocument = fullDocument
    }
}
