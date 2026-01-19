//
//  ButtonNodeView.swift
//  CladsModules
//
//  SwiftUI renderer and view for ButtonNode.
//

import CLADS
import SwiftUI

// MARK: - Button Node SwiftUI Renderer

public struct ButtonNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.button

    public init() {}

    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .button(let buttonNode) = node else {
            return AnyView(EmptyView())
        }
        return AnyView(
            ButtonNodeView(node: buttonNode, actionContext: context.actionContext)
                .environmentObject(context.observableStateStore)
        )
    }
}

// MARK: - Button Node View

struct ButtonNodeView: View {
    let node: ButtonNode
    let actionContext: ActionContext
    @EnvironmentObject var stateStore: ObservableStateStore

    /// Check if button is selected based on state binding
    private var isSelected: Bool {
        guard let bindingPath = node.isSelectedBinding else { return false }
        return stateStore.get(bindingPath) as? Bool ?? false
    }

    /// Get the current style based on selection state
    private var currentStyle: IR.Style {
        node.styles.style(isSelected: isSelected)
    }

    /// Calculate effective corner radius based on buttonShape or style
    private var effectiveCornerRadius: CGFloat {
        guard let shape = node.buttonShape else {
            return currentStyle.cornerRadius ?? 0
        }

        switch shape {
        case .circle:
            let width = currentStyle.width ?? 44
            let height = currentStyle.height ?? 44
            return min(width, height) / 2

        case .capsule:
            let height = currentStyle.height ?? 44
            return height / 2

        case .roundedSquare:
            return 10  // Fixed moderate rounding
        }
    }

    var body: some View {
        Button(action: handleTap) {
            buttonLabel
                .applyTextStyle(currentStyle)
                .padding(.top, currentStyle.paddingTop ?? 0)
                .padding(.bottom, currentStyle.paddingBottom ?? 0)
                .padding(.leading, currentStyle.paddingLeading ?? 0)
                .padding(.trailing, currentStyle.paddingTrailing ?? 0)
                .frame(
                    width: currentStyle.width,
                    height: currentStyle.height
                )
                .frame(
                    maxWidth: node.fillWidth ? .infinity : nil,
                    alignment: alignmentForTextAlignment(currentStyle.textAlignment)
                )
                // Convert IR.Color to SwiftUI.Color
                .background(currentStyle.backgroundColor?.swiftUI ?? .clear)
                .cornerRadius(effectiveCornerRadius)
        }
        .buttonStyle(.plain)
    }

    /// Convert IR.TextAlignment to SwiftUI.Alignment for frame positioning
    private func alignmentForTextAlignment(_ textAlignment: IR.TextAlignment?) -> Alignment {
        switch textAlignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        case .none:
            return .center
        }
    }

    @ViewBuilder
    private var buttonLabel: some View {
        if let image = node.image {
            // Image + Text or Image-only
            labelWithImage(image)
        } else {
            // Text-only (existing)
            Text(node.label)
        }
    }

    @ViewBuilder
    private func labelWithImage(_ imageSource: ImageNode.Source) -> some View {
        let imageView = resolveImage(imageSource)

        switch node.imagePlacement {
        case .leading:
            HStack(spacing: node.imageSpacing) {
                imageView
                if !node.label.isEmpty {
                    Text(node.label)
                }
            }
        case .trailing:
            HStack(spacing: node.imageSpacing) {
                if !node.label.isEmpty {
                    Text(node.label)
                }
                imageView
            }
        case .top:
            VStack(spacing: node.imageSpacing) {
                imageView
                if !node.label.isEmpty {
                    Text(node.label)
                }
            }
        case .bottom:
            VStack(spacing: node.imageSpacing) {
                if !node.label.isEmpty {
                    Text(node.label)
                }
                imageView
            }
        }
    }

    @ViewBuilder
    private func resolveImage(_ source: ImageNode.Source) -> some View {
        switch source {
        case .sfsymbol(let name):
            Image(systemName: name)
        case .asset(let name):
            Image(name)
        case .url(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
        case .statePath(let template):
            // Dynamic URL from state - resolve template
            let resolvedURL = resolveTemplateURL(template)
            if let url = resolvedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
            }
        }
    }

    /// Resolves a template URL by replacing ${...} with state values
    private func resolveTemplateURL(_ template: String) -> URL? {
        var resolved = template
        let pattern = #"\$\{([^}]+)\}"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return URL(string: template)
        }

        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        for match in matches.reversed() {
            if let range = Range(match.range, in: template),
               let pathRange = Range(match.range(at: 1), in: template) {
                let path = String(template[pathRange])
                if let value = stateStore.get(path) {
                    resolved.replaceSubrange(range, with: "\(value)")
                }
            }
        }

        return URL(string: resolved)
    }

    private func handleTap() {
        guard let binding = node.onTap else { return }
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
