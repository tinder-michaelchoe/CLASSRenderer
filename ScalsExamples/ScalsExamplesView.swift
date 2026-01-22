//
//  ContentView.swift
//  StaticExamples
//
//  Created by mexicanpizza on 12/23/25.
//

import SCALS
import ScalsModules
import SwiftUI

public struct ScalsExamplesView: View {

    @State private var selectedExample: Example?
    @State private var fullScreenExample: Example?
    @State private var jsonViewerExample: Example?

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // SCALS Categories
                Section("C - Components") {
                    ForEach(Example.componentExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("L - Layouts") {
                    ForEach(Example.layoutExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("A - Actions") {
                    ForEach(Example.actionExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("D - Data") {
                    ForEach(Example.dataExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("S - Styles") {
                    ForEach(Example.styleExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("Complex Examples") {
                    ForEach(Example.complexExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("Custom Components") {
                    ForEach(Example.customComponentExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }
            }
            .navigationTitle("SCALS Examples")
            .sheet(item: $selectedExample) { example in
                Group {
                    switch example {
                    case .dadJokes:
                        DadJokesExampleView()
                    case .taskManager:
                        TaskManagerExampleView()
                    case .photoTouchUp:
                        PhotoTouchUpExampleView()
                    case .feedbackSurvey:
                        FeedbackSurveyExampleView()
                    case .designSystem:
                        DesignSystemExampleView()
                    default:
                        ExampleSheetView(example: example)
                    }
                }
                .modifier(PresentationStyleModifier(style: example.presentation))
            }
            .fullScreenCover(item: $fullScreenExample) { example in
                switch example {
                case .dadJokes:
                    DadJokesExampleView()
                case .taskManager:
                    TaskManagerExampleView()
                case .doubleDate:
                    ExampleSheetView(example: example)
                default:
                    ExampleSheetView(example: example)
                }
            }
            .sheet(item: $jsonViewerExample) { example in
                JSONViewerSheet(example: example)
            }
        }
    }
}

// MARK: - JSON Viewer Sheet

struct JSONViewerSheet: View {
    let example: Example
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let fileSize = example.fileSizeFormatted {
                    HStack {
                        Text("File Size:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(fileSize)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemBackground))
                }

                ScrollView {
                    if let json = example.json {
                        Text(formatJSON(json))
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    } else {
                        Text("No JSON available for this example")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle(example.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                if example.json != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if let json = example.json {
                                UIPasteboard.general.string = json
                            }
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func formatJSON(_ json: String) -> String {
        // Try to pretty-print the JSON
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return json
        }
        return prettyString
    }
}

struct ExampleRow: View {
    let example: Example
    @Binding var selectedExample: Example?
    @Binding var fullScreenExample: Example?
    @Binding var jsonViewerExample: Example?

    var body: some View {
        Button {
            if case .fullScreen = example.presentation {
                fullScreenExample = example
            } else {
                selectedExample = example
            }
        } label: {
            HStack {
                Image(systemName: example.icon)
                    .foregroundStyle(example.iconColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(example.title)
                        .foregroundColor(Color(uiColor: .label))
                    if let subtitle = example.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    if let fileSize = example.fileSizeFormatted {
                        Text(fileSize)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .contextMenu {
            if example.json != nil {
                Button {
                    jsonViewerExample = example
                } label: {
                    Label("View JSON", systemImage: "curlybraces")
                }

                Button {
                    if let json = example.json {
                        UIPasteboard.general.string = json
                    }
                } label: {
                    Label("Copy JSON", systemImage: "doc.on.doc")
                }
            }
        }
    }
}

// MARK: - Presentation Style

enum PresentationStyle: Equatable {
    /// Standard detent (.medium, .large, or custom fraction/height)
    case detent(PresentationDetent)
    /// Fixed height in points
    case fixed(height: CGFloat)
    /// Automatically sizes to fit content
    case autoSize
    /// Full sheet size (large detent)
    case fullSize
    /// Full screen cover (no sheet chrome)
    case fullScreen

    var label: String {
        switch self {
        case .detent(let detent):
            if detent == .medium { return "Detent: Medium" }
            if detent == .large { return "Detent: Large" }
            return "Detent"
        case .fixed(let height): return "\(Int(height))pt"
        case .autoSize: return "Auto"
        case .fullSize: return "Full"
        case .fullScreen: return "Screen"
        }
    }
}

// MARK: - Example Enum

enum Example: String, CaseIterable, Identifiable {
    // Components (C)
    case labels
    case buttons
    case textFields
    case toggles
    case sliders
    case images
    case gradients
    case shapes

    // Layouts (L)
    case vstackHstack
    case zstack
    case nested
    case alignment
    case sectionLayout
    case sectionLayoutList
    case sectionLayoutGrid
    case sectionLayoutFlow
    case sectionLayoutHorizontal

    // Actions (A)
    case setState
    case toggleState
    case showAlert
    case dismiss
    case navigate
    case sequence
    case arrayActions
    case httpRequest

    // Data (D)
    case staticData
    case bindingData
    case expressions

    // Styles (S)
    case basicStyles
    case styleInheritance
    case conditionalStyles

    // Complex Examples (Combining SCALS Elements)
    case dadJokes
    case taskManager
    case shoppingCart
    case musicPlayer
    case metMuseum
    case weatherDashboard
    case plantCareTracker
    case designSystem

    // Custom Components
    case photoTouchUp
    case feedbackSurvey
    case doubleDate

    var id: String { rawValue }

    var title: String {
        switch self {
        // Components
        case .labels: return "Labels"
        case .buttons: return "Buttons"
        case .textFields: return "Text Fields"
        case .toggles: return "Toggles"
        case .sliders: return "Sliders"
        case .images: return "Images"
        case .gradients: return "Gradients"
        case .shapes: return "Shapes"
        // Layouts
        case .vstackHstack: return "VStack & HStack"
        case .zstack: return "ZStack"
        case .nested: return "Nested"
        case .alignment: return "Alignment"
        case .sectionLayout: return "Section Layout"
        case .sectionLayoutList: return "Section: List"
        case .sectionLayoutGrid: return "Section: Grid"
        case .sectionLayoutFlow: return "Section: Flow"
        case .sectionLayoutHorizontal: return "Section: Horizontal"
        // Actions
        case .setState: return "Set State"
        case .toggleState: return "Toggle State"
        case .showAlert: return "Show Alert"
        case .dismiss: return "Dismiss"
        case .navigate: return "Navigate"
        case .sequence: return "Sequence Actions"
        case .arrayActions: return "Array Actions"
        case .httpRequest: return "HTTP Request"
        // Data
        case .staticData: return "Static Data"
        case .bindingData: return "Binding Data"
        case .expressions: return "Expressions"
        // Styles
        case .basicStyles: return "Basic Styles"
        case .styleInheritance: return "Style Inheritance"
        case .conditionalStyles: return "Conditional Styles"
        // Complex
        case .dadJokes: return "Dad Jokes"
        case .taskManager: return "Task Manager"
        case .shoppingCart: return "Shopping Cart"
        case .musicPlayer: return "Music Player"
        case .metMuseum: return "Met Museum"
        case .weatherDashboard: return "Weather Dashboard"
        case .plantCareTracker: return "Plant Care Tracker"
        case .designSystem: return "Design System"
        // Custom Components
        case .photoTouchUp: return "Photo Touch Up"
        case .feedbackSurvey: return "Feedback Survey"
        case .doubleDate: return "Double Date"
        }
    }

    var subtitle: String? {
        switch self {
        // Components
        case .labels: return "Text display with styles"
        case .buttons: return "Tappable actions"
        case .textFields: return "User input"
        case .toggles: return "Boolean switches"
        case .sliders: return "Range selection"
        case .images: return "SF Symbols, assets, URLs, dynamic & spinners"
        case .gradients: return "Color transitions"
        case .shapes: return "Rectangle, circle, capsule, ellipse"
        // Layouts
        case .vstackHstack: return "Vertical & horizontal stacks"
        case .zstack: return "Layered overlays"
        case .nested: return "VStack with nested HStack"
        case .alignment: return "All alignment options for containers"
        case .sectionLayout: return "Combined section layouts"
        case .sectionLayoutList: return "Vertical list with dividers"
        case .sectionLayoutGrid: return "Multi-column grid"
        case .sectionLayoutFlow: return "Wrapping flow layout"
        case .sectionLayoutHorizontal: return "Carousel & card paging"
        // Actions
        case .setState: return "Update state values"
        case .toggleState: return "Toggle boolean state"
        case .showAlert: return "Display alert dialogs"
        case .dismiss: return "Close the view"
        case .navigate: return "Push new screens"
        case .sequence: return "Chain multiple actions"
        case .arrayActions: return "Add/remove array items"
        case .httpRequest: return "POST/PUT/PATCH/DELETE requests"
        // Data
        case .staticData: return "Fixed values"
        case .bindingData: return "Two-way state binding"
        case .expressions: return "Arithmetic, templates, arrays, ternary & cycling"
        // Styles
        case .basicStyles: return "Font, color, spacing"
        case .styleInheritance: return "Multi-level chains, overrides & reuse"
        case .conditionalStyles: return "State-based styling"
        // Complex
        case .dadJokes: return "Custom actions with REST API"
        case .taskManager: return "Dynamic task list with state"
        case .shoppingCart: return "E-commerce cart with promo codes"
        case .musicPlayer: return "Player controls, queue & progress"
        case .metMuseum: return "Explore artwork via GET API"
        case .weatherDashboard: return "Weather with custom action & gradients"
        case .plantCareTracker: return "Plant status cards with shapes and style inheritance"
        case .designSystem: return "Lightspeed design system"
        // Custom Components
        case .photoTouchUp: return "Before/after photo comparison with custom components"
        case .feedbackSurvey: return "Radio button survey with dismiss and alert"
        case .doubleDate: return "Onboarding with gradient background and hero image"
        }
    }

    var icon: String {
        switch self {
        // Components
        case .labels: return "textformat"
        case .buttons: return "hand.tap"
        case .textFields: return "character.cursor.ibeam"
        case .toggles: return "switch.2"
        case .sliders: return "slider.horizontal.3"
        case .images: return "photo"
        case .gradients: return "paintbrush"
        case .shapes: return "circle.square"
        // Layouts
        case .vstackHstack: return "square.split.2x1"
        case .zstack: return "square.stack"
        case .nested: return "rectangle.on.rectangle"
        case .alignment: return "arrow.up.left.and.arrow.down.right"
        case .sectionLayout: return "rectangle.split.3x1"
        case .sectionLayoutList: return "list.bullet"
        case .sectionLayoutGrid: return "square.grid.2x2"
        case .sectionLayoutFlow: return "rectangle.3.group"
        case .sectionLayoutHorizontal: return "scroll"
        // Actions
        case .setState: return "arrow.right.circle"
        case .toggleState: return "arrow.triangle.swap"
        case .showAlert: return "exclamationmark.bubble"
        case .dismiss: return "xmark.circle"
        case .navigate: return "arrow.right.square"
        case .sequence: return "list.number"
        case .arrayActions: return "plus.slash.minus"
        case .httpRequest: return "network"
        // Data
        case .staticData: return "doc.text"
        case .bindingData: return "link"
        case .expressions: return "function"
        // Styles
        case .basicStyles: return "paintpalette"
        case .styleInheritance: return "arrow.up.right.circle"
        case .conditionalStyles: return "questionmark.diamond"
        // Complex
        case .dadJokes: return "face.smiling"
        case .taskManager: return "checklist"
        case .shoppingCart: return "cart.fill"
        case .musicPlayer: return "music.note.list"
        case .metMuseum: return "building.columns"
        case .weatherDashboard: return "cloud.sun.fill"
        case .plantCareTracker: return "leaf.fill"
        case .designSystem: return "sparkles"
        // Custom Components
        case .photoTouchUp: return "wand.and.stars"
        case .feedbackSurvey: return "text.bubble"
        case .doubleDate: return "person.2.fill"
        }
    }

    var iconColor: Color {
        switch self {
        // Components - Blue shades
        case .labels: return .blue
        case .buttons: return .blue
        case .textFields: return .blue
        case .toggles: return .blue
        case .sliders: return .blue
        case .images: return .blue
        case .gradients: return .blue
        case .shapes: return .blue
        // Layouts - Purple shades
        case .vstackHstack: return .purple
        case .zstack: return .purple
        case .nested: return .purple
        case .alignment: return .purple
        case .sectionLayout: return .purple
        case .sectionLayoutList: return .purple
        case .sectionLayoutGrid: return .purple
        case .sectionLayoutFlow: return .purple
        case .sectionLayoutHorizontal: return .purple
        // Actions - Orange shades
        case .setState: return .orange
        case .toggleState: return .orange
        case .showAlert: return .orange
        case .dismiss: return .orange
        case .navigate: return .orange
        case .sequence: return .orange
        case .arrayActions: return .orange
        case .httpRequest: return .orange
        // Data - Green shades
        case .staticData: return .green
        case .bindingData: return .green
        case .expressions: return .green
        // Styles - Pink shades
        case .basicStyles: return .pink
        case .styleInheritance: return .pink
        case .conditionalStyles: return .pink
        // Complex - Teal/Indigo
        case .dadJokes: return .yellow
        case .taskManager: return .indigo
        case .shoppingCart: return .teal
        case .musicPlayer: return .teal
        case .metMuseum: return Color(red: 0.77, green: 0.12, blue: 0.23) // Met Museum red
        case .weatherDashboard: return .cyan
        case .plantCareTracker: return .green
        // Styles - Pink shades
        case .designSystem: return .pink
        // Custom Components - Coral
        case .photoTouchUp: return Color(red: 0.99, green: 0.35, blue: 0.37)
        case .feedbackSurvey: return Color(red: 0.99, green: 0.35, blue: 0.37)
        case .doubleDate: return Color(red: 0.99, green: 0.35, blue: 0.37)
        }
    }

    var json: String? {
        switch self {
        // Components
        case .labels: return labelsJSON
        case .buttons: return buttonsJSON
        case .textFields: return textFieldsJSON
        case .toggles: return togglesJSON
        case .sliders: return slidersJSON
        case .images: return imagesJSON
        case .gradients: return gradientsJSON
        case .shapes: return shapesJSON
        // Layouts
        case .vstackHstack: return vstackHstackJSON
        case .zstack: return zstackJSON
        case .nested: return nestedJSON
        case .alignment: return alignmentJSON
        case .sectionLayout: return sectionLayoutJSON
        case .sectionLayoutList: return sectionListJSON
        case .sectionLayoutGrid: return sectionGridJSON
        case .sectionLayoutFlow: return sectionFlowJSON
        case .sectionLayoutHorizontal: return sectionHorizontalJSON
        // Actions
        case .setState: return setStateJSON
        case .toggleState: return toggleStateJSON
        case .showAlert: return showAlertJSON
        case .dismiss: return dismissJSON
        case .navigate: return navigateJSON
        case .sequence: return sequenceJSON
        case .arrayActions: return arrayActionsJSON
        case .httpRequest: return httpRequestJSON
        // Data
        case .staticData: return staticDataJSON
        case .bindingData: return bindingDataJSON
        case .expressions: return expressionsJSON
        // Styles
        case .basicStyles: return basicStylesJSON
        case .styleInheritance: return styleInheritanceJSON
        case .conditionalStyles: return conditionalStylesJSON
        // Complex
        case .dadJokes: return dadJokesJSON
        case .taskManager: return taskManagerJSON
        case .shoppingCart: return shoppingCartJSON
        case .musicPlayer: return musicPlayerJSON
        case .metMuseum: return metMuseumJSON
        case .weatherDashboard: return weatherDashboardJSON
        case .plantCareTracker: return plantCareTrackerJSON
        case .designSystem: return designSystemExampleJSON
        // Custom Components
        case .photoTouchUp: return PhotoTouchUpJSON.bottomSheet
        case .feedbackSurvey: return FeedbackSurveyJSON.bottomSheet
        case .doubleDate: return DoubleDateJSON.bottomSheet
        }
    }

    /// Calculate the file size of the JSON string in kilobytes
    var fileSizeKB: Double? {
        guard let json = json,
              let data = json.data(using: .utf8) else {
            return nil
        }
        return Double(data.count) / 1024.0
    }

    /// Formatted file size string (e.g., "2.5 KB")
    var fileSizeFormatted: String? {
        guard let sizeKB = fileSizeKB else {
            return nil
        }
        return String(format: "%.1f KB", sizeKB)
    }

    var presentation: PresentationStyle {
        switch self {
        // Most basic examples work well with medium detent
        case .labels, .buttons, .textFields, .toggles, .sliders, .gradients:
            return .detent(.medium)
        case .shapes:
            return .fullSize
        case .images:
            return .detent(.large)
        case .sectionLayoutGrid:
            return .detent(.fraction(0.3))
        case .vstackHstack, .zstack:
            return .detent(.medium)
        case .nested:
            return .fullSize
        case .alignment:
            return .fullSize
        case .sectionLayout:
            return .fullSize
        case .sectionLayoutList:
            return .fullSize
        case .sectionLayoutFlow:
            return .detent(.medium)
        case .sectionLayoutHorizontal:
            return .fullSize
        case .setState, .toggleState, .showAlert, .dismiss, .navigate, .sequence, .arrayActions:
            return .detent(.medium)
        case .httpRequest:
            return .fullSize
        case .staticData, .bindingData:
            return .detent(.medium)
        case .expressions:
            return .fullSize
        case .basicStyles, .conditionalStyles:
            return .detent(.medium)
        case .styleInheritance:
            return .fullSize
        // Complex examples - full size sheets
        case .dadJokes: return .detent(.medium)
        case .taskManager: return .fullSize
        case .shoppingCart: return .fullSize
        case .musicPlayer: return .fullSize
        case .metMuseum: return .fullSize
        case .weatherDashboard: return .fullSize
        case .plantCareTracker: return .fullSize
        case .designSystem: return .fullSize
        // Custom Components
        case .photoTouchUp: return .fixed(height: 600)
        case .feedbackSurvey: return .detent(.large)
        case .doubleDate: return .fullScreen
        }
    }

    // MARK: - Category Arrays

    static var componentExamples: [Example] {
        [.labels, .buttons, .textFields, .toggles, .sliders, .images, .gradients, .shapes]
    }

    static var layoutExamples: [Example] {
        [.vstackHstack, .zstack, .nested, .alignment, .sectionLayout, .sectionLayoutList, .sectionLayoutGrid, .sectionLayoutFlow, .sectionLayoutHorizontal]
    }

    static var actionExamples: [Example] {
        [.setState, .toggleState, .showAlert, .dismiss, .navigate, .sequence, .arrayActions, .httpRequest]
    }

    static var dataExamples: [Example] {
        [.staticData, .bindingData, .expressions]
    }

    static var styleExamples: [Example] {
        [.basicStyles, .styleInheritance, .conditionalStyles, .designSystem]
    }

    static var complexExamples: [Example] {
        [.dadJokes, .taskManager, .shoppingCart, .musicPlayer, .metMuseum, .weatherDashboard, .plantCareTracker]
    }

    static var customComponentExamples: [Example] {
        [.photoTouchUp, .feedbackSurvey, .doubleDate]
    }
}

// MARK: - Example Sheet View

struct ExampleSheetView: View {
    let example: Example
    @Environment(\.dismiss) private var dismiss
    @State private var parseError: String?

    var body: some View {
        Group {
            if let json = example.json {
                if let view = createView(from: json) {
                    view
                } else if let error = parseError {
                    errorView(error: error)
                } else {
                    errorView(error: "Unknown error occurred")
                }
            } else {
                errorView(error: "No JSON available for this example")
            }
        }
    }

    private func createView(from json: String) -> ScalsRendererView? {
        do {
            let document = try Document.Definition(jsonString: json)
            return ScalsRendererView(document: document, debugMode: true)
        } catch {
            parseError = DocumentParseError.detailedDescription(error: error, jsonString: json)
            return nil
        }
    }

    private func errorView(error: String) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)

                Text("Failed to parse JSON")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(error)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = error
                    } label: {
                        Label("Copy Error", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button("Dismiss") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

// MARK: - Presentation Style Modifier

struct PresentationStyleModifier: ViewModifier {
    let style: PresentationStyle

    func body(content: Content) -> some View {
        switch style {
        case .detent(let detent):
            content
                .presentationDetents([detent])
                .presentationDragIndicator(.visible)

        case .fixed(let height):
            content
                .presentationDetents([.height(height)])
                .presentationDragIndicator(.visible)

        case .autoSize:
            content
                .presentationSizing(.fitted)
                .presentationDragIndicator(.visible)

        case .fullSize:
            content
                .presentationSizing(.page)
                .presentationDragIndicator(.visible)

        case .fullScreen:
            content
        }
    }
}
