//
//  TextNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for TextNode.
//

import CLADS
import SwiftUI

// MARK: - Text Node SwiftUI Renderer

public struct TextNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.text

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .text(let textNode) = node else {
            return AnyView(EmptyView())
        }
        // Wrap the StateStore in ObservableStateStore for SwiftUI observation
        let observableStore = ObservableStateStore(wrapping: context.stateStore)
        return AnyView(
            TextNodeView(node: textNode, stateStore: observableStore)
        )
    }
}

// MARK: - Text Node View

struct TextNodeView: View {
    let node: TextNode
    @ObservedObject var stateStore: ObservableStateStore

    var body: some View {
        Text(displayContent)
            .applyTextStyle(node.style)
            .padding(.top, node.padding.top)
            .padding(.bottom, node.padding.bottom)
            .padding(.leading, node.padding.leading)
            .padding(.trailing, node.padding.trailing)
    }

    /// Compute the content to display, reading from StateStore if dynamic
    private var displayContent: String {
        // If there's a binding path, read directly from state
        if let path = node.bindingPath {
            return stateStore.get(path) as? String ?? node.content
        }

        // If there's a template, interpolate with state
        if let template = node.bindingTemplate {
            return stateStore.interpolate(template)
        }

        // Otherwise, use static content
        return node.content
    }
}
