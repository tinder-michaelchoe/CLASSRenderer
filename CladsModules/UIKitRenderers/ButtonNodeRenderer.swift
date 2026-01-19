//
//  ButtonNodeRenderer.swift
//  CladsModules
//
//  Renders ButtonNode to UIButton.
//

import CLADS
import UIKit

/// Renders button nodes to ActionButton (UIButton subclass)
public struct ButtonNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNodeKind = .button

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .button(let buttonNode) = node else {
            return UIView()
        }

        let button = ActionButton(
            actionBinding: buttonNode.onTap,
            actionContext: context.actionContext
        )
        button.translatesAutoresizingMaskIntoConstraints = false

        // Configure button with UIButton.Configuration (iOS 17+ minimum)
        var config = UIButton.Configuration.plain()
        config.title = buttonNode.label

        // Configure image if present
        if let imageSource = buttonNode.image {
            config.image = resolveUIImage(imageSource, context: context)
            config.imagePlacement = uiImagePlacement(buttonNode.imagePlacement)
            config.imagePadding = buttonNode.imageSpacing
        }

        button.configuration = config
        button.applyStyle(buttonNode.style)

        // Apply button shape if specified
        applyButtonShape(button, node: buttonNode)

        if buttonNode.fillWidth {
            button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }

        if let width = buttonNode.style.width {
            button.widthAnchor.constraint(equalToConstant: width).isActive = true
        }

        if let height = buttonNode.style.height {
            button.heightAnchor.constraint(equalToConstant: height).isActive = true
        }

        return button
    }

    private func applyButtonShape(_ button: UIButton, node: ButtonNode) {
        guard let shape = node.buttonShape else {
            // No shape specified, use style's cornerRadius if present
            if let cornerRadius = node.style.cornerRadius {
                button.layer.cornerRadius = cornerRadius
                button.clipsToBounds = true
            }
            return
        }

        // Calculate corner radius based on shape
        switch shape {
        case .circle:
            let width = node.style.width ?? 44
            let height = node.style.height ?? 44
            button.layer.cornerRadius = min(width, height) / 2

        case .capsule:
            let height = node.style.height ?? 44
            button.layer.cornerRadius = height / 2

        case .roundedSquare:
            button.layer.cornerRadius = 10
        }

        button.clipsToBounds = true
    }

    private func uiImagePlacement(_ placement: ButtonNode.ImagePlacement) -> NSDirectionalRectEdge {
        switch placement {
        case .leading: return .leading
        case .trailing: return .trailing
        case .top: return .top
        case .bottom: return .bottom
        @unknown default: return .leading
        }
    }

    private func resolveUIImage(_ source: ImageNode.Source, context: UIKitRenderContext) -> UIImage? {
        switch source {
        case .sfsymbol(let name):
            return UIImage(systemName: name)
        case .asset(let name):
            return UIImage(named: name)
        case .url(let url):
            // For URLs, we'd need async loading - return placeholder for now
            return UIImage(systemName: "photo")
        case .statePath(let template):
            // For dynamic templates, we'd need to resolve from state - return placeholder for now
            return UIImage(systemName: "photo")
        }
    }
}

// MARK: - Action Button

/// UIButton subclass that executes an action on tap
public final class ActionButton: UIButton {
    private let actionBinding: Document.Component.ActionBinding?
    private let actionContext: ActionContext

    public init(actionBinding: Document.Component.ActionBinding?, actionContext: ActionContext) {
        self.actionBinding = actionBinding
        self.actionContext = actionContext
        super.init(frame: .zero)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        guard let binding = actionBinding else { return }
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
