//
//  ActionExecutor.swift
//  ScalsRendererFramework
//
//  Platform-agnostic action execution context.
//  UIKit-specific alert presentation is handled via the AlertPresenting protocol.
//

import Foundation

/// Context for action execution, providing access to state and navigation.
///
/// **Platform-Agnostic**: This class does not depend on SwiftUI, UIKit, or Combine.
/// Alert presentation is delegated to an `AlertPresenting` implementation.
/// For SwiftUI integration, use `ObservableActionContext` wrapper.
public final class ActionContext: ActionExecutionContext {
    public let stateStore: StateStoring
    public let documentId: String
    public let actionRegistry: ActionRegistry
    private let actionDefinitions: [String: Document.Action]

    /// Alert presenter for showing alerts (injectable for testing)
    private let alertPresenter: AlertPresenting?

    /// Delegate for handling custom actions
    public weak var actionDelegate: ScalsActionDelegate?

    /// Callback to dismiss the current view
    public var dismissHandler: (() -> Void)?

    /// Callback to present an alert (legacy - prefer alertPresenter)
    public var alertHandler: ((AlertConfiguration) -> Void)?

    /// Callback for navigation
    public var navigationHandler: ((String, Document.NavigationPresentation?) -> Void)?

    public init(
        stateStore: StateStoring,
        actionDefinitions: [String: Document.Action],
        registry: ActionRegistry,
        documentId: String = UUID().uuidString,
        actionDelegate: ScalsActionDelegate? = nil,
        alertPresenter: AlertPresenting? = nil
    ) {
        self.stateStore = stateStore
        self.actionDefinitions = actionDefinitions
        self.actionRegistry = registry
        self.documentId = documentId
        self.actionDelegate = actionDelegate
        self.alertPresenter = alertPresenter
    }

    // MARK: - ActionExecutionContext

    /// Execute an action by its ID.
    ///
    /// Resolution order:
    /// 1. Document action definitions (to get type + parameters)
    /// 2. Action delegate (for intercepting, with parameters)
    /// 3. Execute the action
    ///
    /// The action definition determines the action type and parameters,
    /// which are then passed to `executeAction(type:parameters:)` for registry lookup.
    public func executeAction(id actionId: String) async {
        // 1. Look up action definition to get type + parameters
        guard let action = actionDefinitions[actionId] else {
            print("ActionContext: Unknown action '\(actionId)'")
            return
        }

        // 2. Check delegate (for intercepting, with parameters extracted from action)
        if let delegate = actionDelegate {
            let parameters = extractParameters(from: action)
            let handled = await delegate.cladsRenderer(
                handleAction: actionId,
                parameters: parameters,
                context: self
            )
            if handled { return }
        }

        // 3. Execute the action
        await executeAction(action)
    }

    /// Extract parameters from an action for delegate calls
    private func extractParameters(from action: Document.Action) -> ActionParameters {
        switch action {
        case .custom(let customAction):
            return ActionParameters(raw: customAction.parameters.mapValues { stateValueToAny($0) })
        default:
            return ActionParameters(raw: [:])
        }
    }

    /// Execute a typed Action directly
    public func executeAction(_ action: Document.Action) async {
        switch action {
        case .dismiss:
            dismiss()

        case .setState(let setStateAction):
            executeSetState(setStateAction)

        case .toggleState(let toggleStateAction):
            executeToggleState(toggleStateAction)

        case .showAlert(let showAlertAction):
            executeShowAlert(showAlertAction)

        case .navigate(let navigateAction):
            navigate(to: navigateAction.destination, presentation: navigateAction.presentation)

        case .sequence(let sequenceAction):
            for step in sequenceAction.steps {
                await executeAction(step)
            }

        case .custom(let customAction):
            // Fall back to registry-based handling for custom actions
            let parameters = ActionParameters(raw: customAction.parameters.mapValues { stateValueToAny($0) })
            await executeAction(type: customAction.type, parameters: parameters)
        }
    }

    /// Execute an action directly by type and parameters.
    ///
    /// Resolution order:
    /// 1. Registry handlers (includes custom actions wrapped as ClosureActionHandler)
    /// 2. Action delegate
    public func executeAction(type actionType: String, parameters: ActionParameters) async {
        // 1. Check registry handlers first (includes ClosureActionHandler for custom actions)
        if let handler = actionRegistry.handler(for: actionType) {
            await handler.execute(parameters: parameters, context: self)
            return
        }

        // 2. Check delegate
        if let delegate = actionDelegate {
            let handled = await delegate.cladsRenderer(
                handleAction: actionType,
                parameters: parameters,
                context: self
            )
            if handled { return }
        }

        print("ActionContext: No handler registered for action type '\(actionType)'")
    }

