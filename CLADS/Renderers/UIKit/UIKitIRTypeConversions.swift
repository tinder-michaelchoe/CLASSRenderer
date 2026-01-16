//
//  IRTypeConversions.swift
//  CladsRendererFramework
//
//  Extensions to convert IR types to UIKit types.
//  This file bridges the platform-agnostic IR layer with UIKit rendering.
//

import UIKit

// MARK: - IR.Color → UIColor

extension IR.Color {
    /// Convert to UIKit UIColor
    public var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Alias for consistency with SwiftUI conversions
    public var toUIKit: UIColor { uiColor }
}

// MARK: - IR.EdgeInsets → NSDirectionalEdgeInsets

extension IR.EdgeInsets {
    /// Convert to UIKit NSDirectionalEdgeInsets
    public var uiKit: NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}

// MARK: - IR.FontWeight → UIFont.Weight

extension IR.FontWeight {
    /// Convert to UIKit UIFont.Weight
    public var uiKit: UIFont.Weight {
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

// MARK: - IR.TextAlignment → NSTextAlignment

extension IR.TextAlignment {
    /// Convert to UIKit NSTextAlignment
    public var uiKit: NSTextAlignment {
        switch self {
        case .leading: return .natural
        case .center: return .center
        case .trailing: return .right
        }
    }
}

// MARK: - IR.ColorScheme → UIUserInterfaceStyle

extension IR.ColorScheme {
    /// Convert to UIKit UIUserInterfaceStyle
    public var uiKit: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }
}

// MARK: - IR.Alignment → UIStackView.Alignment

extension IR.Alignment {
    /// Convert to UIKit UIStackView.Alignment based on the layout type
    public func toUIKit(for layoutType: ContainerNode.LayoutType) -> UIStackView.Alignment {
        switch layoutType {
        case .vstack:
            // For vertical stacks, horizontal alignment matters
            switch horizontal {
            case .leading: return .leading
            case .center: return .center
            case .trailing: return .trailing
            }
        case .hstack:
            // For horizontal stacks, vertical alignment matters
            switch vertical {
            case .top: return .top
            case .center: return .center
            case .bottom: return .bottom
            }
        case .zstack:
            // ZStack uses center alignment by default in UIKit representation
            return .center
        }
    }
}

// MARK: - IR.UnitPoint → CGPoint

extension IR.UnitPoint {
    /// Convert to CoreGraphics CGPoint
    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

// MARK: - IR.Style UIKit Extensions

extension IR.Style {
    /// Get the UIFont with size, weight, and family applied
    public var uiFont: UIFont? {
        guard fontSize != nil || fontWeight != nil || fontFamily != nil else { return nil }
        let size = fontSize ?? 17
        
        // If custom font family is specified, use it
        if let family = fontFamily, let customFont = UIFont(name: family, size: size) {
            return customFont
        }
        
        // Otherwise use system font with weight
        if let weight = fontWeight {
            return UIFont.systemFont(ofSize: size, weight: weight.uiKit)
        }
        return UIFont.systemFont(ofSize: size)
    }
}

// MARK: - Document.FontWeight → UIFont.Weight (Backward Compatibility)

extension Document.FontWeight {
    /// Convert to UIKit UIFont.Weight
    public func toUIKit() -> UIFont.Weight {
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

// MARK: - UIColor Hex Initializer

public extension UIColor {
    /// Initialize a UIColor from a hex string
    convenience init(hex: String) {
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
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
