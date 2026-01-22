//
//  GradientNodeView.swift
//  ScalsModules
//
//  SwiftUI renderer and view for GradientNode.
//

import SCALS
import SwiftUI

// MARK: - Gradient Node SwiftUI Renderer

public struct GradientNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.gradient

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .gradient(let gradientNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            GradientNodeView(node: gradientNode, colorScheme: context.tree.root.colorScheme)
        )
    }
}

// MARK: - Gradient Node View

struct GradientNodeView: View {
    let node: GradientNode
    let colorScheme: IR.ColorScheme
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        LinearGradient(
            stops: node.colors.map { stop in
                Gradient.Stop(
                    // Convert IR.Color to SwiftUI.Color
                    color: stop.color.resolved(for: colorScheme, isSystemDark: systemColorScheme == .dark).swiftUI,
                    location: stop.location
                )
            },
            // Convert IR.UnitPoint to SwiftUI.UnitPoint
            startPoint: node.startPoint.swiftUI,
            endPoint: node.endPoint.swiftUI
        )
        .frame(
            width: node.style.width,
            height: node.style.height,
            alignment: .center
        )
        .frame(
            maxWidth: node.style.width == nil ? .infinity : nil,
            maxHeight: node.style.height == nil ? .infinity : nil
        )
    }
}
