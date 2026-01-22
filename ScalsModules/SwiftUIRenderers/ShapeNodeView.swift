//
//  ShapeNodeView.swift
//  ScalsModules
//
//  SwiftUI renderer for ShapeNode.
//

import SCALS
import SwiftUI

// MARK: - Shape Node SwiftUI Renderer

public struct ShapeNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.shape

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .shape(let shapeNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            ShapeNodeView(node: shapeNode, context: context)
                .environmentObject(context.observableStateStore)
                .environmentObject(context.observableActionContext)
        )
    }
}

// MARK: - Shape Node View

struct ShapeNodeView: View {
    let node: ShapeNode
    let context: SwiftUIRenderContext

    var body: some View {
        Group {
            switch node.shapeType {
            case .rectangle:
                Rectangle()
                    .fill(node.style.backgroundColor?.swiftUI ?? Color.clear)
                    .overlay(
                        Rectangle()
                            .stroke(node.style.borderColor?.swiftUI ?? Color.clear,
                                   lineWidth: node.style.borderWidth ?? 0)
                    )
            case .circle:
                Circle()
                    .fill(node.style.backgroundColor?.swiftUI ?? Color.clear)
                    .overlay(
                        Circle()
                            .stroke(node.style.borderColor?.swiftUI ?? Color.clear,
                                   lineWidth: node.style.borderWidth ?? 0)
                    )
            case .roundedRectangle(let cornerRadius):
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(node.style.backgroundColor?.swiftUI ?? Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(node.style.borderColor?.swiftUI ?? Color.clear,
                                   lineWidth: node.style.borderWidth ?? 0)
                    )
            case .capsule:
                Capsule()
                    .fill(node.style.backgroundColor?.swiftUI ?? Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(node.style.borderColor?.swiftUI ?? Color.clear,
                                   lineWidth: node.style.borderWidth ?? 0)
                    )
            case .ellipse:
                Ellipse()
                    .fill(node.style.backgroundColor?.swiftUI ?? Color.clear)
                    .overlay(
                        Ellipse()
                            .stroke(node.style.borderColor?.swiftUI ?? Color.clear,
                                   lineWidth: node.style.borderWidth ?? 0)
                    )
            }
        }
        .frame(
            width: node.style.width,
            height: node.style.height,
            alignment: .center
        )
        .frame(
            maxWidth: node.style.width == nil ? .infinity : nil,
            maxHeight: node.style.height == nil ? .infinity : nil
        )
        .padding(strokePadding)
    }

    // Add padding to prevent stroke from being clipped
    private var strokePadding: CGFloat {
        if let borderWidth = node.style.borderWidth, borderWidth > 0 {
            // Add padding equal to half the stroke width to prevent clipping
            return borderWidth / 2
        }
        return 0
    }
}
