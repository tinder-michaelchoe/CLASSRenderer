//
//  ContainerNodeRenderer.swift
//  CladsModules
//
//  Renders ContainerNode (VStack, HStack, ZStack) to UIKit views.
//

import CLADS
import SwiftUI
import UIKit

/// Renders container nodes (VStack, HStack, ZStack) to UIStackView or UIView
public struct ContainerNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNodeKind = .container

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .container(let containerNode) = node else {
            return UIView()
        }

        let contentView: UIView

        switch containerNode.layoutType {
        case .vstack, .hstack:
            contentView = renderStackContainer(containerNode, context: context)
        case .zstack:
            contentView = renderZStackContainer(containerNode, context: context)
        }

        // Wrap in container for padding if needed
        if containerNode.padding != .zero {
            return wrapWithPadding(contentView, padding: containerNode.padding)
        }

        return contentView
    }

    // MARK: - Stack Container (VStack/HStack)

    private func renderStackContainer(_ container: ContainerNode, context: UIKitRenderContext) -> UIView {
        let stackView = UIStackView()
        stackView.axis = container.layoutType == .vstack ? .vertical : .horizontal
        stackView.spacing = container.spacing
        stackView.alignment = container.alignment.toUIKit(for: container.layoutType)
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        for child in container.children {
            let childView = context.render(child)
            stackView.addArrangedSubview(childView)
        }

        return stackView
    }

    // MARK: - ZStack Container

    private func renderZStackContainer(_ container: ContainerNode, context: UIKitRenderContext) -> UIView {
        let zstackView = UIView()
        zstackView.translatesAutoresizingMaskIntoConstraints = false

        for child in container.children {
            let childView = context.render(child)
            childView.translatesAutoresizingMaskIntoConstraints = false
            zstackView.addSubview(childView)
            applyZStackAlignment(childView, in: zstackView, alignment: container.alignment)
        }

        return zstackView
    }

    private func applyZStackAlignment(_ child: UIView, in parent: UIView, alignment: IR.Alignment) {
        // Horizontal alignment
        switch alignment.horizontal {
        case .leading:
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor).isActive = true
        case .trailing:
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor).isActive = true
        case .center:
            child.centerXAnchor.constraint(equalTo: parent.centerXAnchor).isActive = true
        }

        // Vertical alignment
        switch alignment.vertical {
        case .top:
            child.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        case .bottom:
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor).isActive = true
        case .center:
            child.centerYAnchor.constraint(equalTo: parent.centerYAnchor).isActive = true
        }
    }

    // MARK: - Padding Wrapper

    private func wrapWithPadding(_ view: UIView, padding: IR.EdgeInsets) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: padding.top),
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -padding.bottom),
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: padding.leading),
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -padding.trailing)
        ])
        return wrapper
    }
}
