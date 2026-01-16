//
//  IR.swift
//  CladsRendererFramework
//
//  Namespace for Intermediate Representation types.
//

import Foundation

// MARK: - IR Namespace

/// Namespace for Intermediate Representation (IR) types.
///
/// Types in this namespace represent the resolved, render-ready structures
/// after processing from `Document.*` types. These are consumed by renderers.
///
/// **Important**: This file should remain platform-agnostic. Do NOT import
/// SwiftUI or UIKit here. Platform-specific conversions belong in the
/// renderer layer (see `Renderers/SwiftUI/IRTypeConversions.swift`).
///
/// Usage:
/// ```swift
/// let style: IR.Style = resolver.resolve(styleId)
/// let section: IR.Section = ...
/// ```
public enum IR {}

// MARK: - Platform-Agnostic Types

extension IR {
    /// Platform-agnostic color representation using RGBA values.
    ///
    /// This type replaces SwiftUI.Color in the IR layer. Convert to platform-specific
    /// colors in the renderer layer using the `.swiftUI` or `.uiColor` extensions.
    public struct Color: Codable, Equatable, Sendable {
        public let red: Double
        public let green: Double
        public let blue: Double
        public let alpha: Double
        
        public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
        
        /// Parse a hex color string (e.g., "#FF0000", "FF0000", "#F00")
        public init(hex: String) {
            var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
            
            var rgb: UInt64 = 0
            Scanner(string: hexSanitized).scanHexInt64(&rgb)
            
            let r, g, b, a: Double
            
            switch hexSanitized.count {
            case 3: // RGB (12-bit)
                r = Double((rgb & 0xF00) >> 8) / 15.0
                g = Double((rgb & 0x0F0) >> 4) / 15.0
                b = Double(rgb & 0x00F) / 15.0
                a = 1.0
            case 6: // RGB (24-bit)
                r = Double((rgb & 0xFF0000) >> 16) / 255.0
                g = Double((rgb & 0x00FF00) >> 8) / 255.0
                b = Double(rgb & 0x0000FF) / 255.0
                a = 1.0
            case 8: // RGBA (32-bit)
                r = Double((rgb & 0xFF000000) >> 24) / 255.0
                g = Double((rgb & 0x00FF0000) >> 16) / 255.0
                b = Double((rgb & 0x0000FF00) >> 8) / 255.0
                a = Double(rgb & 0x000000FF) / 255.0
            default:
                r = 0; g = 0; b = 0; a = 1.0
            }
            
            self.red = r
            self.green = g
            self.blue = b
            self.alpha = a
        }
        
        // MARK: - Common Colors
        
        public static let clear = Color(red: 0, green: 0, blue: 0, alpha: 0)
        public static let black = Color(red: 0, green: 0, blue: 0, alpha: 1)
        public static let white = Color(red: 1, green: 1, blue: 1, alpha: 1)
        public static let red = Color(red: 1, green: 0, blue: 0, alpha: 1)
        public static let green = Color(red: 0, green: 1, blue: 0, alpha: 1)
        public static let blue = Color(red: 0, green: 0, blue: 1, alpha: 1)
    }
    
    /// Platform-agnostic edge insets.
    ///
    /// Replaces `NSEdgeInsets` from UIKit. Uses leading/trailing
    /// instead of left/right for proper RTL support.
    public struct EdgeInsets: Equatable, Sendable {
        public let top: CGFloat
        public let leading: CGFloat
        public let bottom: CGFloat
        public let trailing: CGFloat
        
        public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
            self.top = top
            self.leading = leading
            self.bottom = bottom
            self.trailing = trailing
        }
        
