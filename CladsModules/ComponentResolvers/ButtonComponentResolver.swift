//
//  ButtonComponentResolver.swift
//  CladsModules
//
//  Resolves button components.
//

import CLADS
import Foundation

/// Resolves `button` components into ButtonNode
public struct ButtonComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .button

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        // Resolve button styles
        let buttonStyles = resolveButtonStyles(component, context: context)
        let nodeId = component.id ?? UUID().uuidString

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .button(ButtonNodeData(
                    label: component.text ?? "",
                    style: buttonStyles.normal,
                    fillWidth: component.fillWidth ?? false,
                    onTapAction: component.actions?.onTap
                ))
            )
            viewNode?.parent = context.parentViewNode

            // Track dependencies during content resolution
            context.tracker?.beginTracking(for: viewNode!)
        } else {
            viewNode = nil
        }

        // Resolve content (may record dependencies)
        let contentResult = ContentResolver.resolve(component, context: context, viewNode: viewNode)

        // Resolve image source
        let imageSource = resolveImageSource(component, context: context)

        // Resolve image placement
        let imagePlacement: ButtonNode.ImagePlacement
        if let placementString = component.imagePlacement,
           let placement = ButtonNode.ImagePlacement(rawValue: placementString) {
            imagePlacement = placement
        } else {
            imagePlacement = .leading  // Default
        }

        // Resolve image spacing
        let imageSpacing = component.imageSpacing ?? 8

        // Resolve button shape
        let buttonShape: ButtonNode.ButtonShape?
        if let shapeString = component.buttonShape {
            buttonShape = ButtonNode.ButtonShape(rawValue: shapeString)
        } else {
            buttonShape = nil
        }

        if context.isTracking {
            context.tracker?.endTracking()
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        let renderNode = RenderNode.button(ButtonNode(
            id: component.id,
            label: component.text ?? contentResult.content,
            styleId: component.styleId,
            styles: buttonStyles,
            isSelectedBinding: component.isSelectedBinding,
            fillWidth: component.fillWidth ?? false,
            onTap: component.actions?.onTap,
            image: imageSource,
            imagePlacement: imagePlacement,
            imageSpacing: imageSpacing,
            buttonShape: buttonShape
        ))

        return ComponentResolutionResult(renderNode: renderNode, viewNode: viewNode)
    }

    private func resolveButtonStyles(_ component: Document.Component, context: ResolutionContext) -> ButtonStyles {
        // If component has styles dictionary, resolve each state
        if let componentStyles = component.styles {
            let normalStyle = context.styleResolver.resolve(componentStyles.normal ?? component.styleId)
            let selectedStyle = componentStyles.selected.map { context.styleResolver.resolve($0) }
            let disabledStyle = componentStyles.disabled.map { context.styleResolver.resolve($0) }

            return ButtonStyles(
                normal: normalStyle,
                selected: selectedStyle,
                disabled: disabledStyle
            )
        }

        // Fall back to single styleId
        let style = context.styleResolver.resolve(component.styleId)
        return ButtonStyles(normal: style)
    }

    @MainActor
    private func resolveImageSource(_ component: Document.Component, context: ResolutionContext) -> ImageNode.Source? {
        guard let image = component.image else { return nil }

        // SF Symbol
        if let sfSymbolName = image.sfsymbol {
            return .sfsymbol(name: sfSymbolName)
        }

        // Asset catalog
        if let assetName = image.asset {
            return .asset(name: assetName)
        }

        // URL (may be static or dynamic template)
        if let urlString = image.url {
            // Check for template syntax ${...}
            if containsTemplate(urlString) {
                // Track dependencies for reactivity
                let paths = extractTemplatePaths(urlString)
                for path in paths {
                    if context.iterationVariables[path] == nil {
                        context.tracker?.recordRead(path)
                    }
                }
                return .statePath(urlString)
            }

            // Static URL
            if let url = URL(string: urlString) {
                return .url(url)
            }
        }

        return nil
    }

    /// Checks if a string contains template syntax ${...}
    private func containsTemplate(_ string: String) -> Bool {
        return string.contains("${") && string.contains("}")
    }

    /// Extracts state paths from a template string like "https://example.com/${artwork.primaryImage}"
    private func extractTemplatePaths(_ template: String) -> [String] {
        var paths: [String] = []
        let pattern = #"\$\{([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return paths }

        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        for match in matches {
            if let range = Range(match.range(at: 1), in: template) {
                paths.append(String(template[range]))
            }
        }
        return paths
    }

    private func initializeLocalState(on viewNode: ViewNode, from localState: Document.LocalStateDeclaration) {
        var stateDict: [String: Any] = [:]
        for (key, value) in localState.initialValues {
            stateDict[key] = StateValueConverter.unwrap(value)
        }
        viewNode.localState = stateDict
    }
}
