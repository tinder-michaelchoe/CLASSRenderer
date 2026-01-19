//
//  ComponentResolverRegistry.swift
//  CladsRendererFramework
//
//  Registry for component resolvers. Allows extensible component resolution.
//

import Foundation

/// Registry that maps component kinds to their resolvers.
///
/// This allows new component types to be added without modifying the core Resolver.
/// Also supports custom components registered via `CustomComponentRegistry`.
///
/// Usage:
/// ```swift
/// let registry = ComponentResolverRegistry()
/// registry.register(TextComponentResolver())
/// // ... register other resolvers
///
/// // For custom components:
/// let customRegistry = CustomComponentRegistry()
/// customRegistry.register(MyCustomComponent.self)
/// registry.setCustomComponentRegistry(customRegistry)
///
/// let result = try registry.resolve(component, context: context)
/// ```
public final class ComponentResolverRegistry {

    // MARK: - Storage

    private var resolvers: [Document.ComponentKind: any ComponentResolving] = [:]
    #if !arch(wasm32)
    private var customComponentRegistry: CustomComponentRegistry?
    private var customComponentResolver: CustomComponentResolver?
    #endif

    // MARK: - Initialization

    public init() {}

    // MARK: - Custom Component Support

    #if !arch(wasm32)
    /// Set the custom component registry for resolving custom components
    public func setCustomComponentRegistry(_ registry: CustomComponentRegistry) {
        self.customComponentRegistry = registry
        self.customComponentResolver = CustomComponentResolver(registry: registry)
    }
    #endif

    // MARK: - Registration

    /// Registers a component resolver
    /// - Parameter resolver: The resolver to register
    public func register<T: ComponentResolving>(_ resolver: T) {
        resolvers[T.componentKind] = resolver
    }

    /// Unregisters a resolver for a component kind
    /// - Parameter kind: The component kind to unregister
    public func unregister(_ kind: Document.ComponentKind) {
        resolvers.removeValue(forKey: kind)
    }

    // MARK: - Resolution

    /// Resolves a component using the appropriate registered resolver
    /// - Parameters:
    ///   - component: The component to resolve
    ///   - context: The resolution context
    /// - Returns: The resolution result
    /// - Throws: `ComponentResolutionError.unknownKind` if no resolver is registered
    @MainActor
    public func resolve(
        _ component: Document.Component,
        context: ResolutionContext
    ) throws -> ComponentResolutionResult {
        // Try built-in resolvers first
        if let resolver = resolvers[component.type] {
            return try resolver.resolve(component, context: context)
        }

        #if !arch(wasm32)
        // Fall back to custom component resolver
        if let customResolver = customComponentResolver,
           customResolver.canResolve(component.type) {
            return try customResolver.resolve(component, context: context)
        }
        #endif

        throw ComponentResolutionError.unknownKind(component.type)
    }

    /// Checks if a resolver is registered for a component kind
    /// - Parameter kind: The component kind to check
    /// - Returns: true if a resolver is registered (built-in or custom)
    public func hasResolver(for kind: Document.ComponentKind) -> Bool {
        if resolvers[kind] != nil {
            return true
        }
        #if !arch(wasm32)
        if let customResolver = customComponentResolver {
            return customResolver.canResolve(kind)
        }
        #endif
        return false
    }

    /// Returns all registered component kinds
    public var registeredKinds: [Document.ComponentKind] {
        Array(resolvers.keys)
    }

}

// MARK: - Errors

/// Errors that can occur during component resolution
public enum ComponentResolutionError: Error, LocalizedError {
    case unknownKind(Document.ComponentKind)

    public var errorDescription: String? {
        switch self {
        case .unknownKind(let kind):
            return "No resolver registered for component kind: \(kind.rawValue)"
        }
    }
}
