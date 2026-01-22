//
//  FeedbackSurveyExampleView.swift
//  ScalsExamples
//
//  Example view demonstrating the Feedback Survey bottom sheet with custom components.
//

import SwiftUI
import SCALS
import ScalsModules

public struct FeedbackSurveyExampleView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        if let rendererView = ScalsRendererView(
            jsonString: FeedbackSurveyJSON.bottomSheet,
            customComponents: [
                CloseButtonComponent.self
            ]
        ) {
            rendererView
        } else {
            Text("Failed to load view")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Preview

#Preview {
    FeedbackSurveyExampleView()
}
