//
//  ShapeNodeRenderer.swift
//  ScalsModules
//
//  UIKit renderer for ShapeNode.
//

import SCALS
import UIKit

/// Renders ShapeNode to UIView with CAShapeLayer
public struct ShapeNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNodeKind = .shape

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .shape(let shapeNode) = node else {
            return UIView()
        }

        let shapeView = ShapeView()
        shapeView.configure(with: shapeNode)
        return shapeView
    }
}

// MARK: - Shape View

/// A UIView that renders shapes using CAShapeLayer
private final class ShapeView: UIView {
    private let shapeLayer = CAShapeLayer()
    private var currentNode: ShapeNode?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(shapeLayer)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with node: ShapeNode) {
        currentNode = node
        updateShape()
        applyStyle()
    }

    private func updateShape() {
        guard let node = currentNode else { return }

        let width = node.style.width ?? bounds.width
        let height = node.style.height ?? bounds.height
        let rect = CGRect(x: 0, y: 0, width: width, height: height)

        let path: UIBezierPath
        switch node.shapeType {
        case .rectangle:
            path = UIBezierPath(rect: rect)
        case .circle:
            path = UIBezierPath(ovalIn: rect)
        case .roundedRectangle(let cornerRadius):
            path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        case .capsule:
            path = UIBezierPath(roundedRect: rect, cornerRadius: min(width, height) / 2)
        case .ellipse:
            path = UIBezierPath(ovalIn: rect)
        }

        shapeLayer.path = path.cgPath
    }

    private func applyStyle() {
        guard let node = currentNode else { return }

        // Apply fill color
        if let backgroundColor = node.style.backgroundColor {
            shapeLayer.fillColor = backgroundColor.uiColor.cgColor
        } else {
            shapeLayer.fillColor = UIColor.clear.cgColor
        }

        // Apply stroke
        if let borderColor = node.style.borderColor,
           let borderWidth = node.style.borderWidth {
            shapeLayer.strokeColor = borderColor.uiColor.cgColor
            shapeLayer.lineWidth = borderWidth
        } else {
            shapeLayer.strokeColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = 0
        }

        // Apply size constraints if specified
        if let width = node.style.width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let height = node.style.height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        updateShape()
    }
}
