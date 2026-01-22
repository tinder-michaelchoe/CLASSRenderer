//
//  SwiftUINodeRendererRegistry+Default.swift
//  ScalsModules
//
//  Provides the default SwiftUINodeRendererRegistry with all built-in renderers registered.
//

import SCALS

extension SwiftUINodeRendererRegistry {
    /// A registry with all built-in SwiftUI renderers registered
    public static var `default`: SwiftUINodeRendererRegistry {
        let registry = SwiftUINodeRendererRegistry()
        registry.registerBuiltInRenderers()
        return registry
    }

    /// Register all built-in SwiftUI node renderers
    public func registerBuiltInRenderers() {
        register(TextNodeSwiftUIRenderer())
        register(ButtonNodeSwiftUIRenderer())
        register(TextFieldNodeSwiftUIRenderer())
        register(ToggleNodeSwiftUIRenderer())
        register(SliderNodeSwiftUIRenderer())
        register(ImageNodeSwiftUIRenderer())
        register(GradientNodeSwiftUIRenderer())
        register(ShapeNodeSwiftUIRenderer())
        register(SpacerNodeSwiftUIRenderer())
        register(DividerNodeSwiftUIRenderer())
        register(PageIndicatorNodeSwiftUIRenderer())
        register(ContainerNodeSwiftUIRenderer())
        register(SectionLayoutNodeSwiftUIRenderer())
    }
}
