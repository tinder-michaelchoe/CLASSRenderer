//
//  UIKitRenderer.swift
//  CladsRendererFramework
//
//  Renders a RenderTree into UIKit views.
//

import UIKit

// MARK: - UIKit Renderer

/// Renders a RenderTree into a UIKit view hierarchy.
///
/// Uses `UIKitNodeRendererRegistry` to delegate rendering to specialized node renderers.
public struct UIKitRenderer: Renderer {
    private let actionContext: ActionContext
    private let registry: UIKitNodeRendererRegistry

    public init(
        actionContext: ActionContext,
        registry: UIKitNodeRendererRegistry
    ) {
        self.actionContext = actionContext
        self.registry = registry
    }

    public func render(_ tree: RenderTree) -> UIView {
        RenderTreeUIView(
            tree: tree,
            actionContext: actionContext,
            registry: registry
        )
    }
}

// MARK: - Render Tree UIView

/// Root UIView that renders a RenderTree
final class RenderTreeUIView: UIView {
    private let tree: RenderTree
    private let context: UIKitRenderContext

    init(tree: RenderTree, actionContext: ActionContext, registry: UIKitNodeRendererRegistry) {
        self.tree = tree
        self.context = UIKitRenderContext(
            actionContext: actionContext,
            stateStore: tree.stateStore,
            colorScheme: tree.root.colorScheme,
            registry: registry
        )
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Background color - convert IR.Color to UIColor
        if let bg = tree.root.backgroundColor {
            backgroundColor = bg.uiColor
        } else {
            backgroundColor = .systemBackground
        }

        // Content container
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        // Apply edge insets with positioning-aware constraints
        let edgeInsets = tree.root.edgeInsets

        NSLayoutConstraint.activate([
            // Top constraint
            contentStack.topAnchor.constraint(
                equalTo: anchorGuide(for: edgeInsets?.top).topAnchor,
                constant: edgeInsets?.top?.value ?? 0
            ),
            // Bottom constraint
            contentStack.bottomAnchor.constraint(
                equalTo: anchorGuide(for: edgeInsets?.bottom).bottomAnchor,
                constant: -(edgeInsets?.bottom?.value ?? 0)
            ),
            // Leading constraint
            contentStack.leadingAnchor.constraint(
                equalTo: anchorGuide(for: edgeInsets?.leading).leadingAnchor,
                constant: edgeInsets?.leading?.value ?? 0
            ),
            // Trailing constraint
            contentStack.trailingAnchor.constraint(
                equalTo: anchorGuide(for: edgeInsets?.trailing).trailingAnchor,
                constant: -(edgeInsets?.trailing?.value ?? 0)
            )
        ])

        // Add children using the registry
        for child in tree.root.children {
            let childView = context.render(child)
            contentStack.addArrangedSubview(childView)
        }
    }

    /// Returns the appropriate layout guide based on the edge inset's positioning mode
    private func anchorGuide(for inset: IR.PositionedEdgeInset?) -> UILayoutGuide {
        switch inset?.positioning ?? .safeArea {
        case .safeArea:
            return safeAreaLayoutGuide
        case .absolute:
            return frameLayoutGuide
        }
    }

    /// A layout guide that represents the view's frame (ignoring safe area)
    private var frameLayoutGuide: UILayoutGuide {
        // Create a layout guide that matches the view's bounds
        if let existing = layoutGuides.first(where: { $0.identifier == "frameLayoutGuide" }) {
            return existing
        }
        let guide = UILayoutGuide()
        guide.identifier = "frameLayoutGuide"
        addLayoutGuide(guide)
        NSLayoutConstraint.activate([
            guide.topAnchor.constraint(equalTo: topAnchor),
            guide.bottomAnchor.constraint(equalTo: bottomAnchor),
            guide.leadingAnchor.constraint(equalTo: leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        return guide
    }
}

// MARK: - UIKit Style Extensions

public extension UILabel {
    func applyStyle(_ style: IR.Style) {
        // Convert IR.Color to UIColor
        if let textColor = style.textColor {
            self.textColor = textColor.uiColor
        }
        font = style.uiFont
        // Convert IR.TextAlignment to NSTextAlignment
        if let alignment = style.textAlignment {
            textAlignment = alignment.uiKit
        }
    }
}

public extension UIButton {
    func applyStyle(_ style: IR.Style) {
        // Convert IR.Color to UIColor
        if let textColor = style.textColor {
            setTitleColor(textColor.uiColor, for: .normal)
        }
        titleLabel?.font = style.uiFont
        if let bgColor = style.backgroundColor {
            self.backgroundColor = bgColor.uiColor
        }
        if let cornerRadius = style.cornerRadius {
            layer.cornerRadius = cornerRadius
            clipsToBounds = true
        }
        // Apply horizontal content alignment based on textAlignment
        if let textAlignment = style.textAlignment {
            switch textAlignment {
            case .leading:
                contentHorizontalAlignment = .leading
            case .center:
                contentHorizontalAlignment = .center
            case .trailing:
                contentHorizontalAlignment = .trailing
            }
        }
    }
}

public extension UITextField {
    func applyStyle(_ style: IR.Style) {
        // Convert IR.Color to UIColor
        if let textColor = style.textColor {
            self.textColor = textColor.uiColor
        }
        font = style.uiFont
        if let bgColor = style.backgroundColor {
            self.backgroundColor = bgColor.uiColor
        }
        if let cornerRadius = style.cornerRadius {
            layer.cornerRadius = cornerRadius
            clipsToBounds = true
        }
    }
}