        public static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        public var isEmpty: Bool {
            top == 0 && bottom == 0 && leading == 0 && trailing == 0
        }
    }
    
    /// Platform-agnostic 2D alignment.
    ///
    /// Replaces `SwiftUI.Alignment` in the IR layer.
    public struct Alignment: Equatable, Sendable {
        public let horizontal: HorizontalAlignment
        public let vertical: VerticalAlignment
        
        public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
            self.horizontal = horizontal
            self.vertical = vertical
        }
        
        // MARK: - Standard Alignments
        
        public static let center = Alignment(horizontal: .center, vertical: .center)
        public static let leading = Alignment(horizontal: .leading, vertical: .center)
        public static let trailing = Alignment(horizontal: .trailing, vertical: .center)
        public static let top = Alignment(horizontal: .center, vertical: .top)
        public static let bottom = Alignment(horizontal: .center, vertical: .bottom)
        public static let topLeading = Alignment(horizontal: .leading, vertical: .top)
        public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)
        public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)
        public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)
    }
    
    /// Platform-agnostic horizontal alignment.
    public enum HorizontalAlignment: String, Codable, Sendable {
        case leading
        case center
        case trailing
    }
    
    /// Platform-agnostic vertical alignment.
    public enum VerticalAlignment: String, Codable, Sendable {
        case top
        case center
        case bottom
    }
    
    /// Platform-agnostic unit point for gradients and anchors.
    ///
    /// Replaces `SwiftUI.UnitPoint` in the IR layer.
    /// Values range from 0.0 to 1.0, where (0, 0) is top-leading and (1, 1) is bottom-trailing.
    public struct UnitPoint: Equatable, Sendable {
        public let x: Double
        public let y: Double
        
        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
        
        // MARK: - Standard Points
        
        public static let zero = UnitPoint(x: 0, y: 0)
        public static let center = UnitPoint(x: 0.5, y: 0.5)
        public static let leading = UnitPoint(x: 0, y: 0.5)
        public static let trailing = UnitPoint(x: 1, y: 0.5)
        public static let top = UnitPoint(x: 0.5, y: 0)
        public static let bottom = UnitPoint(x: 0.5, y: 1)
        public static let topLeading = UnitPoint(x: 0, y: 0)
        public static let topTrailing = UnitPoint(x: 1, y: 0)
        public static let bottomLeading = UnitPoint(x: 0, y: 1)
        public static let bottomTrailing = UnitPoint(x: 1, y: 1)
    }
    
    /// Platform-agnostic color scheme (light/dark mode).
    ///
    /// Replaces `SwiftUI.ColorScheme` in the IR layer.
    public enum ColorScheme: String, Codable, Sendable {
        case light
        case dark
        case system  // Use system setting
    }
    
    /// Platform-agnostic font weight.
    ///
    /// Reuses Document.FontWeight since it's already platform-agnostic.
    public typealias FontWeight = Document.FontWeight
    
    /// Platform-agnostic text alignment.
    ///
    /// Reuses Document.TextAlignment since it's already platform-agnostic.
    public typealias TextAlignment = Document.TextAlignment
}

// MARK: - IR.Style

extension IR {
    /// A fully resolved style with all inherited values merged.
    ///
    /// This is the IR representation of a style, ready for rendering.
    /// Uses platform-agnostic types - convert to SwiftUI/UIKit types in the renderer layer.
    public struct Style: Sendable {
        // Typography
        public var fontFamily: String?
        public var fontSize: CGFloat?
        public var fontWeight: IR.FontWeight?
        public var textColor: IR.Color?
        public var textAlignment: IR.TextAlignment?

        // Background & Border
        public var backgroundColor: IR.Color?
        public var cornerRadius: CGFloat?
        public var borderWidth: CGFloat?
        public var borderColor: IR.Color?

        // Image
        public var tintColor: IR.Color?

        // Sizing
        public var width: CGFloat?
        public var height: CGFloat?
        public var minWidth: CGFloat?
        public var minHeight: CGFloat?
        public var maxWidth: CGFloat?
        public var maxHeight: CGFloat?

        // Padding
        public var paddingTop: CGFloat?
        public var paddingBottom: CGFloat?
        public var paddingLeading: CGFloat?
        public var paddingTrailing: CGFloat?

        public init() {}

        mutating func merge(from style: Document.Style) {
            if let v = style.fontFamily { fontFamily = v }
            if let v = style.fontSize { fontSize = v }
            if let v = style.fontWeight { fontWeight = v }
            if let v = style.textColor { textColor = IR.Color(hex: v) }
            if let v = style.textAlignment { textAlignment = v }
            if let v = style.backgroundColor { backgroundColor = IR.Color(hex: v) }
            if let v = style.cornerRadius { cornerRadius = v }
            if let v = style.borderWidth { borderWidth = v }
            if let v = style.borderColor { borderColor = IR.Color(hex: v) }
            if let v = style.tintColor { tintColor = IR.Color(hex: v) }
            if let v = style.width { width = v }
            if let v = style.height { height = v }
            if let v = style.minWidth { minWidth = v }
            if let v = style.minHeight { minHeight = v }
            if let v = style.maxWidth { maxWidth = v }
            if let v = style.maxHeight { maxHeight = v }

            // Padding resolution using Padding struct
            if let padding = style.padding {
                if padding.top != nil || padding.vertical != nil {
                    paddingTop = padding.resolvedTop
                }
                if padding.bottom != nil || padding.vertical != nil {
                    paddingBottom = padding.resolvedBottom
                }
                if padding.leading != nil || padding.horizontal != nil {
                    paddingLeading = padding.resolvedLeading
                }
                if padding.trailing != nil || padding.horizontal != nil {
                    paddingTrailing = padding.resolvedTrailing
                }
            }
        }
    }
}

// MARK: - IR.Section

extension IR {
    /// A resolved section within a SectionLayoutNode
    public struct Section {
        public let id: String?
        public let layoutType: SectionType
        public let header: RenderNode?
        public let footer: RenderNode?
        public let stickyHeader: Bool
        public let config: SectionConfig
        public let children: [RenderNode]

