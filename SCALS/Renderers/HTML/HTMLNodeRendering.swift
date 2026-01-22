//
//  HTMLNodeRendering.swift
//  SCALS
//
//  Renders RenderNodes to HTML elements.
//  Converts the IR tree structure to semantic HTML with iOS-style classes.
//

import Foundation

// MARK: - HTML Node Renderer

/// Renders RenderNodes to HTML string output.
public struct HTMLNodeRenderer {
    private var containerCounter = 0
    private var textCounter = 0
    private var buttonCounter = 0
    private var imageCounter = 0
    private var textFieldCounter = 0
    private var toggleCounter = 0
    private var sliderCounter = 0
    private var gradientCounter = 0
    private var dividerCounter = 0
    private var sectionLayoutCounter = 0
    
    public init() {}
    
    /// Render a RootNode and all its children to HTML.
    /// - Parameter root: The root node to render
    /// - Returns: HTML string representing the entire tree
    public mutating func render(_ root: RootNode) -> String {
        var html = ""
        
        for child in root.children {
            html += renderNode(child)
        }
        
        return html
    }
    
    // MARK: - Node Rendering
    
    /// Render a single RenderNode to HTML.
    public mutating func renderNode(_ node: RenderNode) -> String {
        switch node {
        case .container(let container):
            return renderContainer(container)
            
        case .sectionLayout(let sectionLayout):
            return renderSectionLayout(sectionLayout)
            
        case .text(let text):
            return renderText(text)
            
        case .button(let button):
            return renderButton(button)
            
        case .textField(let textField):
            return renderTextField(textField)
            
        case .toggle(let toggle):
            return renderToggle(toggle)
            
        case .slider(let slider):
            return renderSlider(slider)
            
        case .image(let image):
            return renderImage(image)
            
        case .gradient(let gradient):
            return renderGradient(gradient)

        case .shape(let shape):
            return renderShape(shape)

        case .pageIndicator(let pageIndicator):
            return renderPageIndicator(pageIndicator)

        case .spacer:
            return renderSpacer()

        case .divider(let divider):
            return renderDivider(divider)

        case .custom(let kind, let customNode):
            return renderCustomNode(kind: kind, node: customNode)
        }
    }
    
    // MARK: - Container Rendering
    
    private mutating func renderContainer(_ container: ContainerNode) -> String {
        let className = containerClassName(for: container)
        let id = container.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        
        var childrenHTML = ""
        for child in container.children {
            childrenHTML += renderNode(child)
        }
        
        return """
        <div\(id) class="\(className)">
        \(childrenHTML.indented(by: 4))
        </div>
        """
    }
    
    private mutating func containerClassName(for container: ContainerNode) -> String {
        var classes = [container.layoutType.cssClass]
        
        // Always add a generated class name that matches CSSGenerator
        containerCounter += 1
        if let id = container.id {
            classes.append("scals-container-\(id.cssClassName)")
        } else {
            classes.append("scals-container-\(containerCounter)")
        }
        
        return classes.joined(separator: " ")
    }
    
    // MARK: - Section Layout Rendering
    
    private mutating func renderSectionLayout(_ sectionLayout: SectionLayoutNode) -> String {
        let id = sectionLayout.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = sectionLayout.id.map { "scals-section-layout-\($0.cssClassName)" } ?? "scals-section-layout"
        
        var sectionsHTML = ""
        for (index, section) in sectionLayout.sections.enumerated() {
            sectionsHTML += renderSection(section, index: index, parentClass: className)
        }
        
        return """
        <div\(id) class="\(className)" role="region">
        \(sectionsHTML.indented(by: 4))
        </div>
        """
    }
    
    private mutating func renderSection(_ section: IR.Section, index: Int, parentClass: String) -> String {
        let sectionClass = "\(parentClass)-section-\(index)"
        var sectionRole = "group"
        
        // Determine section type for ARIA
        switch section.layoutType {
        case .list:
            sectionRole = "list"
        case .grid:
            sectionRole = "grid"
        default:
            break
        }
        
        var html = ""
        
        // Header
        if let header = section.header {
            let stickyClass = section.stickyHeader ? " ios-section-header--sticky" : ""
            html += """
            <div class="ios-section-header\(stickyClass)">
            \(renderNode(header).indented(by: 4))
            </div>
            """
        }
        
        // Section content
        html += """
        <div class="\(sectionClass)" role="\(sectionRole)">
        """
        
        for child in section.children {
            let itemRole = sectionRole == "list" ? " role=\"listitem\"" : ""
            html += """
            <div class="ios-section-item"\(itemRole)>
            \(renderNode(child).indented(by: 4))
            </div>
            """
        }
        
        html += "</div>"
        
        // Footer
        if let footer = section.footer {
            html += """
            <div class="ios-section-footer">
            \(renderNode(footer).indented(by: 4))
            </div>
            """
        }
        
        return html
    }
    
