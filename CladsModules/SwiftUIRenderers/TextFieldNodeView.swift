//
//  TextFieldNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for TextFieldNode.
//

import CLADS
import Combine
import SwiftUI

// MARK: - TextField Node SwiftUI Renderer

public struct TextFieldNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.textField

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .textField(let textFieldNode) = node else {
            return AnyView(EmptyView())
        }
        // Wrap the StateStore in ObservableStateStore for SwiftUI observation
        let observableStore = ObservableStateStore(wrapping: context.stateStore)
        return AnyView(
            TextFieldNodeView(node: textFieldNode, stateStore: observableStore)
        )
    }
}

// MARK: - TextField Node View

struct TextFieldNodeView: View {
    let node: TextFieldNode
    @ObservedObject var stateStore: ObservableStateStore
    @State private var text: String = ""
    @State private var isUpdatingFromState: Bool = false

    var body: some View {
        TextField(node.placeholder, text: $text)
            .applyTextStyle(node.style)
            .onAppear {
                syncFromState()
            }
            .onChange(of: text) { _, newValue in
                // Only update state if the change came from user input, not from state sync
                guard !isUpdatingFromState else { return }
                if let path = node.bindingPath {
                    stateStore.set(path, value: newValue)
                }
            }
            .onReceive(stateStore.objectWillChange) { _ in
                // Sync from state when state changes externally
                syncFromState()
            }
    }
    
    private func syncFromState() {
        if let path = node.bindingPath {
            let stateValue = stateStore.get(path) as? String ?? ""
            if stateValue != text {
                isUpdatingFromState = true
                text = stateValue
                // Reset flag after a brief delay to allow the onChange to fire
                DispatchQueue.main.async {
                    isUpdatingFromState = false
                }
            }
        }
    }
}
