//
//  PageIndicatorComponentResolver.swift
//  ScalsModules
//
//  Resolves pageIndicator components into PageIndicatorNode
//

import SCALS
import Foundation

/// Page indicator resolution errors
enum PageIndicatorResolutionError: Error {
    case missingCurrentPage
}

/// Resolves `pageIndicator` components into PageIndicatorNode
public struct PageIndicatorComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .pageIndicator

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        // currentPage is required
        guard let currentPageStr = component.currentPage else {
            throw PageIndicatorResolutionError.missingCurrentPage
        }

        let style = context.styleResolver.resolve(component.styleId)

        // currentPage is always a state path (non-optional)
        let currentPagePath = currentPageStr

        // Resolve pageCount - can be static int, state path, or template
        let pageCountPath: String?
        let pageCountStatic: Int?

        if let staticCount = component.pageCount {
            // Static count provided directly
            pageCountPath = nil
            pageCountStatic = staticCount
        } else if let pageCountStr = component.additionalProperties?["pageCount"] as? String {
            // pageCount as string - could be state path or template
            if pageCountStr.contains("${") {
                // For now, treat templates as state paths by extracting variable name
                // E.g., "${items.length}" -> "items" or simple "${count}" -> "count"
                let cleaned = pageCountStr
                    .replacingOccurrences(of: "${", with: "")
                    .replacingOccurrences(of: "}", with: "")
                    .components(separatedBy: ".").first ?? pageCountStr
                pageCountPath = cleaned
                pageCountStatic = nil
            } else {
                // Direct state path
                pageCountPath = pageCountStr
                pageCountStatic = nil
            }
        } else {
            // Default
            pageCountPath = nil
            pageCountStatic = 5
        }

        let node = PageIndicatorNode(
            id: component.id,
            currentPagePath: currentPagePath,
            pageCountPath: pageCountPath,
            pageCountStatic: pageCountStatic,
            dotSize: component.dotSize ?? 8,
            dotSpacing: component.dotSpacing ?? 8,
            dotColor: IR.Color(hex: component.dotColor ?? "#CCCCCC"),
            currentDotColor: IR.Color(hex: component.currentDotColor ?? "#007AFF"),
            style: style
        )

        // Track state dependencies
        if context.isTracking {
            context.tracker?.recordRead(currentPagePath)
            if let path = pageCountPath {
                context.tracker?.recordRead(path)
            }
        }

        return ComponentResolutionResult(renderNode: .pageIndicator(node), viewNode: nil)
    }
}
