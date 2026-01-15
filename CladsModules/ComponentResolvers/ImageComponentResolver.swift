//
//  ImageComponentResolver.swift
//  CladsModules
//
//  Resolves image components.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves `image` components into ImageNode
public struct ImageComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .image

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let style = context.styleResolver.resolve(component.styleId)
        let nodeId = component.id ?? UUID().uuidString
        let source = resolveImageSource(component, context: context)
        let placeholder = resolvePlaceholder(component)
        let loading = resolveLoading(component)

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .image(ImageNodeData(source: source, placeholder: placeholder, loading: loading, style: style))
            )
            viewNode?.parent = context.parentViewNode
        } else {
            viewNode = nil
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        let renderNode = RenderNode.image(ImageNode(
            id: component.id,
            source: source,
            placeholder: placeholder,
            loading: loading,
            style: style,
            onTap: component.actions?.onTap
        ))

        return ComponentResolutionResult(renderNode: renderNode, viewNode: viewNode)
    }

    // MARK: - Private Helpers

    @MainActor
    private func resolveImageSource(_ component: Document.Component, context: ResolutionContext) -> ImageNode.Source {
        // Check for image property (preferred)
        if let image = component.image {
            // SF Symbol
            if let sfSymbolName = image.sfsymbol {
                return .system(name: sfSymbolName)
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
        }

        // Fallback: Check the data["value"] property for image source (legacy support)
        if let data = component.data?["value"] {
            switch data.type {
            case .static:
                if let value = data.value {
                    // Check for system: prefix for SF Symbols
                    if value.hasPrefix("system:") {
                        return .system(name: String(value.dropFirst(7)))
                    }
                    // Check for url: prefix
                    if value.hasPrefix("url:"), let url = URL(string: String(value.dropFirst(4))) {
                        return .url(url)
                    }
                    // Default to asset
                    return .asset(name: value)
                }
            case .binding:
                // Dynamic binding - track dependency and return statePath
                if let path = data.path {
                    context.tracker?.recordRead(path)
                    return .statePath("${\(path)}")
                }
            case .localBinding:
                break  // Local binding images not supported yet
            }
        }
        return .system(name: "questionmark")
    }
    
    /// Resolves the placeholder image source from the component
    private func resolvePlaceholder(_ component: Document.Component) -> ImageNode.Source? {
        guard let image = component.image, let placeholder = image.placeholder else {
            return nil
        }
        return resolveImagePlaceholder(placeholder)
    }
    
    /// Resolves the loading indicator source from the component
    private func resolveLoading(_ component: Document.Component) -> ImageNode.Source? {
        guard let image = component.image, let loading = image.loading else {
            return nil
        }
        return resolveImagePlaceholder(loading)
    }
    
    /// Resolves an ImagePlaceholder to an ImageNode.Source
    private func resolveImagePlaceholder(_ placeholder: Document.ImagePlaceholder) -> ImageNode.Source? {
        // SF Symbol
        if let sfSymbolName = placeholder.sfsymbol {
            return .system(name: sfSymbolName)
        }
        
        // Asset
        if let assetName = placeholder.asset {
            return .asset(name: assetName)
        }
        
        // URL (static only - no dynamic)
        if let urlString = placeholder.url, let url = URL(string: urlString) {
            return .url(url)
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
