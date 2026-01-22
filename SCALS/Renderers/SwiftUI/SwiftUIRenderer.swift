//
//  SwiftUIRenderer.swift
//  ScalsRendererFramework
//
//  Renders a RenderTree into SwiftUI views.
//

import SwiftUI

// MARK: - SwiftUI Renderer

/// Renders a RenderTree into SwiftUI views
public struct SwiftUIRenderer: Renderer {
    private let actionContext: ActionContext
    private let rendererRegistry: SwiftUINodeRendererRegistry
    private let designSystemProvider: (any DesignSystemProvider)?

    public init(
        actionContext: ActionContext,
        rendererRegistry: SwiftUINodeRendererRegistry,
        designSystemProvider: (any DesignSystemProvider)? = nil
    ) {
        self.actionContext = actionContext
        self.rendererRegistry = rendererRegistry
        self.designSystemProvider = designSystemProvider
    }

    public func render(_ tree: RenderTree) -> some View {
        RenderTreeView(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: rendererRegistry,
            designSystemProvider: designSystemProvider
        )
    }
}

// MARK: - Render Tree View

/// SwiftUI view that renders a RenderTree
struct RenderTreeView: View {
    let tree: RenderTree
    let actionContext: ActionContext
    let rendererRegistry: SwiftUINodeRendererRegistry
    let designSystemProvider: (any DesignSystemProvider)?
    
    // Observe the stateStore to trigger re-renders when state changes
    // We use ObservableStateStore which wraps the platform-agnostic StateStore
    @ObservedObject private var observableStateStore: ObservableStateStore
    
    // Wrap ActionContext for SwiftUI environment injection
    private let observableActionContext: ObservableActionContext
    
    init(
        tree: RenderTree,
        actionContext: ActionContext,
        rendererRegistry: SwiftUINodeRendererRegistry,
        designSystemProvider: (any DesignSystemProvider)? = nil
    ) {
        self.tree = tree
        self.actionContext = actionContext
        self.rendererRegistry = rendererRegistry
        self.designSystemProvider = designSystemProvider
        // IMPORTANT: Use actionContext.stateStore, not tree.stateStore!
        // ActionContext is a @StateObject that persists across view recreations,
        // so its stateStore is the stable reference that actions update.
        self.observableStateStore = ObservableStateStore(wrapping: actionContext.stateStore)
        self.observableActionContext = ObservableActionContext(wrapping: actionContext)
    }

    var body: some View {
        ZStack {
            // Background - convert IR.Color to SwiftUI.Color
            if let bg = tree.root.backgroundColor {
                bg.swiftUI.ignoresSafeArea()
            }

            // Content with edge insets using custom RootLayout
            RootLayout(edgeInsets: tree.root.edgeInsets) {
                VStack(spacing: 0) {
                    ForEach(Array(tree.root.children.enumerated()), id: \.offset) { _, node in
                        RenderNodeView(node: node, context: context)
                    }
                    Spacer(minLength: 0)
                }
            }
            .ignoresSafeArea(edges: absoluteEdges)
        }
        .environmentObject(observableStateStore)
        .environmentObject(observableActionContext)
        .rootActions(tree.root.actions, context: actionContext)
    }

    private var context: SwiftUIRenderContext {
        SwiftUIRenderContext(
            tree: tree,
            actionContext: actionContext,
            rendererRegistry: rendererRegistry,
            designSystemProvider: designSystemProvider
        )
    }

    /// Edges that should ignore safe area (absolute positioning)
    private var absoluteEdges: Edge.Set {
        var edges: Edge.Set = []
        if tree.root.edgeInsets?.top?.positioning == .absolute { edges.insert(.top) }
        if tree.root.edgeInsets?.bottom?.positioning == .absolute { edges.insert(.bottom) }
        if tree.root.edgeInsets?.leading?.positioning == .absolute { edges.insert(.leading) }
        if tree.root.edgeInsets?.trailing?.positioning == .absolute { edges.insert(.trailing) }
        return edges
    }
}

// MARK: - Root Layout

/// A custom Layout that positions content based on edge insets
struct RootLayout: Layout {
    let edgeInsets: IR.PositionedEdgeInsets?

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Return the proposed size (fill available space)
        CGSize(
            width: proposal.width ?? 0,
            height: proposal.height ?? 0
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else { return }

        // Calculate insets from the bounds
        // For safeArea positioning: bounds already accounts for safe area, add our value
        // For absolute positioning: bounds extends to screen edge due to ignoresSafeArea, add our value
        let topInset = edgeInsets?.top?.value ?? 0
        let bottomInset = edgeInsets?.bottom?.value ?? 0
        let leadingInset = edgeInsets?.leading?.value ?? 0
        let trailingInset = edgeInsets?.trailing?.value ?? 0

        // Calculate the content frame
        let contentWidth = bounds.width - leadingInset - trailingInset
        let contentHeight = bounds.height - topInset - bottomInset

        let origin = CGPoint(
            x: bounds.minX + leadingInset,
            y: bounds.minY + topInset
        )

        subview.place(
            at: origin,
            proposal: ProposedViewSize(width: contentWidth, height: contentHeight)
        )
    }
}

// MARK: - Render Node View

/// SwiftUI view that renders a single RenderNode using the registry
struct RenderNodeView: View {
    let node: RenderNode
    let context: SwiftUIRenderContext

    var body: some View {
        context.render(node)
    }
}
