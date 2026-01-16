//
//  ObservableActionContext.swift
//  CladsRendererFramework
//
//  SwiftUI-specific wrapper for ActionContext that provides ObservableObject conformance.
//  This bridges the platform-agnostic ActionContext with SwiftUI's environment system.
//

import SwiftUI
import Combine

/// SwiftUI wrapper for `ActionContext` that provides `ObservableObject` conformance.
///
/// This class wraps the platform-agnostic `ActionContext` to allow it to be used
/// with SwiftUI's `@EnvironmentObject` property wrapper.
///
/// Use this class when injecting `ActionContext` into SwiftUI views:
///
/// ```swift
/// // In your view hierarchy
/// ContentView()
///     .environmentObject(ObservableActionContext(wrapping: actionContext))
///
/// // In child views
/// struct MyView: View {
///     @EnvironmentObject var actionContext: ObservableActionContext
///
///     var body: some View {
///         Button("Tap") {
///             actionContext.execute("myAction")
///         }
///     }
/// }
/// ```
///
/// For non-SwiftUI code, use `ActionContext` directly.
@MainActor
public final class ObservableActionContext: ObservableObject {
    /// The underlying platform-agnostic action context
    public let context: ActionContext
    
    // MARK: - Initialization
    
    /// Wrap an existing ActionContext
    /// - Parameter context: The ActionContext to wrap
    public init(wrapping context: ActionContext) {
        self.context = context
    }
    
    // MARK: - Forwarded Properties
    
    public var stateStore: StateStoring {
        context.stateStore
    }
    
    public var documentId: String {
        context.documentId
    }
    
    public var actionRegistry: ActionRegistry {
        context.actionRegistry
    }
    
    public var actionDelegate: CladsActionDelegate? {
        get { context.actionDelegate }
        set { context.actionDelegate = newValue }
    }
    
    public var dismissHandler: (() -> Void)? {
        get { context.dismissHandler }
        set { context.dismissHandler = newValue }
    }
    
    public var alertHandler: ((AlertConfiguration) -> Void)? {
        get { context.alertHandler }
        set { context.alertHandler = newValue }
    }
    
    public var navigationHandler: ((String, Document.NavigationPresentation?) -> Void)? {
        get { context.navigationHandler }
        set { context.navigationHandler = newValue }
    }
    
    // MARK: - Action Execution
    
    /// Execute an action by its ID
    public func executeAction(id actionId: String) async {
        await context.executeAction(id: actionId)
    }
    
    /// Execute a typed Action directly
    public func executeAction(_ action: Document.Action) async {
        await context.executeAction(action)
    }
    
    /// Execute an action by type and parameters
    public func executeAction(type actionType: String, parameters: ActionParameters) async {
        await context.executeAction(type: actionType, parameters: parameters)
    }
    
    /// Dismiss the current view
    public func dismiss() {
        context.dismiss()
    }
    
    /// Present an alert
    public func presentAlert(_ config: AlertConfiguration) {
        context.presentAlert(config)
    }
    
    /// Navigate to another view
    public func navigate(to destination: String, presentation: Document.NavigationPresentation?) {
        context.navigate(to: destination, presentation: presentation)
    }
    
    /// Execute an action binding (either reference or inline)
    public func execute(_ binding: Document.Component.ActionBinding) {
        context.execute(binding)
    }
    
    /// Execute an action by its ID (convenience for button taps, etc.)
    public func execute(_ actionId: String) {
        context.execute(actionId)
    }
}
