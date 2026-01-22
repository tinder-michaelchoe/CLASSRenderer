//
//  HTMLIRTypeConversions.swift
//  SCALS
//
//  Extensions to convert IR types to CSS values.
//  This file bridges the platform-agnostic IR layer with HTML/CSS rendering.
//

import Foundation

// MARK: - IR.Color → CSS

extension IR.Color {
    /// Convert to CSS RGBA color string
    public var cssRGBA: String {
        if alpha == 1.0 {
            // Use hex for fully opaque colors
            let r = Int(red * 255)
            let g = Int(green * 255)
            let b = Int(blue * 255)
            return String(format: "#%02X%02X%02X", r, g, b)
        } else {
            return "rgba(\(Int(red * 255)), \(Int(green * 255)), \(Int(blue * 255)), \(String(format: "%.2f", alpha)))"
        }
    }
    
    /// Convert to CSS hex color string (ignores alpha)
    public var cssHex: String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - IR.EdgeInsets → CSS

extension IR.EdgeInsets {
    /// Convert to CSS padding/margin shorthand
    public var cssPadding: String {
        "\(Int(top))px \(Int(trailing))px \(Int(bottom))px \(Int(leading))px"
    }
    
    /// Convert to individual CSS properties
    public var cssProperties: [String: String] {
        var props: [String: String] = [:]
        if top != 0 { props["padding-top"] = "\(Int(top))px" }
        if bottom != 0 { props["padding-bottom"] = "\(Int(bottom))px" }
        if leading != 0 { props["padding-left"] = "\(Int(leading))px" }
        if trailing != 0 { props["padding-right"] = "\(Int(trailing))px" }
        return props
    }
}

// MARK: - IR.Alignment → CSS

extension IR.Alignment {
    /// Convert to CSS flexbox align-items and justify-content
    public var cssFlexAlignment: (alignItems: String, justifyContent: String) {
        let align: String
        switch vertical {
        case .top: align = "flex-start"
        case .center: align = "center"
        case .bottom: align = "flex-end"
        }
        
        let justify: String
        switch horizontal {
        case .leading: justify = "flex-start"
        case .center: justify = "center"
        case .trailing: justify = "flex-end"
        }
        
        return (align, justify)
    }
    
    /// CSS text-align value for horizontal alignment
    public var cssTextAlign: String {
        switch horizontal {
        case .leading: return "left"
        case .center: return "center"
        case .trailing: return "right"
        }
    }
}

// MARK: - IR.HorizontalAlignment → CSS

extension IR.HorizontalAlignment {
    /// Convert to CSS text-align
    public var cssTextAlign: String {
        switch self {
        case .leading: return "left"
        case .center: return "center"
        case .trailing: return "right"
        }
    }
    
    /// Convert to CSS justify-content
    public var cssJustifyContent: String {
        switch self {
        case .leading: return "flex-start"
        case .center: return "center"
        case .trailing: return "flex-end"
        }
    }
}

// MARK: - IR.VerticalAlignment → CSS

extension IR.VerticalAlignment {
    /// Convert to CSS align-items
    public var cssAlignItems: String {
        switch self {
        case .top: return "flex-start"
        case .center: return "center"
        case .bottom: return "flex-end"
        }
    }
}

// MARK: - IR.FontWeight → CSS

extension IR.FontWeight {
    /// Convert to CSS font-weight value
    public var cssValue: String {
        switch self {
        case .ultraLight: return "100"
        case .thin: return "200"
        case .light: return "300"
        case .regular: return "400"
        case .medium: return "500"
        case .semibold: return "600"
        case .bold: return "700"
        case .heavy: return "800"
        case .black: return "900"
        }
    }
    
    /// CSS font-weight as integer
    public var cssNumericValue: Int {
        switch self {
        case .ultraLight: return 100
        case .thin: return 200
        case .light: return 300
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        case .heavy: return 800
        case .black: return 900
        }
    }
}

// MARK: - IR.TextAlignment → CSS

extension IR.TextAlignment {
    /// Convert to CSS text-align
    public var cssValue: String {
        switch self {
        case .leading: return "left"
        case .center: return "center"
        case .trailing: return "right"
        }
    }
}

// MARK: - IR.UnitPoint → CSS

extension IR.UnitPoint {
    /// Convert to CSS background-position or gradient direction
    public var cssPosition: String {
        "\(Int(x * 100))% \(Int(y * 100))%"
    }
    
