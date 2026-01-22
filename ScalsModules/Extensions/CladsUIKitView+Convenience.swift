//
//  ScalsUIKitView+Convenience.swift
//  ScalsModules
//
//  Convenience initializers for ScalsUIKitView and ScalsViewController that use default registries.
//  Custom actions are merged into the action registry internally.
//

import SCALS
import UIKit

extension ScalsUIKitView {
    /// Initialize with a document using default registries.
    ///
    /// - Parameters:
    ///   - document: The document definition to render
    ///   - customActions: View-specific action closures, keyed by action ID
    ///   - actionDelegate: Delegate for handling custom actions
    ///
    /// Example:
    /// ```swift
    /// let view = ScalsUIKitView(document: document)
    ///
    /// // With custom actions
    /// let view = ScalsUIKitView(
    ///     document: document,
    ///     customActions: [
    ///         "submitOrder": { params, context in
    ///             await OrderService.submit(orderId)
    ///         }
    ///     ]
    /// )
    /// ```
    public convenience init(
        document: Document.Definition,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: ScalsActionDelegate? = nil
    ) {
        // Merge custom actions into the registry
        let registry = ActionRegistry.default.merging(customActions: customActions)

        self.init(
            document: document,
            actionRegistry: registry,
            componentRegistry: .default,
            rendererRegistry: .default,
            actionDelegate: actionDelegate
        )
    }

    /// Initialize from a JSON string using default registries.
    public convenience init?(
        jsonString: String,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: ScalsActionDelegate? = nil
    ) {
        guard let document = try? Document.Definition(jsonString: jsonString) else {
            return nil
        }

        // Merge custom actions into the registry
        let registry = ActionRegistry.default.merging(customActions: customActions)

        self.init(
            document: document,
            actionRegistry: registry,
            componentRegistry: .default,
            rendererRegistry: .default,
            actionDelegate: actionDelegate
        )
    }
}

// MARK: - ScalsViewController Convenience

extension ScalsViewController {
    /// Initialize with a document using default registries.
    public convenience init(document: Document.Definition) {
        self.init(
            document: document,
            actionRegistry: .default,
            componentRegistry: .default,
            rendererRegistry: .default
        )
    }

    /// Initialize from a JSON string using default registries.
    public convenience init?(jsonString: String) {
        self.init(
            jsonString: jsonString,
            actionRegistry: .default,
            componentRegistry: .default,
            rendererRegistry: .default
        )
    }
}
