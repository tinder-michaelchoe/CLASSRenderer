//
//  ActionRegistry.swift
//  ScalsRendererFramework
//

import Foundation
#if !arch(wasm32)
import Dispatch
#endif

// MARK: - Action Registry

/// Registry for action handlers
/// Allows registering custom action types that can be executed by the renderer
public final class ActionRegistry: @unchecked Sendable {

    private var handlers: [String: any ActionHandler] = [:]
    #if !arch(wasm32)
    private let queue = DispatchQueue(label: "com.cladsrenderer.actionregistry")
    #endif

    public init() {}

    /// Create a copy of this registry with additional custom action closures merged in.
    ///
    /// - Parameter customActions: Dictionary of action closures keyed by action type
    /// - Returns: A new ActionRegistry containing all handlers from this registry plus the custom actions
    public func merging(customActions: [String: ActionClosure]) -> ActionRegistry {
        let merged = ActionRegistry()
        #if arch(wasm32)
        // Wasm is single-threaded, no synchronization needed
        merged.handlers = self.handlers
        for (actionType, closure) in customActions {
            merged.handlers[actionType] = ClosureActionHandler(actionType: actionType, closure: closure)
        }
        #else
        queue.sync {
            // Copy existing handlers
            merged.handlers = self.handlers

            // Wrap closures as ClosureActionHandler and add them
            for (actionType, closure) in customActions {
                merged.handlers[actionType] = ClosureActionHandler(actionType: actionType, closure: closure)
            }
        }
        #endif
        return merged
    }

    /// Register an action handler
    /// - Parameter handler: The handler instance to register
    public func register(_ handler: any ActionHandler) {
        #if arch(wasm32)
        handlers[type(of: handler).actionType] = handler
        #else
        queue.sync {
            handlers[type(of: handler).actionType] = handler
        }
        #endif
    }


    /// Register an action closure directly
    /// - Parameters:
    ///   - actionType: The action type identifier
    ///   - closure: The closure to execute for this action
    public func registerClosure(_ actionType: String, closure: @escaping ActionClosure) {
        #if arch(wasm32)
        handlers[actionType] = ClosureActionHandler(actionType: actionType, closure: closure)
        #else
        queue.sync {
            handlers[actionType] = ClosureActionHandler(actionType: actionType, closure: closure)
        }
        #endif
    }

    /// Get a handler for the given action type
    /// - Parameter actionType: The action type identifier
    /// - Returns: The registered handler, or nil if not found
    public func handler(for actionType: String) -> (any ActionHandler)? {
        #if arch(wasm32)
        return handlers[actionType]
        #else
        queue.sync {
            handlers[actionType]
        }
        #endif
    }

    /// Check if a handler is registered for the given action type
    public func hasHandler(for actionType: String) -> Bool {
        #if arch(wasm32)
        return handlers[actionType] != nil
        #else
        queue.sync {
            handlers[actionType] != nil
        }
        #endif
    }

    /// Get a handler that supports cancellation
    /// - Parameter actionType: The action type identifier
    /// - Returns: The registered handler if it conforms to CancellableActionHandler, or nil
    public func getCancellableHandler(for actionType: String) -> CancellableActionHandler? {
        #if arch(wasm32)
        return handlers[actionType] as? CancellableActionHandler
        #else
        queue.sync {
            handlers[actionType] as? CancellableActionHandler
        }
        #endif
    }
}

// MARK: - Closure Action Handler

/// An ActionHandler that wraps a closure.
/// This allows closures to be stored uniformly with other ActionHandler types.
public struct ClosureActionHandler: ActionHandler {
    public let actionType: String
    private let closure: ActionClosure

    public static var actionType: String { "" } // Not used, instance property is used instead

    public init(actionType: String, closure: @escaping ActionClosure) {
        self.actionType = actionType
        self.closure = closure
    }

    @MainActor
    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        await closure(parameters, context)
    }
}