    // MARK: - Text Rendering
    
    private mutating func renderText(_ text: TextNode) -> String {
        var classes = ["ios-text"]
        
        // Always add a generated class name that matches CSSGenerator
        textCounter += 1
        if let id = text.id {
            classes.append("scals-text-\(id.cssClassName)")
        } else {
            classes.append("scals-text-\(textCounter)")
        }
        
        // Add padding classes if needed
        if !text.padding.isEmpty {
            classes.append("has-padding")
        }
        
        let id = text.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")
        let content = text.content.htmlEscaped
        
        // Data attributes for dynamic content
        var dataAttrs = ""
        if let bindingPath = text.bindingPath {
            dataAttrs += " data-binding-path=\"\(bindingPath.htmlEscaped)\""
        }
        if let bindingTemplate = text.bindingTemplate {
            dataAttrs += " data-binding-template=\"\(bindingTemplate.htmlEscaped)\""
        }
        
        return "<span\(id) class=\"\(className)\"\(dataAttrs)>\(content)</span>"
    }
    
    // MARK: - Button Rendering
    
    private mutating func renderButton(_ button: ButtonNode) -> String {
        var classes = ["ios-button"]
        
        // Always add a generated class name that matches CSSGenerator
        buttonCounter += 1
        if let id = button.id {
            classes.append("scals-button-\(id.cssClassName)")
        } else {
            classes.append("scals-button-\(buttonCounter)")
        }
        
        if button.fillWidth {
            classes.append("ios-button--full-width")
        }
        
        let id = button.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")
        let label = button.label.htmlEscaped
        
        // Data attributes for actions and state binding
        var dataAttrs = ""
        if let isSelectedBinding = button.isSelectedBinding {
            dataAttrs += " data-selected-binding=\"\(isSelectedBinding.htmlEscaped)\""
        }
        if button.onTap != nil {
            dataAttrs += " data-has-action=\"true\""
        }
        
        // Inline style for custom button color
        var inlineStyle = ""
        if let bg = button.style.backgroundColor {
            inlineStyle = " style=\"background-color: \(bg.cssRGBA)\""
        } else if let fg = button.style.textColor {
            // Secondary button style (transparent bg, colored text)
            inlineStyle = " style=\"background-color: transparent; color: \(fg.cssRGBA)\""
        }
        
        return """
        <button\(id) class="\(className)" type="button"\(dataAttrs)\(inlineStyle)>
            <span class="ios-button-label">\(label)</span>
        </button>
        """
    }
    
    // MARK: - TextField Rendering
    
    private func renderTextField(_ textField: TextFieldNode) -> String {
        var classes = ["ios-textfield"]
        
        if let id = textField.id {
            classes.append("scals-textfield-\(id.cssClassName)")
        }
        
        let id = textField.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")
        let placeholder = textField.placeholder.htmlEscaped
        
        var dataAttrs = ""
        if let bindingPath = textField.bindingPath {
            dataAttrs = " data-binding-path=\"\(bindingPath.htmlEscaped)\""
        }
        
        return """
        <input\(id) class="\(className)" type="text" placeholder="\(placeholder)"\(dataAttrs)>
        """
    }
    
    // MARK: - Toggle Rendering
    
    private func renderToggle(_ toggle: ToggleNode) -> String {
        var classes = ["ios-toggle"]
        
        if let id = toggle.id {
            classes.append("scals-toggle-\(id.cssClassName)")
        }
        
        let id = toggle.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")
        
        var dataAttrs = ""
        if let bindingPath = toggle.bindingPath {
            dataAttrs = " data-binding-path=\"\(bindingPath.htmlEscaped)\""
        }
        
        return """
        <input\(id) class="\(className)" type="checkbox" role="switch"\(dataAttrs)>
        """
    }
    
    // MARK: - Slider Rendering
    
    private func renderSlider(_ slider: SliderNode) -> String {
        var classes = ["ios-slider"]
        
        if let id = slider.id {
            classes.append("scals-slider-\(id.cssClassName)")
        }
        
        let id = slider.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")
        
        var dataAttrs = ""
        if let bindingPath = slider.bindingPath {
            dataAttrs = " data-binding-path=\"\(bindingPath.htmlEscaped)\""
        }
        
        return """
        <input\(id) class="\(className)" type="range" min="\(slider.minValue)" max="\(slider.maxValue)" step="0.01"\(dataAttrs)>
        """
    }
    
    // MARK: - Image Rendering
    
