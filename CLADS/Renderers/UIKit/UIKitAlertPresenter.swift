//
//  UIKitAlertPresenter.swift
//  CladsRendererFramework
//
//  UIKit-specific implementation of AlertPresenting.
//

import UIKit

// MARK: - UIKit Alert Presenter

/// Default UIKit implementation of AlertPresenting.
/// Uses UIAlertController to present alerts.
public final class UIKitAlertPresenter: AlertPresenting {

    public init() {}

    public func present(_ config: AlertConfiguration) {
        // Ensure we're on the main thread for UIKit operations
        if Thread.isMainThread {
            presentOnMainThread(config)
        } else {
            DispatchQueue.main.async { [self] in
                presentOnMainThread(config)
            }
        }
    }
    
    private func presentOnMainThread(_ config: AlertConfiguration) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        let alert = UIAlertController(
            title: config.title,
            message: config.message,
            preferredStyle: .alert
        )

        for button in config.buttons {
            let style: UIAlertAction.Style
            switch button.style {
            case .default: style = .default
            case .cancel: style = .cancel
            case .destructive: style = .destructive
            }

            let action = UIAlertAction(title: button.label, style: style) { _ in
                config.onButtonTap?(button.action)
            }
            alert.addAction(action)
        }

        topController.present(alert, animated: true)
    }
}

// MARK: - Legacy Support

/// Legacy static interface for backward compatibility.
/// Prefer using UIKitAlertPresenter instance for new code.
public enum AlertPresenter {
    public static func present(_ config: AlertConfiguration) {
        UIKitAlertPresenter().present(config)
    }
}
