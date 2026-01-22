//
//  UIKitNodeRendererRegistry+Default.swift
//  ScalsModules
//
//  Provides the default UIKitNodeRendererRegistry with all built-in renderers registered.
//

import SCALS

extension UIKitNodeRendererRegistry {
    /// A registry with all built-in UIKit renderers registered
    public static var `default`: UIKitNodeRendererRegistry {
        let registry = UIKitNodeRendererRegistry()
        registry.registerBuiltInRenderers()
        return registry
    }

    /// Register all built-in UIKit node renderers
    public func registerBuiltInRenderers() {
        register(TextNodeRenderer())
        register(ButtonNodeRenderer())
        register(TextFieldNodeRenderer())
        register(ImageNodeRenderer())
        register(GradientNodeRenderer())
        register(ShapeNodeRenderer())
        register(SpacerNodeRenderer())
        register(DividerNodeRenderer())
        register(PageIndicatorNodeRenderer())
        register(ContainerNodeRenderer())
        register(SectionLayoutNodeRenderer())
    }
}