    private mutating func renderImage(_ image: ImageNode) -> String {
        var classes = ["ios-image"]
        
        if let id = image.id {
            classes.append("scals-image-\(id.cssClassName)")
        }
        
        let id = image.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")
        
        let (tag, attributes) = image.source.htmlAttributes
        
        var attrsString = attributes.map { key, value in
            "\(key)=\"\(value.htmlEscaped)\""
        }.joined(separator: " ")
        
        // Add common attributes
        if !attrsString.contains("class=") {
            attrsString += " class=\"\(className)\""
        } else {
            // Merge classes
            attrsString = attrsString.replacingOccurrences(
                of: "class=\"ios-image\"",
                with: "class=\"\(className)\""
            )
        }
        
        // Inline styles from IR.Style
        var inlineStyles: [String] = []
        if let width = image.style.width {
            inlineStyles.append("width: \(Int(width))px")
        }
        if let height = image.style.height {
            inlineStyles.append("height: \(Int(height))px")
        }
        if let radius = image.style.cornerRadius {
            inlineStyles.append("border-radius: \(Int(radius))px")
        }
        if let tint = image.style.tintColor {
            // For SF Symbols / icons
            inlineStyles.append("color: \(tint.cssRGBA)")
        }
        
        if !inlineStyles.isEmpty {
            attrsString += " style=\"\(inlineStyles.joined(separator: "; "))\""
        }
        
        // Action data attribute
        if image.onTap != nil {
            attrsString += " data-has-action=\"true\" role=\"button\" tabindex=\"0\""
        }
        
        if tag == "img" {
            return "<\(tag)\(id) \(attrsString)>"
        } else {
            // For SF Symbol spans, we need a closing tag
            let symbolName = attributes["data-symbol"] ?? ""
            return "<\(tag)\(id) \(attrsString)>\(renderSFSymbolPlaceholder(symbolName))</\(tag)>"
        }
    }
    
    /// Render a placeholder for SF Symbols (since web doesn't have native SF Symbols)
    private func renderSFSymbolPlaceholder(_ name: String) -> String {
        // Map common SF Symbols to unicode or emoji equivalents
        // In production, you'd use a proper icon font or SVG icons
        let symbolMap: [String: String] = [
            "star.fill": "★",
            "star": "☆",
            "heart.fill": "♥",
            "heart": "♡",
            "checkmark": "✓",
            "xmark": "✕",
            "plus": "+",
            "minus": "−",
            "arrow.right": "→",
            "arrow.left": "←",
            "arrow.up": "↑",
            "arrow.down": "↓",
            "chevron.right": "›",
            "chevron.left": "‹",
            "chevron.up": "ˆ",
            "chevron.down": "ˇ",
            "magnifyingglass": "🔍",
            "gear": "⚙",
            "person": "👤",
            "person.fill": "👤",
            "house": "🏠",
            "house.fill": "🏠",
            "bell": "🔔",
            "bell.fill": "🔔",
            "envelope": "✉",
            "envelope.fill": "✉",
            "photo": "🖼",
            "photo.fill": "🖼",
            "trash": "🗑",
            "trash.fill": "🗑",
            "folder": "📁",
            "folder.fill": "📁",
            "doc": "📄",
            "doc.fill": "📄",
        ]
        
        return symbolMap[name] ?? "●"
    }
    
    // MARK: - Gradient Rendering
    
    private func renderGradient(_ gradient: GradientNode) -> String {
        var classes = ["ios-gradient"]
        
        if let id = gradient.id {
            classes.append("scals-gradient-\(id.cssClassName)")
        }
        
        let id = gradient.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")
        
        // Inline gradient style
        let gradientCSS = gradient.cssGradient
        var inlineStyle = "background: \(gradientCSS)"
        
        // Add sizing from style
        if let width = gradient.style.width {
            inlineStyle += "; width: \(Int(width))px"
        }
        if let height = gradient.style.height {
            inlineStyle += "; height: \(Int(height))px"
        }
        
        return "<div\(id) class=\"\(className)\" style=\"\(inlineStyle)\"></div>"
    }

    // MARK: - Shape Rendering