    /// Convert to CSS gradient direction keyword
    public var cssGradientPosition: String {
        // Common positions
        if x == 0.5 && y == 0 { return "top" }
        if x == 0.5 && y == 1 { return "bottom" }
        if x == 0 && y == 0.5 { return "left" }
        if x == 1 && y == 0.5 { return "right" }
        if x == 0 && y == 0 { return "top left" }
        if x == 1 && y == 0 { return "top right" }
        if x == 0 && y == 1 { return "bottom left" }
        if x == 1 && y == 1 { return "bottom right" }
        // Fallback to percentage
        return cssPosition
    }
}

// MARK: - IR.Style → CSS

extension IR.Style {
    /// Generate CSS rules from this style
    public func cssRules() -> [String: String] {
        var rules: [String: String] = [:]
        
        // Typography
        if let family = fontFamily {
            rules["font-family"] = "'\(family)', var(--ios-font-stack)"
        }
        if let size = fontSize {
            rules["font-size"] = "\(Int(size))px"
        }
        if let weight = fontWeight {
            rules["font-weight"] = weight.cssValue
        }
        if let color = textColor {
            rules["color"] = color.cssRGBA
        }
        if let alignment = textAlignment {
            rules["text-align"] = alignment.cssValue
        }
        
        // Background & Border
        if let bg = backgroundColor {
            rules["background-color"] = bg.cssRGBA
        }
        if let radius = cornerRadius {
            rules["border-radius"] = "\(Int(radius))px"
        }
        if let width = borderWidth, width > 0 {
            rules["border-width"] = "\(Int(width))px"
            rules["border-style"] = "solid"
        }
        if let color = borderColor {
            rules["border-color"] = color.cssRGBA
        }
        
        // Image tint (using CSS filter for SF Symbols)
        if let tint = tintColor {
            // Note: This works for monochrome images/icons
            // For full color images, this won't apply correctly
            rules["color"] = tint.cssRGBA
        }
        
        // Sizing
        if let w = width { rules["width"] = "\(Int(w))px" }
        if let h = height { rules["height"] = "\(Int(h))px" }
        if let minW = minWidth { rules["min-width"] = "\(Int(minW))px" }
        if let minH = minHeight { rules["min-height"] = "\(Int(minH))px" }
        if let maxW = maxWidth { rules["max-width"] = "\(Int(maxW))px" }
        if let maxH = maxHeight { rules["max-height"] = "\(Int(maxH))px" }
        
        // Padding
        if let pt = paddingTop { rules["padding-top"] = "\(Int(pt))px" }
        if let pb = paddingBottom { rules["padding-bottom"] = "\(Int(pb))px" }
        if let pl = paddingLeading { rules["padding-left"] = "\(Int(pl))px" }
        if let pr = paddingTrailing { rules["padding-right"] = "\(Int(pr))px" }
        
        return rules
    }
    
    /// Generate CSS rule string (e.g., "color: red; font-size: 16px;")
    public func cssRuleString() -> String {
        cssRules()
            .map { "\($0.key): \($0.value)" }
            .sorted()  // For consistent output
            .joined(separator: "; ")
    }
    
    /// Generate a complete CSS class definition
    public func cssClass(named className: String) -> String {
        let rules = cssRuleString()
        if rules.isEmpty {
            return ""
        }
        return ".\(className) { \(rules); }"
    }
}

// MARK: - ContainerNode.LayoutType → CSS

extension ContainerNode.LayoutType {
    /// CSS class name for this layout type
    public var cssClass: String {
        switch self {
        case .vstack: return "ios-vstack"
        case .hstack: return "ios-hstack"
        case .zstack: return "ios-zstack"
        }
    }
    
    /// CSS flex-direction value
    public var cssFlexDirection: String {
        switch self {
        case .vstack: return "column"
        case .hstack: return "row"
        case .zstack: return "column"  // ZStack uses grid, not flex
        }
    }
}

// MARK: - GradientNode → CSS

extension GradientNode {
    /// Generate CSS gradient value
    public var cssGradient: String {
        let colorStops = colors.map { stop in
            "\(stop.color.resolvedForCSS) \(Int(stop.location * 100))%"
        }.joined(separator: ", ")
        
        switch gradientType {
        case .linear:
            let angle = calculateAngle(from: startPoint, to: endPoint)
            return "linear-gradient(\(angle)deg, \(colorStops))"
        case .radial:
            return "radial-gradient(circle at \(startPoint.cssPosition), \(colorStops))"
        }
    }
    
    /// Calculate CSS gradient angle from start/end points
    private func calculateAngle(from start: IR.UnitPoint, to end: IR.UnitPoint) -> Int {
        // CSS angles: 0deg = to top, 90deg = to right, 180deg = to bottom, 270deg = to left
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        // Convert to degrees (CSS uses clockwise from top)
        var angle = atan2(dx, -dy) * 180 / .pi
        if angle < 0 { angle += 360 }
        
        return Int(angle.rounded())
    }
}

extension GradientColor {
    /// Resolve to CSS color string (using light mode for static generation)
    public var resolvedForCSS: String {
        switch self {
        case .fixed(let color):
            return color.cssRGBA
        case .adaptive(let light, _):
            // For static CSS, use light mode by default
            // Dynamic adaptation would require CSS custom properties
            return light.cssRGBA
        }
    }
}

// MARK: - ImageNode.Source → HTML

extension ImageNode.Source {
    /// Generate appropriate HTML/CSS for the image source
    public var htmlAttributes: (tag: String, attributes: [String: String]) {
        switch self {
        case .sfsymbol(let name):
            // SF Symbols rendered as icon font or SVG placeholder
            // In web context, we'd need to either use a symbol font or fallback
            return ("span", [
                "class": "ios-icon",
                "data-symbol": name,
                "aria-label": name.replacingOccurrences(of: ".", with: " ")
            ])
        case .asset(let name):
            return ("img", [
                "src": name,
                "alt": name,
                "class": "ios-image"
            ])
        case .url(let url):
            return ("img", [
                "src": url.absoluteString,
                "alt": "",
                "class": "ios-image",
                "loading": "lazy"
            ])
        case .statePath(let path):
            return ("img", [
                "data-src-path": path,
                "alt": "",
                "class": "ios-image ios-image--dynamic",
                "loading": "lazy"
            ])
        case .activityIndicator:
            // Activity indicator rendered as a loading spinner
            return ("div", [
                "class": "ios-activity-indicator",
                "role": "progressbar",
                "aria-label": "Loading"
            ])
        }
    }
}

// MARK: - String HTML Escaping

extension String {
    /// Escape HTML special characters
    public var htmlEscaped: String {
        var result = self
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&#39;")
        return result
    }
    
    /// Convert a Swift identifier to a valid CSS class name
    public var cssClassName: String {
        // Replace non-alphanumeric characters with hyphens
        let cleaned = self
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        
        // Ensure it starts with a letter
        if let first = cleaned.first, first.isNumber {
            return "n\(cleaned)"
        }
        return cleaned
    }
}
