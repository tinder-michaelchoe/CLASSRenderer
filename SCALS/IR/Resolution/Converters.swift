//
//  Converters.swift
//  ScalsRendererFramework
//
//  Value converters for transforming schema types to IR types.
//
//  **Important**: This file should remain platform-agnostic. Do NOT import
//  SwiftUI or UIKit here. Platform-specific conversions belong in the
//  renderer layer (see `Renderers/SwiftUI/IRTypeConversions.swift`).
//

import Foundation

// MARK: - Alignment Converter

/// Converts schema alignment types to IR.Alignment
public enum AlignmentConverter {

    /// Converts horizontal alignment for VStack
    public static func forVStack(_ alignment: Document.HorizontalAlignment?) -> IR.Alignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        case .center, .none: return .center
        }
    }

    /// Converts vertical alignment for HStack
    public static func forHStack(_ alignment: Document.VerticalAlignment?) -> IR.Alignment {
        switch alignment {
        case .top: return .top
        case .bottom: return .bottom
        case .center, .none: return .center
        }
    }

    /// Converts 2D alignment for ZStack
    public static func forZStack(_ alignment: Document.Alignment?) -> IR.Alignment {
        guard let alignment = alignment else { return .center }

        let h: IR.HorizontalAlignment
        let v: IR.VerticalAlignment

        switch alignment.horizontal {
        case .leading: h = .leading
        case .trailing: h = .trailing
        case .center, .none: h = .center
        }

        switch alignment.vertical {
        case .top: v = .top
        case .bottom: v = .bottom
        case .center, .none: v = .center
        }

        return IR.Alignment(horizontal: h, vertical: v)
    }
}

// MARK: - Gradient Point Converter

/// Converts gradient point strings to IR.UnitPoint
public enum GradientPointConverter {

    /// Converts a named point string to IR.UnitPoint
    /// - Parameter point: Named point like "top", "bottomLeading", etc.
    /// - Returns: Corresponding IR.UnitPoint, defaults to .bottom
    public static func convert(_ point: String?) -> IR.UnitPoint {
        switch point?.lowercased() {
        case "top": return .top
        case "bottom": return .bottom
        case "leading": return .leading
        case "trailing": return .trailing
        case "topleading": return .topLeading
        case "toptrailing": return .topTrailing
        case "bottomleading": return .bottomLeading
        case "bottomtrailing": return .bottomTrailing
        case "center": return .center
        default: return .bottom
        }
    }
}

// MARK: - Padding Converter

/// Converts schema Padding to IR.EdgeInsets
public enum PaddingConverter {

    /// Converts optional Padding to IR.EdgeInsets
    public static func convert(_ padding: Document.Padding?) -> IR.EdgeInsets {
        guard let padding = padding else { return .zero }
        return IR.EdgeInsets(
            top: padding.resolvedTop,
            leading: padding.resolvedLeading,
            bottom: padding.resolvedBottom,
            trailing: padding.resolvedTrailing
        )
    }
}

// MARK: - Color Scheme Converter

/// Converts color scheme strings to IR.ColorScheme
public enum ColorSchemeConverter {

    /// Converts a color scheme string to IR.ColorScheme
    public static func convert(_ scheme: String?) -> IR.ColorScheme {
        switch scheme?.lowercased() {
        case "light": return .light
        case "dark": return .dark
        default: return .system
        }
    }
}

// MARK: - State Value Converter

/// Converts StateValue enum to native Swift types
public enum StateValueConverter {

    /// Unwraps a StateValue to its underlying Swift type
    public static func unwrap(_ value: Document.StateValue) -> Any {
        switch value {
        case .intValue(let v): return v
        case .doubleValue(let v): return v
        case .stringValue(let v): return v
        case .boolValue(let v): return v
        case .nullValue: return NSNull()
        case .arrayValue(let arr): return arr.map { unwrap($0) }
        case .objectValue(let obj): return obj.mapValues { unwrap($0) }
        }
    }

    /// Converts a value to StateSetValue for action resolution
    public static func toSetValue(_ value: Any?) -> StateSetValue {
        guard let value = value else { return .literal(.nullValue) }

        if let dict = value as? [String: Any],
           let expr = dict["$expr"] as? String {
            return .expression(expr)
        }

        // Convert to StateValue
        let stateValue = anyToStateValue(value)
        return .literal(stateValue)
    }

    /// Converts an Any value to StateValue
    public static func anyToStateValue(_ value: Any) -> Document.StateValue {
        if let intVal = value as? Int {
            return .intValue(intVal)
        } else if let doubleVal = value as? Double {
            return .doubleValue(doubleVal)
        } else if let stringVal = value as? String {
            return .stringValue(stringVal)
        } else if let boolVal = value as? Bool {
            return .boolValue(boolVal)
        } else if let arrayVal = value as? [Any] {
            return .arrayValue(arrayVal.map { anyToStateValue($0) })
        } else if let dictVal = value as? [String: Any] {
            return .objectValue(dictVal.mapValues { anyToStateValue($0) })
        } else {
            return .nullValue
        }
    }
}