    private func renderShape(_ shape: ShapeNode) -> String {
        var classes = ["ios-shape"]

        // Add CSS class for styling
        if let id = shape.id {
            classes.append("scals-shape-\(id.cssClassName)")
        }

        let id = shape.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")

        // Build inline style
        var inlineStyles: [String] = []

        // Background color
        if let bgColor = shape.style.backgroundColor {
            inlineStyles.append("background-color: \(bgColor.cssRGBA)")
        }

        // Border
        if let borderColor = shape.style.borderColor, let borderWidth = shape.style.borderWidth {
            inlineStyles.append("border: \(Int(borderWidth))px solid \(borderColor.cssRGBA)")
        }

        // Border radius (for roundedRectangle, capsule, circle)
        switch shape.shapeType {
        case .roundedRectangle(let radius):
            inlineStyles.append("border-radius: \(Int(radius))px")
        case .circle, .capsule:
            inlineStyles.append("border-radius: 50%")
        case .rectangle, .ellipse:
            break
        }

        // Dimensions
        if let width = shape.style.width {
            inlineStyles.append("width: \(Int(width))px")
        }
        if let height = shape.style.height {
            inlineStyles.append("height: \(Int(height))px")
        }

        let inlineStyle = inlineStyles.isEmpty ? "" : " style=\"\(inlineStyles.joined(separator: "; "))\""

        return "<div\(id) class=\"\(className)\"\(inlineStyle)></div>"
    }

    // MARK: - Page Indicator Rendering

    private func renderPageIndicator(_ pageIndicator: PageIndicatorNode) -> String {
        var classes = ["ios-page-indicator"]

        if let id = pageIndicator.id {
            classes.append("scals-page-indicator-\(id.cssClassName)")
        }

        let id = pageIndicator.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")

        // Build container inline style
        var containerStyles: [String] = []

        // Padding
        if let paddingTop = pageIndicator.style.paddingTop {
            containerStyles.append("padding-top: \(Int(paddingTop))px")
        }
        if let paddingBottom = pageIndicator.style.paddingBottom {
            containerStyles.append("padding-bottom: \(Int(paddingBottom))px")
        }
        if let paddingLeading = pageIndicator.style.paddingLeading {
            containerStyles.append("padding-left: \(Int(paddingLeading))px")
        }
        if let paddingTrailing = pageIndicator.style.paddingTrailing {
            containerStyles.append("padding-right: \(Int(paddingTrailing))px")
        }

        containerStyles.append("display: flex")
        containerStyles.append("gap: \(Int(pageIndicator.dotSpacing))px")
        containerStyles.append("align-items: center")
        containerStyles.append("justify-content: center")

        let containerStyle = " style=\"\(containerStyles.joined(separator: "; "))\""

        // Note: Actual page count and current page would need to be resolved from state
        // For HTML rendering, we'll render placeholder dots
        let pageCount = pageIndicator.pageCountStatic ?? 5
        let dotSize = Int(pageIndicator.dotSize)
        let inactiveDotColor = pageIndicator.dotColor.cssRGBA
        let activeDotColor = pageIndicator.currentDotColor.cssRGBA

        var dotsHTML = ""
        for index in 0..<pageCount {
            let dotColor = index == 0 ? activeDotColor : inactiveDotColor // Default to first page active
            let dotStyle = "width: \(dotSize)px; height: \(dotSize)px; border-radius: 50%; background-color: \(dotColor);"
            dotsHTML += "<div class=\"ios-page-dot\" style=\"\(dotStyle)\"></div>"
        }

        return "<div\(id) class=\"\(className)\"\(containerStyle)>\(dotsHTML)</div>"
    }

    // MARK: - Spacer Rendering

    private func renderSpacer() -> String {
        return "<div class=\"ios-spacer\" aria-hidden=\"true\"></div>"
    }
    
    // MARK: - Divider Rendering
    
    private func renderDivider(_ divider: DividerNode) -> String {
        var classes = ["ios-divider"]
        
        if let id = divider.id {
            classes.append("scals-divider-\(id.cssClassName)")
        }
        
        let id = divider.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        let className = classes.joined(separator: " ")
        
        return "<hr\(id) class=\"\(className)\" role=\"separator\">"
    }
    
    // MARK: - Custom Node Rendering
    
    private mutating func renderCustomNode(kind: RenderNodeKind, node: any CustomRenderNode) -> String {
        // Check if the custom node implements HTMLRendering
        if let htmlRendering = node as? HTMLRendering {
            return htmlRendering.renderHTML()
        }
        
        // Fallback: render as a placeholder div
        return """
        <div class="scals-custom scals-custom-\(kind.rawValue.cssClassName)" data-node-kind="\(kind.rawValue.htmlEscaped)">
            <!-- Custom component: \(kind.rawValue) -->
        </div>
        """
    }
}

// MARK: - HTML Rendering Protocol

/// Protocol for custom nodes that can render themselves to HTML.
public protocol HTMLRendering {
    /// Render this node to HTML.
    func renderHTML() -> String
}

// MARK: - String Helpers

extension String {
    /// Indent each line by the specified number of spaces.
    func indented(by spaces: Int) -> String {
        let indent = String(repeating: " ", count: spaces)
        return self.split(separator: "\n", omittingEmptySubsequences: false)
            .map { indent + $0 }
            .joined(separator: "\n")
    }
}