    // MARK: - Action Execution Helpers

    private func executeSetState(_ action: Document.SetStateAction) {
        let value: Any
        switch action.value {
        case .literal(let stateValue):
            value = stateValueToAny(stateValue)
        case .expression(let expr):
            value = stateStore.evaluate(expression: expr)
        }
        stateStore.set(action.path, value: value)
    }

    private func executeToggleState(_ action: Document.ToggleStateAction) {
        let currentValue = stateStore.get(action.path) as? Bool ?? false
        stateStore.set(action.path, value: !currentValue)
    }

    private func executeShowAlert(_ action: Document.ShowAlertAction) {
        let message: String?
        if let msgContent = action.message {
            switch msgContent {
            case .static(let str):
                message = str
            case .template(let template):
                message = stateStore.interpolate(template)
            }
        } else {
            message = nil
        }

        let buttons = (action.buttons ?? []).map { button in
            AlertConfiguration.Button(
                label: button.label,
                style: button.style ?? .default,
                action: button.action
            )
        }

        let config = AlertConfiguration(
            title: action.title,
            message: message,
            buttons: buttons.isEmpty ? [AlertConfiguration.Button(label: "OK", style: .default, action: nil)] : buttons,
            onButtonTap: { [weak self] actionId in
                if let actionId = actionId {
                    self?.execute(actionId)
                }
            }
        )

        presentAlert(config)
    }

    private func stateValueToAny(_ value: Document.StateValue) -> Any {
        switch value {
        case .intValue(let v): return v
        case .doubleValue(let v): return v
        case .stringValue(let v): return v
        case .boolValue(let v): return v
        case .nullValue: return NSNull()
        case .arrayValue(let arr): return arr.map { stateValueToAny($0) }
        case .objectValue(let obj): return obj.mapValues { stateValueToAny($0) }
        }
    }

    /// Dismiss the current view
    public func dismiss() {
        dismissHandler?()
    }

    /// Present an alert using the injected alert presenter
    public func presentAlert(_ config: AlertConfiguration) {
        // Use legacy handler if set, otherwise use injected presenter
        if let handler = alertHandler {
            handler(config)
        } else {
            alertPresenter?.present(config)
        }
    }

    /// Navigate to another view
    public func navigate(to destination: String, presentation: Document.NavigationPresentation?) {
        navigationHandler?(destination, presentation)
    }

    // MARK: - Convenience Execution

    /// Execute an action binding (either reference or inline)
    public func execute(_ binding: Document.Component.ActionBinding) {
        Task {
            switch binding {
            case .reference(let actionId):
                await executeAction(id: actionId)
            case .inline(let action):
                await executeAction(action)
            }
        }
    }

    /// Execute an action by its ID (convenience for button taps, etc.)
    public func execute(_ actionId: String) {
        Task {
            await executeAction(id: actionId)
        }
    }
}

/// Configuration for presenting an alert
public struct AlertConfiguration {
    public let title: String
    public let message: String?
    public let buttons: [Button]
    public let onButtonTap: ((String?) -> Void)?

    public struct Button {
        public let label: String
        public let style: Document.AlertButtonStyle
        public let action: String?

        public init(label: String, style: Document.AlertButtonStyle, action: String?) {
            self.label = label
            self.style = style
            self.action = action
        }
    }

    public init(
        title: String,
        message: String?,
        buttons: [Button],
        onButtonTap: ((String?) -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.buttons = buttons
        self.onButtonTap = onButtonTap
    }
}

// MARK: - Alert Presenting Protocol

/// Protocol for presenting alerts, enabling dependency injection for testing.
///
/// **Platform-Agnostic**: This protocol does not depend on UIKit or SwiftUI.
/// Platform-specific implementations (like `UIKitAlertPresenter`) are in the renderer layer.
///
/// Example test usage:
/// ```swift
/// class MockAlertPresenter: AlertPresenting {
///     var presentedAlerts: [AlertConfiguration] = []
///     func present(_ config: AlertConfiguration) {
///         presentedAlerts.append(config)
///     }
/// }
///
/// let mockPresenter = MockAlertPresenter()
/// let context = ActionContext(stateStore: store, alertPresenter: mockPresenter, ...)
/// // ... trigger action ...
/// XCTAssertEqual(mockPresenter.presentedAlerts.count, 1)
/// ```
public protocol AlertPresenting: AnyObject {
    func present(_ config: AlertConfiguration)
}
