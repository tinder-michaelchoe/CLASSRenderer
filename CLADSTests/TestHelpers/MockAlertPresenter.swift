//
//  MockAlertPresenter.swift
//  CLADSTests
//
//  Mock implementation of AlertPresenting for testing.
//

import Foundation
@testable import CLADS

/// Mock implementation of AlertPresenting for testing.
///
/// Captures presented alerts for verification in tests.
///
/// Example usage:
/// ```swift
/// let mockPresenter = MockAlertPresenter()
/// let context = ActionContext(stateStore: store, alertPresenter: mockPresenter, ...)
///
/// // Trigger action that shows alert
/// await context.executeAction(showAlertAction)
///
/// // Verify
/// #expect(mockPresenter.presentedAlerts.count == 1)
/// #expect(mockPresenter.presentedAlerts[0].title == "Success")
/// ```
public final class MockAlertPresenter: AlertPresenting {
    
    /// All alerts that have been presented
    public var presentedAlerts: [AlertConfiguration] = []
    
    /// The last presented alert (convenience)
    public var lastAlert: AlertConfiguration? {
        presentedAlerts.last
    }
    
    public init() {}
    
    public func present(_ config: AlertConfiguration) {
        presentedAlerts.append(config)
    }
    
    /// Reset all captured alerts
    public func reset() {
        presentedAlerts = []
    }
    
    /// Simulate tapping a button on the last alert
    public func tapButton(at index: Int) {
        guard let alert = lastAlert,
              index < alert.buttons.count else { return }
        alert.onButtonTap?(alert.buttons[index].action)
    }
    
    /// Simulate tapping a button with a specific label on the last alert
    public func tapButton(labeled label: String) {
        guard let alert = lastAlert,
              let button = alert.buttons.first(where: { $0.label == label }) else { return }
        alert.onButtonTap?(button.action)
    }
}
