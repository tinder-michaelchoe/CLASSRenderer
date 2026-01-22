//
//  ComponentResolverRegistry+Default.swift
//  ScalsModules
//
//  Provides the default ComponentResolverRegistry with all built-in resolvers registered.
//

import SCALS

extension ComponentResolverRegistry {
    /// A registry with all built-in component resolvers registered
    public static var `default`: ComponentResolverRegistry {
        let registry = ComponentResolverRegistry()
        registry.registerBuiltInResolvers()
        return registry
    }

    /// Register all built-in component resolvers
    public func registerBuiltInResolvers() {
        register(TextComponentResolver())
        register(ButtonComponentResolver())
        register(TextFieldComponentResolver())
        register(ToggleComponentResolver())
        register(SliderComponentResolver())
        register(ImageComponentResolver())
        register(GradientComponentResolver())
        register(ShapeComponentResolver())
        register(DividerComponentResolver())
        register(PageIndicatorComponentResolver())
    }
}
