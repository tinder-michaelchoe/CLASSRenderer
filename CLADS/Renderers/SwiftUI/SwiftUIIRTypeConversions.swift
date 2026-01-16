//
//  IRTypeConversions.swift
//  CladsRendererFramework
//
//  Extensions to convert IR types to SwiftUI types.
//  This file bridges the platform-agnostic IR layer with SwiftUI rendering.
//

import SwiftUI

// MARK: - IR.Color → SwiftUI.Color

extension IR.Color {
    /// Convert to SwiftUI Color
    public var swiftUI: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - IR.EdgeInsets → SwiftUI.EdgeInsets

extension IR.EdgeInsets {
    /// Convert to SwiftUI EdgeInsets
    public var swiftUI: EdgeInsets {
        EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}

// MARK: - IR.Alignment → SwiftUI.Alignment

extension IR.Alignment {
    /// Convert to SwiftUI Alignment
    public var swiftUI: SwiftUI.Alignment {
        let h: SwiftUI.HorizontalAlignment = switch horizontal {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
        let v: SwiftUI.VerticalAlignment = switch vertical {
        case .top: .top
        case .center: .center
        case .bottom: .bottom
        }
        return SwiftUI.Alignment(horizontal: h, vertical: v)
    }
}

// MARK: - IR.HorizontalAlignment → SwiftUI.HorizontalAlignment

extension IR.HorizontalAlignment {
    /// Convert to SwiftUI HorizontalAlignment
    public var swiftUI: SwiftUI.HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - IR.VerticalAlignment → SwiftUI.VerticalAlignment

extension IR.VerticalAlignment {
    /// Convert to SwiftUI VerticalAlignment
    public var swiftUI: SwiftUI.VerticalAlignment {
        switch self {
        case .top: return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }
}

// MARK: - IR.UnitPoint → SwiftUI.UnitPoint

extension IR.UnitPoint {
    /// Convert to SwiftUI UnitPoint
    public var swiftUI: SwiftUI.UnitPoint {
        SwiftUI.UnitPoint(x: x, y: y)
    }
}

// MARK: - IR.FontWeight → Font.Weight

extension IR.FontWeight {
    /// Convert to SwiftUI Font.Weight
    public var swiftUI: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

// MARK: - IR.TextAlignment → SwiftUI.TextAlignment

extension IR.TextAlignment {
    /// Convert to SwiftUI TextAlignment
    public var swiftUI: SwiftUI.TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - IR.ColorScheme → SwiftUI.ColorScheme

extension IR.ColorScheme {
    /// Convert to SwiftUI ColorScheme (nil for .system)
    public var swiftUI: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - IR.Style SwiftUI Extensions

extension IR.Style {
    /// Get the SwiftUI Font with size, weight, and family applied
    public var swiftUIFont: Font? {
        guard fontSize != nil || fontWeight != nil || fontFamily != nil else { return nil }
        let size = fontSize ?? 17
        
        // If custom font family is specified, use it
        if let family = fontFamily {
            return Font.custom(family, size: size)
        }
        
        // Otherwise use system font with weight
        var font = Font.system(size: size)
        if let weight = fontWeight {
            font = font.weight(weight.swiftUI)
        }
        return font
    }
}

// MARK: - Document.FontWeight → Font.Weight (Backward Compatibility)

extension Document.FontWeight {
    /// Convert to SwiftUI Font.Weight
    /// Note: This is equivalent to using `IR.FontWeight.swiftUI` since IR.FontWeight is a typealias
    public func toSwiftUI() -> Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

// MARK: - Document.TextAlignment → SwiftUI.TextAlignment (Backward Compatibility)

extension Document.TextAlignment {
    /// Convert to SwiftUI TextAlignment
    /// Note: This is equivalent to using `IR.TextAlignment.swiftUI` since IR.TextAlignment is a typealias
    public func toSwiftUI() -> SwiftUI.TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - SwiftUI.Color Hex Initializer

public extension Color {
    /// Initialize a SwiftUI Color from a hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