        public init(
            id: String? = nil,
            layoutType: SectionType,
            header: RenderNode? = nil,
            footer: RenderNode? = nil,
            stickyHeader: Bool = false,
            config: SectionConfig = SectionConfig(),
            children: [RenderNode] = []
        ) {
            self.id = id
            self.layoutType = layoutType
            self.header = header
            self.footer = footer
            self.stickyHeader = stickyHeader
            self.config = config
            self.children = children
        }
    }
}

// MARK: - IR.SectionType

extension IR {
    /// Section type for rendering
    public enum SectionType {
        case horizontal  // Horizontally scrolling row
        case list        // Vertical list (table-like)
        case grid(columns: ColumnConfig)  // Grid layout
        case flow        // Flow/wrapping layout
    }
}

// MARK: - IR.ColumnConfig

extension IR {
    /// Resolved column configuration for grids
    public enum ColumnConfig: Equatable {
        case fixed(Int)
        case adaptive(minWidth: CGFloat)
    }
}

// MARK: - IR.SectionConfig

extension IR {
    /// Resolved configuration for a section
    public struct SectionConfig {
        public let alignment: IR.HorizontalAlignment
        public let itemSpacing: CGFloat
        public let lineSpacing: CGFloat
        public let contentInsets: IR.EdgeInsets

        // Item dimensions (for horizontal/grid sections)
        public let itemDimensions: ItemDimensions?

        // Horizontal section
        public let showsIndicators: Bool
        public let isPagingEnabled: Bool
        public let snapBehavior: SnapBehavior

        // List section
        public let showsDividers: Bool

        public init(
            alignment: IR.HorizontalAlignment = .leading,
            itemSpacing: CGFloat = 8,
            lineSpacing: CGFloat = 8,
            contentInsets: IR.EdgeInsets = .zero,
            itemDimensions: ItemDimensions? = nil,
            showsIndicators: Bool = false,
            isPagingEnabled: Bool = false,
            snapBehavior: SnapBehavior = .none,
            showsDividers: Bool = true
        ) {
            self.alignment = alignment
            self.itemSpacing = itemSpacing
            self.lineSpacing = lineSpacing
            self.contentInsets = contentInsets
            self.itemDimensions = itemDimensions
            self.showsIndicators = showsIndicators
            self.isPagingEnabled = isPagingEnabled
            self.snapBehavior = snapBehavior
            self.showsDividers = showsDividers
        }
    }
}

// MARK: - IR.ItemDimensions

extension IR {
    /// Resolved item dimensions for section items
    public struct ItemDimensions {
        public let width: DimensionValue?
        public let height: DimensionValue?
        public let aspectRatio: CGFloat?

        public init(
            width: DimensionValue? = nil,
            height: DimensionValue? = nil,
            aspectRatio: CGFloat? = nil
        ) {
            self.width = width
            self.height = height
            self.aspectRatio = aspectRatio
        }
    }
}

// MARK: - IR.DimensionValue

extension IR {
    /// Resolved dimension value - absolute or fractional
    @frozen
    public enum DimensionValue: Equatable {
        case absolute(CGFloat)
        case fractional(CGFloat)

        /// Resolve to an absolute value given a container size
        public func resolve(in containerSize: CGFloat) -> CGFloat {
            switch self {
            case .absolute(let value):
                return value
            case .fractional(let fraction):
                return containerSize * fraction
            }
        }
    }
}

// MARK: - IR.SnapBehavior

extension IR {
    /// Resolved snap behavior for horizontal sections
    public enum SnapBehavior {
        case none
        case viewAligned
        case paging
    }
}

// MARK: - IR.Positioning

extension IR {
    /// Positioning reference for edge insets
    public enum Positioning {
        /// Position relative to safe area boundaries
        case safeArea
        /// Position relative to absolute screen edges (ignores safe area)
        case absolute
    }
}

// MARK: - IR.PositionedEdgeInset

extension IR {
    /// A resolved edge inset with positioning and value
    public struct PositionedEdgeInset {
        public let positioning: Positioning
        public let value: CGFloat

        public init(positioning: Positioning, value: CGFloat) {
            self.positioning = positioning
            self.value = value
        }
    }
}

// MARK: - IR.PositionedEdgeInsets

extension IR {
    /// Positioned edge insets for the root container.
    ///
    /// Unlike `IR.EdgeInsets`, this type supports positioning modes (safeArea vs absolute)
    /// for each edge, used specifically for root container layout.
    public struct PositionedEdgeInsets {
        public let top: PositionedEdgeInset?
        public let bottom: PositionedEdgeInset?
        public let leading: PositionedEdgeInset?
        public let trailing: PositionedEdgeInset?

        public init(
            top: PositionedEdgeInset? = nil,
            bottom: PositionedEdgeInset? = nil,
            leading: PositionedEdgeInset? = nil,
            trailing: PositionedEdgeInset? = nil
        ) {
            self.top = top
            self.bottom = bottom
            self.leading = leading
            self.trailing = trailing
        }
    }
}

