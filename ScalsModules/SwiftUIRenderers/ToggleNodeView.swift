//
//  ToggleNodeView.swift
//  ScalsModules
//
//  SwiftUI renderer and view for ToggleNode.
//

import SCALS
import SwiftUI

// MARK: - Toggle Node SwiftUI Renderer

public struct ToggleNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.toggle

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .toggle(let toggleNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            ToggleNodeView(node: toggleNode)
                .environmentObject(context.observableStateStore)
        )
    }
}

// MARK: - Toggle Node View

struct ToggleNodeView: View {
    let node: ToggleNode
    @EnvironmentObject var stateStore: ObservableStateStore
    @State private var isOn: Bool = false

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            // Convert IR.Color to SwiftUI.Color
            .tint(node.style.tintColor?.swiftUI)
            .onAppear {
                if let path = node.bindingPath {
                    isOn = stateStore.get(path) as? Bool ?? false
                }
            }
            .onChange(of: isOn) { _, newValue in
                if let path = node.bindingPath {
                    stateStore.set(path, value: newValue)
                }
            }
    }
}
