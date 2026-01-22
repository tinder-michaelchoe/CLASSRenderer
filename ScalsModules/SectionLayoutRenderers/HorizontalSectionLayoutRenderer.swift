//
//  HorizontalSectionLayoutRenderer.swift
//  ScalsModules
//
//  SwiftUI renderer for horizontal section layouts.
//

import SCALS
import SwiftUI

/// Renders horizontal section layouts in SwiftUI.
///
/// Horizontal layouts display items in a scrollable horizontal row.
public struct HorizontalSectionLayoutRenderer: SwiftUISectionLayoutRendering {
    
    public static let layoutTypeIdentifier = SectionLayoutTypeIdentifier.horizontal
    
    public init() {}
    
    @MainActor
    public func render(section: IR.Section, context: SwiftUISectionRenderContext) -> AnyView {
        AnyView(
            HorizontalSectionContentView(section: section, context: context)
        )
    }
}

// MARK: - Horizontal Section Content View

private struct HorizontalSectionContentView: View {
    let section: IR.Section
    let context: SwiftUISectionRenderContext

    @EnvironmentObject var stateStore: ObservableStateStore
    @State private var currentPage: Int = 0
    @State private var scrollPosition: Int? = 0

    // Check if this is card-based paging (paging enabled with binding)
    // Note: Card paging features not yet implemented in IR layer
    private var isCardPaging: Bool {
        false // section.config.isPagingEnabled && section.config.currentPageBinding != nil
    }

    var body: some View {
        // Standard horizontal scrolling
        // Note: Card paging features commented out - not yet implemented in IR layer
        ScrollView(.horizontal, showsIndicators: section.config.showsIndicators) {
                LazyHStack(spacing: section.config.itemSpacing) {
                    ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                        HorizontalSectionItemView(
                            child: child,
                            context: context,
                            dimensions: section.config.itemDimensions
                        )
                    }
            }
            .scrollTargetLayout()
        }
        .applySnapBehavior(section.config.snapBehavior)
    }
}

// MARK: - Card Page Item View

/// A view for card-based paging with configurable width
private struct CardPageItemView: View {
    let child: RenderNode
    let context: SwiftUISectionRenderContext
    let cardWidth: CGFloat
    let containerWidth: CGFloat

    var body: some View {
        context.renderChild(child)
            .frame(width: containerWidth * cardWidth)
    }
}

// MARK: - Horizontal Section Item View

/// A view that wraps section items with optional dimension constraints
private struct HorizontalSectionItemView: View {
    let child: RenderNode
    let context: SwiftUISectionRenderContext
    let dimensions: IR.ItemDimensions?

    var body: some View {
        context.renderChild(child)
            .modifier(ItemDimensionsModifier(dimensions: dimensions))
    }
}

// MARK: - Item Dimensions Modifier

/// Modifier that applies item dimensions using containerRelativeFrame for fractional widths
struct ItemDimensionsModifier: ViewModifier {
    let dimensions: IR.ItemDimensions?

    func body(content: Content) -> some View {
        if let dimensions = dimensions {
            content
                .modifier(WidthModifier(width: dimensions.width))
                .modifier(HeightModifier(height: dimensions.height, aspectRatio: dimensions.aspectRatio, width: dimensions.width))
        } else {
            content
        }
    }
}

/// Applies width dimension (absolute or fractional)
private struct WidthModifier: ViewModifier {
    let width: IR.DimensionValue?

    func body(content: Content) -> some View {
        if let width = width {
            switch width {
            case .absolute(let value):
                content.frame(width: value)
            case .fractional(let fraction):
                content.containerRelativeFrame(.horizontal) { containerWidth, _ in
                    containerWidth * fraction
                }
            }
        } else {
            content
        }
    }
}

/// Applies height dimension (absolute, or computed from aspect ratio)
private struct HeightModifier: ViewModifier {
    let height: IR.DimensionValue?
    let aspectRatio: CGFloat?
    let width: IR.DimensionValue?

    func body(content: Content) -> some View {
        if let height = height {
            switch height {
            case .absolute(let value):
                content.frame(height: value)
            case .fractional(let fraction):
                content.containerRelativeFrame(.vertical) { containerHeight, _ in
                    containerHeight * fraction
                }
            }
        } else if let aspectRatio = aspectRatio {
            content.aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            content
        }
    }
}

// MARK: - Snap Behavior Extension

public extension View {
    @ViewBuilder
    func applySnapBehavior(_ behavior: IR.SnapBehavior) -> some View {
        switch behavior {
        case .none:
            self
        case .viewAligned:
            self.scrollTargetBehavior(.viewAligned)
        case .paging:
            self.scrollTargetBehavior(.paging)
        }
    }
}
