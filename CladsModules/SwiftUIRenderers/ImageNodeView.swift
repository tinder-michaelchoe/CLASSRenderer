//
//  ImageNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for ImageNode.
//

import CLADS
import SwiftUI

// MARK: - Image Node SwiftUI Renderer

public struct ImageNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.image

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .image(let imageNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            ImageNodeView(node: imageNode, actionContext: context.actionContext, stateStore: context.stateStore)
        )
    }
}

// MARK: - Image Node View

struct ImageNodeView: View {
    let node: ImageNode
    let actionContext: ActionContext
    @ObservedObject var stateStore: StateStore
    
    /// Default placeholder when none specified (shown on error or no URL)
    private var defaultPlaceholder: ImageNode.Source {
        .system(name: "photo")
    }
    
    /// The effective placeholder to show on error or when URL is empty
    private var effectivePlaceholder: ImageNode.Source {
        node.placeholder ?? defaultPlaceholder
    }
    
    /// Computes the URL from a statePath template by interpolating with StateStore
    private func computeURL(from template: String) -> URL? {
        let interpolated = stateStore.interpolate(template)
        // Return nil if the interpolated result is empty or still contains unresolved placeholders
        guard !interpolated.isEmpty, !interpolated.contains("${") else {
            return nil
        }
        return URL(string: interpolated)
    }

    var body: some View {
        if let onTap = node.onTap {
            Button(action: { handleTap(onTap) }) {
                imageContent
            }
            .buttonStyle(.plain)
        } else {
            imageContent
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        Group {
            switch node.source {
            case .system(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .modifier(TintModifier(tintColor: node.style.tintColor))

            case .asset(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .modifier(TintModifier(tintColor: node.style.tintColor))

            case .url(let url):
                asyncImageView(url: url)
                
            case .statePath(let template):
                // Compute URL from state and reload when it changes
                if let url = computeURL(from: template) {
                    asyncImageView(url: url)
                        .id(url.absoluteString) // Force reload when URL changes
                } else {
                    // Show placeholder when URL is not yet available
                    placeholderView
                }
            }
        }
        .frame(width: node.style.width, height: node.style.height)
        .frame(maxWidth: node.style.width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: node.style.cornerRadius ?? 0))
    }
    
    @ViewBuilder
    private func asyncImageView(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                // Show loading indicator while fetching
                loadingView
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fit)
            case .failure:
                // Show placeholder on error
                placeholderView
            @unknown default:
                loadingView
            }
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        if let loading = node.loading {
            // Custom loading indicator
            renderSource(loading)
        } else {
            // Default: ProgressView spinner
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        renderSource(effectivePlaceholder)
    }
    
    @ViewBuilder
    private func renderSource(_ source: ImageNode.Source) -> some View {
        switch source {
        case .system(let name):
            Image(systemName: name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.secondary)
        case .asset(let name):
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .url(let url):
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
        case .statePath:
            // Loading/placeholder shouldn't be dynamic, fall back to default
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.secondary)
        }
    }

    private func handleTap(_ binding: Document.Component.ActionBinding) {
        Task { @MainActor in
            switch binding {
            case .reference(let actionId):
                await actionContext.executeAction(id: actionId)
            case .inline(let action):
                await actionContext.executeAction(action)
            }
        }
    }
}

// MARK: - Tint Modifier

/// Applies tint color to an image if specified
struct TintModifier: ViewModifier {
    let tintColor: Color?

    func body(content: Content) -> some View {
        if let tintColor {
            content.foregroundStyle(tintColor)
        } else {
            content
        }
    }
}
