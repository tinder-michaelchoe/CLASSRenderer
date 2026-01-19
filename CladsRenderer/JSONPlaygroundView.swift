//
//  JSONPlaygroundView.swift
//  CladsRenderer
//
//  A playground view for testing custom JSON documents.
//

import CLADS
import CladsModules
import SwiftUI
import WebKit

// MARK: - Renderer Type

/// The type of renderer to use for displaying CLADS content.
enum RendererType: String, CaseIterable, Identifiable {
    case swiftUI = "SwiftUI"
    case html = "HTML"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .swiftUI: return "swift"
        case .html: return "globe"
        }
    }
}

// MARK: - JSON Playground View

// Sheet presentation data
struct HTMLSheetData: Identifiable {
    let id = UUID()
    let html: String
    let jsonString: String
}

struct JSONPlaygroundView: View {
    @State private var jsonText: String = sampleJSON
    @State private var showingSwiftUISheet = false
    @State private var htmlSheetData: HTMLSheetData?
    @State private var parseError: String?
    @State private var selectedRenderer: RendererType = .swiftUI
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // JSON Editor
                jsonEditor
                
                Divider()
                
                // Action bar
                actionBar
            }
            .navigationTitle("JSON Playground")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Renderer picker in principal position
                ToolbarItem(placement: .principal) {
                    Picker("Renderer", selection: $selectedRenderer) {
                        ForEach(RendererType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            jsonText = sampleJSON
                        } label: {
                            Label("Load Sample", systemImage: "doc.text")
                        }
                        
                        Button {
                            UIPasteboard.general.string = jsonText
                        } label: {
                            Label("Copy JSON", systemImage: "doc.on.doc")
                        }
                        
                        Button {
                            if let clipboardString = UIPasteboard.general.string {
                                jsonText = clipboardString
                            }
                        } label: {
                            Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            jsonText = ""
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        formatJSON()
                    } label: {
                        Image(systemName: "text.alignleft")
                    }
                    .disabled(jsonText.isEmpty)
                }
            }
            .sheet(isPresented: $showingSwiftUISheet) {
                RenderedJSONSheet(jsonString: jsonText)
            }
            .sheet(item: $htmlSheetData) { data in
                HTMLPreviewSheet(html: data.html, jsonString: data.jsonString)
            }
        }
    }
    
    private var jsonEditor: some View {
        TextEditor(text: $jsonText)
            .font(.system(.body, design: .monospaced))
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .focused($isTextEditorFocused)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .overlay(alignment: .topLeading) {
                if jsonText.isEmpty {
                    Text("Paste or type your CLADS JSON here...")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
    }
    
    private var actionBar: some View {
        VStack(spacing: 12) {
            if let error = parseError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Button {
                isTextEditorFocused = false
                validateAndRender()
            } label: {
                HStack {
                    Image(systemName: selectedRenderer == .swiftUI ? "play.fill" : "globe")
                    Text("Render with \(selectedRenderer.rawValue)")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 12)
        .background(Color(.systemBackground))
    }
    
    private func validateAndRender() {
        parseError = nil
        
        // Try to parse the JSON to check for errors
        do {
            let definition = try Document.Definition(jsonString: jsonText)
            
            // Show appropriate sheet based on renderer
            if selectedRenderer == .html {
                let html = generateHTML(from: definition)
                htmlSheetData = HTMLSheetData(html: html, jsonString: jsonText)
            } else {
                showingSwiftUISheet = true
            }
        } catch {
            let fullError = DocumentParseError.detailedDescription(error: error, jsonString: jsonText)
            
            // Print full error to console for debugging
            print("=== CLADS Parse Error ===")
            print(fullError)
            print("=========================")
            
            // Also print the raw error
            print("Raw error: \(error)")
            
            parseError = fullError
                .components(separatedBy: "\n")
                .first ?? "Invalid JSON"
        }
    }
    
    private func generateHTML(from definition: Document.Definition) -> String {
        // Create resolver with default component registry
        let componentRegistry = ComponentResolverRegistry.default
        let resolver = Resolver(
            document: definition,
            componentRegistry: componentRegistry
        )
        
        // Resolve to render tree
        do {
            let renderTree = try resolver.resolve()
            
            // Use HTML renderer
            let htmlRenderer = HTMLRenderer()
            let output = htmlRenderer.render(renderTree)
            
            print("=== HTML Generated Successfully ===")
            print("HTML length: \(output.html.count) chars")
            print("CSS length: \(output.css.count) chars")
            
            return output.fullDocument
        } catch {
            print("=== HTML Generation Error: \(error) ===")
            
            // Return error HTML if resolution fails
            return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body { 
                        font-family: -apple-system, system-ui; 
                        padding: 20px;
                        background: #1a1a2e;
                        color: #e8e8e8;
                    }
                    .error { color: #FF6B6B; }
                    pre { 
                        background: rgba(255,255,255,0.1); 
                        padding: 16px; 
                        border-radius: 8px;
                        overflow-x: auto;
                    }
                </style>
            </head>
            <body>
                <h1 class="error">Resolution Error</h1>
                <pre>\(error.localizedDescription.htmlEscaped)</pre>
            </body>
            </html>
            """
        }
    }
    
    private func formatJSON() {
        guard let data = jsonText.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return
        }
        jsonText = prettyString
    }
}

// MARK: - Rendered JSON Sheet (SwiftUI)

struct RenderedJSONSheet: View {
    let jsonString: String
    @State private var hasError = false
    
    var body: some View {
        Group {
            if let view = CladsRendererView(jsonString: jsonString, debugMode: true) {
                view
            } else {
                errorView
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var errorView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                
                Text("Failed to Render")
                    .font(.headline)
                
                Text("The JSON could not be parsed into a valid CLADS document.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Show detailed error
                let errorMessage = getParseError()
                Text(errorMessage)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
            .padding()
        }
    }
    
    private func getParseError() -> String {
        do {
            _ = try Document.Definition(jsonString: jsonString)
            return "Unknown error"
        } catch {
            return DocumentParseError.detailedDescription(error: error, jsonString: jsonString)
        }
    }
}

// MARK: - HTML Preview Sheet

struct HTMLPreviewSheet: View {
    let html: String
    let jsonString: String
    
    var body: some View {
        WebViewWrapper(html: html)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }
}

// MARK: - HTML Source View

struct HTMLSourceView: View {
    let html: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(html)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("HTML Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        UIPasteboard.general.string = html
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

// MARK: - WebView Wrapper

/// A UIViewRepresentable wrapper for WKWebView to display HTML content.
struct WebViewWrapper: UIViewRepresentable {
    let html: String
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadedHTML: String = ""
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        
        // Allow inspection in Safari for debugging
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        
        // Load HTML immediately in makeUIView
        if !html.isEmpty {
            context.coordinator.lastLoadedHTML = html
            webView.loadHTMLString(html, baseURL: nil)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only load if HTML changed and is not empty
        guard !html.isEmpty, html != context.coordinator.lastLoadedHTML else {
            return
        }
        
        context.coordinator.lastLoadedHTML = html
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Debug Helpers

private func printRenderNode(_ node: RenderNode?, indent: Int) {
    guard let node = node else {
        print(String(repeating: "  ", count: indent) + "nil")
        return
    }
    let prefix = String(repeating: "  ", count: indent)
    switch node {
    case .container(let c):
        print("\(prefix)Container(\(c.layoutType))")
        for child in c.children {
            printRenderNode(child, indent: indent + 1)
        }
    case .text(let t):
        print("\(prefix)Text(content: \"\(t.content)\", bindingPath: \(t.bindingPath ?? "nil"), bindingTemplate: \(t.bindingTemplate ?? "nil"))")
    case .button(let b):
        print("\(prefix)Button(label: \"\(b.label)\")")
    case .sectionLayout(let s):
        print("\(prefix)SectionLayout(sections: \(s.sections.count))")
    case .textField(let tf):
        print("\(prefix)TextField(placeholder: \"\(tf.placeholder)\")")
    case .toggle:
        print("\(prefix)Toggle")
    case .slider:
        print("\(prefix)Slider")
    case .image:
        print("\(prefix)Image")
    case .gradient:
        print("\(prefix)Gradient")
    case .spacer:
        print("\(prefix)Spacer")
    case .divider:
        print("\(prefix)Divider")
    case .custom(let kind, _):
        print("\(prefix)Custom(\(kind.rawValue))")
    }
}

// MARK: - Sample JSON

private let sampleJSON = """
{
  "id": "playground-sample",
  "state": {
    "counter": 0,
    "message": "Hello, CLADS!"
  },
  "root": {
    "children": [
      {
        "type": "vstack",
        "spacing": 20,
        "padding": {"horizontal": 24, "vertical": 40},
        "children": [
          {
            "type": "label",
            "text": "${message}",
            "styleId": "titleStyle"
          },
          {
            "type": "label",
            "text": "Counter: ${counter}",
            "styleId": "subtitleStyle"
          },
          {
            "type": "hstack",
            "spacing": 12,
            "children": [
              {
                "type": "button",
                "text": "Decrement",
                "styleId": "decrementButton",
                "actions": {
                  "onTap": {
                    "type": "setState",
                    "path": "counter",
                    "value": {"$expr": "${counter} - 1"}
                  }
                }
              },
              {
                "type": "button",
                "text": "Increment",
                "styleId": "incrementButton",
                "actions": {
                  "onTap": {
                    "type": "setState",
                    "path": "counter",
                    "value": {"$expr": "${counter} + 1"}
                  }
                }
              }
            ]
          },
          {
            "type": "button",
            "text": "Reset",
            "styleId": "resetButton",
            "actions": {
              "onTap": {
                "type": "sequence",
                "steps": [
                  {
                    "type": "setState",
                    "path": "counter",
                    "value": 0
                  },
                  {
                    "type": "setState",
                    "path": "message",
                    "value": "Counter reset!"
                  }
                ]
              }
            }
          }
        ]
      }
    ]
  },
  "styles": {
    "titleStyle": {
      "fontSize": 28,
      "fontWeight": "bold"
    },
    "subtitleStyle": {
      "fontSize": 20,
      "foregroundColor": "#666666"
    },
    "decrementButton": {
      "backgroundColor": "#FF6B6B",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "padding": {"horizontal": 20, "vertical": 12}
    },
    "incrementButton": {
      "backgroundColor": "#4ECDC4",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "padding": {"horizontal": 20, "vertical": 12}
    },
    "resetButton": {
      "backgroundColor": "#9B59B6",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "padding": {"horizontal": 24, "vertical": 14}
    }
  }
}
"""

#Preview {
    JSONPlaygroundView()
}
