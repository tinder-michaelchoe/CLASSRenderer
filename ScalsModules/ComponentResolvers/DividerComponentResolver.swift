//
//  DividerComponentResolver.swift
//  ScalsModules
//
//  Resolves divider components.
//

import SCALS
import Foundation

/// Resolves `divider` components into DividerNode
public struct DividerComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .divider

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let style = context.styleResolver.resolve(component.styleId)

        let renderNode = RenderNode.divider(DividerNode(
            id: component.id,
            style: style
        ))

        return ComponentResolutionResult(renderNode: renderNode, viewNode: nil)
    }
}
