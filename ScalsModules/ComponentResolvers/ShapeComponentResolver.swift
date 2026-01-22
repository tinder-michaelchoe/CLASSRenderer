//
//  ShapeComponentResolver.swift
//  ScalsModules
//
//  Resolves shape components into ShapeNode.
//

import SCALS
import Foundation

/// Shape resolution errors
enum ShapeResolutionError: Error {
    case missingShapeType
    case invalidShapeType(String)
}

/// Resolves `shape` components into ShapeNode
public struct ShapeComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .shape

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        // Get shapeType from component
        guard let shapeTypeStr = component.shapeType else {
            throw ShapeResolutionError.missingShapeType
        }

        // Convert string to ShapeType enum
        let shapeType: ShapeNode.ShapeType
        switch shapeTypeStr {
        case "rectangle":
            shapeType = .rectangle
        case "circle":
            shapeType = .circle
        case "roundedRectangle":
            let cornerRadius = component.cornerRadius ?? 0
            shapeType = .roundedRectangle(cornerRadius: cornerRadius)
        case "capsule":
            shapeType = .capsule
        case "ellipse":
            shapeType = .ellipse
        default:
            throw ShapeResolutionError.invalidShapeType(shapeTypeStr)
        }

        // Resolve style
        let style = context.styleResolver.resolve(component.styleId)
        let nodeId = component.id ?? UUID().uuidString

        // Build ShapeNode
        let shapeNode = ShapeNode(
            id: nodeId,
            shapeType: shapeType,
            style: style
        )

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .shape(ShapeNodeData(
                    shapeType: shapeType,
                    style: style
                ))
            )
            viewNode?.parent = context.parentViewNode
        } else {
            viewNode = nil
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        return ComponentResolutionResult(
            renderNode: .shape(shapeNode),
            viewNode: viewNode
        )
    }

    // MARK: - Private Helpers

    private func initializeLocalState(on viewNode: ViewNode, from localState: Document.LocalStateDeclaration) {
        var stateDict: [String: Any] = [:]
        for (key, value) in localState.initialValues {
            stateDict[key] = StateValueConverter.unwrap(value)
        }
        viewNode.localState = stateDict
    }
}
