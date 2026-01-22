# SCALS Extensibility Guide

SCALS provides multiple extensibility mechanisms to support different use cases—from quick view-level customizations to building reusable core modules. This guide covers all extensibility options, when to use each, and how to implement them.

## Overview of Extensibility Options

| Option | Scope | Persistence | Use Case |
|--------|-------|-------------|----------|
| **Custom Actions (closures)** | Single view | Per-view | Quick, view-specific logic |
| **Custom Actions (delegate)** | View controller | Per-controller | When you need access to the owning controller |
| **Custom Components (`CustomComponent`)** | View-level registration | Per-view | Quick custom UI without full pipeline |
| **Core Module (full pipeline)** | Global/shared | App-wide | Reusable components across the app |
| **SCALSPlugin** | Global/shared | App-wide | Bundle multiple related registrations |
| **Design System (`DesignSystemProvider`)** | Global/shared | App-wide | Custom styling tokens and native components |
| **Section Layout Renderers** | Global/shared | App-wide | Custom list/grid/flow layouts |
| **State Observers** | View-level | Per-view | React to state changes |
| **External State Binding** | View-level | Per-view | Two-way sync with SwiftUI state |
| **Alert/Navigation Handlers** | View-level | Per-view | Custom presentation behavior |

---

## Part 1: View-Level Extensibility

These options are ideal when you need customization scoped to a specific view instance without affecting other parts of your app.

### 1.1 Custom Actions via Closures

Use custom action closures when you need view-specific business logic that doesn't warrant a full action handler.

```swift
ScalsRendererView(
    document: document,
    customActions: [
        "submitOrder": { params, context in
            let orderId = context.stateStore.get("order.id") as? String
            await OrderService.submit(orderId)
        },
        "trackEvent": { params, context in
            let eventName = params.string("event") ?? "unknown"
            Analytics.track(eventName)
        }
    ]
)
```

These actions can be referenced in JSON:

```json
{
  "actions": {
    "onSubmit": {
      "type": "submitOrder",
      "orderId": { "$expr": "order.id" }
    }
  }
}
```

**When to use:**
- One-off actions specific to a single screen
- Integration with view-specific services
- Prototyping before committing to a full action handler

### 1.2 Custom Actions via Delegate

Use the `ScalsActionDelegate` when you need access to the owning view controller or prefer a single point for handling multiple custom actions.

```swift
class OrderViewController: UIViewController, ScalsActionDelegate {
    func scalsRenderer(
        handleAction actionId: String,
        parameters: ActionParameters,
        context: ActionExecutionContext
    ) async -> Bool {
        switch actionId {
        case "submitOrder":
            await handleSubmitOrder(parameters, context)
            return true
        case "showReceipt":
            presentReceiptSheet()
            return true
        default:
            return false  // Fall through to registry
        }
    }
}
```

**When to use:**
- Multiple related actions that share controller state
- Actions that need to present UIKit view controllers
- Actions that interact with navigation or other UIKit APIs

### 1.3 Custom Components (`CustomComponent` Protocol)

The `CustomComponent` protocol provides a lightweight way to inject custom SwiftUI views without implementing the full resolver/renderer pipeline.

```swift
struct WeatherCardComponent: CustomComponent {
    static let typeName = "weatherCard"

    @MainActor
    static func makeView(context: CustomComponentContext) -> AnyView {
        let temp = context.resolveDouble(forKey: "temperature") ?? 0
        let condition = context.resolveString(forKey: "condition") ?? "Unknown"

        return AnyView(
            WeatherCardView(temperature: temp, condition: condition)
                .applyScalsStyle(context.style)
                .applyScalsActions(context.component.actions, context: context)
        )
    }
}
```

Register at view creation:

```swift
ScalsRendererView(
    document: document,
    customComponents: [WeatherCardComponent.self, PhotoComparisonComponent.self]
)
```

Use in JSON:

```json
{
  "type": "weatherCard",
  "styleId": "card",
  "data": {
    "temperature": { "type": "binding", "path": "weather.temp" },
    "condition": { "type": "static", "value": "Sunny" }
  },
  "actions": {
    "onTap": "refreshWeather"
  }
}
```

#### CustomComponentContext API

The `CustomComponentContext` provides everything your custom component needs:

| Property/Method | Description |
|-----------------|-------------|
| `style: IR.Style` | Resolved style from `styleId` |
| `stateStore: StateStore` | Read/write state |
| `component: Document.Component` | Original component definition |
| `resolveString(forKey:)` | Resolve data reference to String |
| `resolveDouble(forKey:)` | Resolve data reference to Double |
| `resolveInt(forKey:)` | Resolve data reference to Int |
| `resolveBool(forKey:)` | Resolve data reference to Bool |
| `executeAction(_:)` | Execute an action binding |

#### Applying SCALS Styling and Actions

Use the provided view modifiers to integrate with SCALS systems:

```swift
MyCustomView()
    .applyScalsStyle(context.style)           // Apply IR.Style
    .applyScalsActions(context.component.actions, context: context)  // Apply actions
```

**When to use CustomComponent:**
- Custom UI that doesn't fit built-in components
- Wrapping existing SwiftUI views for use in SCALS
- Complex interactive components (sliders, pickers, animations)
- When you don't need UIKit support

---

## Part 2: Core Module Extensibility

When you need components or actions that are reusable across your entire app, implement them as core modules that register with SCALS registries.

### 2.1 Architecture Overview

SCALS uses an LLVM-inspired pipeline:

```
JSON → Document (Model) → Resolver → RenderTree (IR) → Renderer → View
```

Adding a new core component requires implementing pieces at each stage:

1. **ComponentProperties** – Decode JSON properties
2. **ComponentResolver** – Convert Document to RenderNode
3. **RenderNode** – IR representation for rendering
4. **SwiftUI/UIKit Renderer** – Convert RenderNode to views

### 2.2 When to Add a Core Module

**Add a core module when:**
- The component will be used across multiple screens/features
- You need both SwiftUI and UIKit support
- The component should be available to all documents by default
- You want to ship it as part of a library/framework

**Use view-level extensibility instead when:**
- The component is specific to one screen
- You're prototyping or iterating quickly
- You only need SwiftUI support

### 2.3 Adding a New Component: Step-by-Step

Let's walk through adding a hypothetical "Chart" component.

#### Step 1: Define the Component Kind

```swift
// In your module
extension Document.ComponentKind {
    public static let chart = Document.ComponentKind(rawValue: "chart")
}

extension RenderNodeKind {
    public static let chart = RenderNodeKind(rawValue: "chart")
}
```

#### Step 2: Define Component Properties (Optional)

If your component has custom JSON properties beyond the standard ones:

```swift
public struct ChartProperties: ComponentProperties {
    public static let kind = Document.ComponentKind.chart
    
    public let dataPoints: [Double]
    public let chartType: String
    public let showLabels: Bool
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dataPoints = try container.decode([Double].self, forKey: .dataPoints)
        chartType = try container.decodeIfPresent(String.self, forKey: .chartType) ?? "line"
        showLabels = try container.decodeIfPresent(Bool.self, forKey: .showLabels) ?? true
    }
    
    private enum CodingKeys: String, CodingKey {
        case dataPoints, chartType, showLabels
    }
}
```

#### Step 3: Define the Render Node

```swift
public struct ChartNode: CustomRenderNode {
    public static let kind = RenderNodeKind.chart
    
    public let id: String?
    public let dataPoints: [Double]
    public let chartType: String
    public let showLabels: Bool
    public let style: IR.Style
    
    public init(
        id: String? = nil,
        dataPoints: [Double],
        chartType: String = "line",
        showLabels: Bool = true,
        style: IR.Style = IR.Style()
    ) {
        self.id = id
        self.dataPoints = dataPoints
        self.chartType = chartType
        self.showLabels = showLabels
        self.style = style
    }
}
```

#### Step 4: Implement the Component Resolver

```swift
public struct ChartComponentResolver: ComponentResolving {
    public static let componentKind: Document.ComponentKind = .chart
    
    public init() {}
    
    @MainActor
    public func resolve(
        _ component: Document.Component,
        context: ResolutionContext
    ) throws -> ComponentResolutionResult {
        // Resolve style
        let style = context.styleResolver.resolve(component.styleId)
        let nodeId = component.id ?? UUID().uuidString
        
        // Get chart-specific data from component
        // (In practice, you'd read from component.data or custom properties)
        let dataPoints = [10.0, 25.0, 15.0, 30.0, 20.0]  // Example
        let chartType = "line"
        
        // Create view node for dependency tracking (optional)
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .custom(kind: "chart")
            )
            viewNode?.parent = context.parentViewNode
        } else {
            viewNode = nil
        }
        
        // Create the render node
        let chartNode = ChartNode(
            id: component.id,
            dataPoints: dataPoints,
            chartType: chartType,
            style: style
        )
        
        let renderNode = RenderNode.custom(kind: .chart, node: chartNode)
        return ComponentResolutionResult(renderNode: renderNode, viewNode: viewNode)
    }
}
```

#### Step 5: Implement the SwiftUI Renderer

```swift
public struct ChartNodeSwiftUIRenderer: SwiftUINodeRendering {
    public static let nodeKind = RenderNodeKind.chart
    
    public init() {}
    
    @MainActor
    public func render(_ node: RenderNode, context: SwiftUIRenderContext) -> AnyView {
        guard case .custom(_, let customNode) = node,
              let chartNode = customNode as? ChartNode else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            ChartNodeView(node: chartNode, stateStore: context.stateStore)
        )
    }
}

struct ChartNodeView: View {
    let node: ChartNode
    @ObservedObject var stateStore: StateStore
    
    var body: some View {
        // Your chart implementation
        VStack {
            // ... chart drawing code
        }
        .applyContainerStyle(node.style)
    }
}
```

#### Step 6: (Optional) Implement UIKit Renderer

```swift
public struct ChartNodeUIKitRenderer: UIKitNodeRendering {
    public static let nodeKind = RenderNodeKind.chart
    
    public init() {}
    
    @MainActor
    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .custom(_, let customNode) = node,
              let chartNode = customNode as? ChartNode else {
            return UIView()
        }
        
        let chartView = ChartUIKitView()
        chartView.configure(with: chartNode)
        return chartView
    }
}
```

#### Step 7: Register with Default Registries

Add to the appropriate registry extension in ScalsModules:

```swift
// ComponentResolverRegistry+Default.swift
extension ComponentResolverRegistry {
    public func registerBuiltInResolvers() {
        // ... existing registrations
        register(ChartComponentResolver())
    }
}

// SwiftUINodeRendererRegistry+Default.swift
extension SwiftUINodeRendererRegistry {
    public func registerBuiltInRenderers() {
        // ... existing registrations
        register(ChartNodeSwiftUIRenderer())
    }
}
```

### 2.4 Adding a New Action Handler

Action handlers process action types defined in JSON documents.

```swift
public struct RefreshDataActionHandler: ActionHandler {
    public static let actionType = "refreshData"
    
    public init() {}
    
    @MainActor
    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        // Get parameters
        let endpoint = parameters.string("endpoint") ?? "/api/data"
        let loadingPath = parameters.string("loadingPath")
        
        // Set loading state
        if let loadingPath = loadingPath {
            context.stateStore.set(loadingPath, value: true)
        }
        
        // Perform the action
        do {
            let data = try await fetchData(from: endpoint)
            context.stateStore.set("data", value: data)
        } catch {
            context.stateStore.set("error", value: error.localizedDescription)
        }
        
        // Clear loading state
        if let loadingPath = loadingPath {
            context.stateStore.set(loadingPath, value: false)
        }
    }
}
```

Register in `ActionRegistry+Default.swift`:

```swift
extension ActionRegistry {
    public func registerBuiltInActions() {
        // ... existing registrations
        register(RefreshDataActionHandler())
    }
}
```

#### Cancellable Actions

For long-running actions that should support cancellation:

```swift
public final class LongRunningActionHandler: CancellableActionHandler {
    public static let actionType = "longRunning"
    
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private let lock = NSLock()
    
    public func cancel(requestId: String, documentId: String) {
        let key = "\(documentId):\(requestId)"
        lock.lock()
        let task = activeTasks.removeValue(forKey: key)
        lock.unlock()
        task?.cancel()
    }
    
    public func cancelAll(documentId: String) {
        lock.lock()
        let prefix = "\(documentId):"
        let keysToCancel = activeTasks.keys.filter { $0.hasPrefix(prefix) }
        let tasksToCancel = keysToCancel.compactMap { activeTasks.removeValue(forKey: $0) }
        lock.unlock()
        tasksToCancel.forEach { $0.cancel() }
    }
    
    @MainActor
    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        // Implementation with Task tracking...
    }
}
```

### 2.5 Using SCALSPlugin for Bundled Registrations

When you have multiple related components/actions, bundle them as a plugin:

```swift
public struct ChartingPlugin: SCALSPlugin {
    public init() {}
    
    public func register(with registry: ScalsRegistry) {
        // Register component properties
        registry.registerProperties(BarChartProperties.self)
        registry.registerProperties(LineChartProperties.self)
        registry.registerProperties(PieChartProperties.self)
        
        // Register resolvers
        registry.registerResolver(BarChartResolver())
        registry.registerResolver(LineChartResolver())
        registry.registerResolver(PieChartResolver())
        
        // Register SwiftUI renderers
        registry.registerSwiftUIRenderer(BarChartSwiftUIRenderer())
        registry.registerSwiftUIRenderer(LineChartSwiftUIRenderer())
        registry.registerSwiftUIRenderer(PieChartSwiftUIRenderer())
        
        // Register actions
        registry.registerAction(ChartExportActionHandler())
    }
}

// Usage
let registry = ScalsRegistry()
registry.load(ChartingPlugin())
```

### 2.6 Using ScalsRegistry for Complete Registration

`ScalsRegistry` provides unified registration for all pipeline stages:

```swift
let registry = ScalsRegistry()

// Full registration with all renderers
registry.registerComponent(
    propertiesType: ChartProperties.self,
    resolver: ChartResolver(),
    uikitRenderer: ChartUIKitRenderer(),
    swiftuiRenderer: ChartSwiftUIRenderer()
)

// SwiftUI only
registry.registerComponent(
    propertiesType: ChartProperties.self,
    resolver: ChartResolver(),
    swiftuiRenderer: ChartSwiftUIRenderer()
)

// Resolver only (uses built-in render nodes)
registry.registerComponent(
    propertiesType: ChartProperties.self,
    resolver: ChartResolver()
)
```

---

## Part 3: Comparison and Decision Guide

### Quick Reference

| Need | Solution |
|------|----------|
| One-off action for a single screen | Custom action closure |
| Action that presents UIKit views | Action delegate |
| Custom UI for one screen only | `CustomComponent` protocol |
| Reusable component across app | Full core module |
| Multiple related components | `SCALSPlugin` |
| Both SwiftUI and UIKit support | Full core module with both renderers |

### Migration Path

Start simple, upgrade as needed:

1. **Prototype** with custom action closures and `CustomComponent`
2. **Extract** frequently-used components to core modules
3. **Bundle** related modules into plugins
4. **Ship** plugins as separate frameworks if needed

### Performance Considerations

- **Custom components** add minimal overhead—they're resolved like built-in components
- **Core modules** have the same performance as built-in components
- **Action closures** have trivial overhead compared to full handlers

---

## Examples

### Example: Photo Comparison Custom Component

A complete example of a custom component with animation:

```swift
public struct PhotoComparisonComponent: CustomComponent {
    public static let typeName = "photoComparison"

    @MainActor
    public static func makeView(context: CustomComponentContext) -> AnyView {
        let beforeImage = context.resolveString(forKey: "beforeImage") ?? ""
        let afterImage = context.resolveString(forKey: "afterImage") ?? ""
        
        let width = context.style.width ?? 200
        let height = context.style.height ?? 300

        return AnyView(
            PhotoComparisonView(
                beforeImageName: beforeImage,
                afterImageName: afterImage,
                width: width,
                height: height
            )
        )
    }
}
```

JSON usage:

```json
{
  "type": "photoComparison",
  "styleId": "comparisonCard",
  "data": {
    "beforeImage": { "type": "static", "value": "photo_before" },
    "afterImage": { "type": "static", "value": "photo_after" }
  }
}
```

### Example: HTTP Request Action Handler

The built-in `RequestActionHandler` shows patterns for complex actions:

- Parameter resolution from state
- Loading/error state management
- Cancellation support
- Debug logging
- Success/error callbacks

See `ScalsModules/ActionHandlers/RequestActionHandler.swift` for the full implementation.

---

## Part 4: Design System Integration

Design systems allow you to provide both style tokens and native component implementations that integrate seamlessly with SCALS.

### 4.1 DesignSystemProvider Protocol

The `DesignSystemProvider` protocol enables two levels of integration:

1. **Style Tokens** – Map `@`-prefixed style references to `IR.Style` values
2. **Native Components** – Render full native SwiftUI components with animations, states, and behaviors

```swift
public struct MyDesignSystemProvider: DesignSystemProvider {
    public static let identifier = "myDesignSystem"
    
    public init() {}
    
    // MARK: - Style Token Resolution (fallback)
    
    public func resolveStyle(_ reference: String) -> IR.Style? {
        // Parse reference like "button.primary" or "text.heading1"
        let parts = reference.split(separator: ".").map(String.init)
        guard let category = parts.first else { return nil }
        
        switch category {
        case "button": return resolveButtonStyle(parts)
        case "text": return resolveTextStyle(parts)
        default: return nil
        }
    }
    
    private func resolveButtonStyle(_ parts: [String]) -> IR.Style? {
        guard parts.count >= 2 else { return nil }
        var style = IR.Style()
        
        switch parts[1] {
        case "primary":
            style.backgroundColor = Color(hex: "#6366F1")
            style.textColor = .white
            style.cornerRadius = 12
            style.paddingTop = 14
            style.paddingBottom = 14
        case "secondary":
            style.backgroundColor = Color(hex: "#F3F4F6")
            style.textColor = Color(hex: "#374151")
            style.cornerRadius = 12
        default:
            return nil
        }
        return style
    }
    
    // MARK: - Full Component Rendering
    
    public func canRender(_ node: RenderNode, styleId: String?) -> Bool {
        guard let styleId, styleId.hasPrefix("@") else { return false }
        let ref = String(styleId.dropFirst())
        
        switch node {
        case .button: return ref.hasPrefix("button.")
        default: return false
        }
    }
    
    @MainActor
    public func render(_ node: RenderNode, styleId: String?, context: SwiftUIRenderContext) -> AnyView? {
        guard let styleId, styleId.hasPrefix("@") else { return nil }
        let ref = String(styleId.dropFirst())
        
        switch node {
        case .button(let buttonNode):
            return renderNativeButton(buttonNode, ref: ref, context: context)
        default:
            return nil
        }
    }
    
    @MainActor
    private func renderNativeButton(_ node: ButtonNode, ref: String, context: SwiftUIRenderContext) -> AnyView? {
        // Return your native design system button with SCALS action handling
        return AnyView(
            MyDesignSystemButton(
                label: node.label,
                style: ref.contains("primary") ? .primary : .secondary,
                onTap: {
                    if let action = node.onTap {
                        Task { @MainActor in
                            switch action {
                            case .reference(let actionId):
                                await context.actionContext.executeAction(id: actionId)
                            case .inline(let actionDef):
                                await context.actionContext.executeAction(actionDef)
                            }
                        }
                    }
                }
            )
        )
    }
}
```

### 4.2 The @ Prefix Convention

- **`@` prefix** → Design system style (e.g., `@button.primary`, `@text.heading1`)
- **No prefix** → Local style from document's `styles` dictionary

```json
{
  "type": "button",
  "text": "Sign Up",
  "styleId": "@button.primary"
}
```

### 4.3 Injecting a Design System

Pass your provider when creating the view:

```swift
let provider = MyDesignSystemProvider()

ScalsRendererView(
    document: document,
    designSystemProvider: provider
)
```

### 4.4 Fallback Behavior

SCALS uses a cascading fallback system:

1. **Provider + canRender() returns true** → Native component via `provider.render()`
2. **Provider + canRender() returns false** → Standard component + `IR.Style` from `provider.resolveStyle()`
3. **No provider or unknown style** → Standard component + inline/document styles only

### 4.5 Best Practices for Design Systems

1. **Keep components pure** – Design system components should have no SCALS imports
2. **Handle dark mode internally** – Use `@Environment(\.colorScheme)` in your components
3. **Always implement `resolveStyle()`** – Provides fallback for platforms without native support
4. **Use the wrapper pattern** – SCALS wraps your components to inject action handling

For complete details, see `Docs/DesignSystemGuide.md`.

---

## Part 5: Section Layout Extensibility

SCALS supports custom section layouts through two extension points:

### 5.1 Section Layout Config Resolvers

Add support for new section layout types during the resolution phase:

```swift
public struct CarouselLayoutConfigResolver: SectionLayoutConfigResolving {
    public static let layoutType = Document.SectionType.carousel
    
    public init() {}
    
    public func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult {
        // Convert document config to IR section type and config
        return SectionLayoutConfigResult(
            sectionType: .carousel,  // Your custom IR.SectionType
            sectionConfig: IR.SectionConfig(
                itemSpacing: config.itemSpacing ?? 16,
                pageWidth: config.pageWidth ?? 280
            )
        )
    }
}

// Register
let registry = SectionLayoutConfigResolverRegistry()
registry.register(CarouselLayoutConfigResolver())
```

### 5.2 SwiftUI Section Layout Renderers

Render custom section layouts in SwiftUI:

```swift
public struct CarouselSectionLayoutRenderer: SwiftUISectionLayoutRendering {
    public static let layoutTypeIdentifier = SectionLayoutTypeIdentifier(rawValue: "carousel")
    
    public init() {}
    
    @MainActor
    public func render(section: IR.Section, context: SwiftUISectionRenderContext) -> AnyView {
        AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: section.config.itemSpacing) {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                        context.renderChild(item)
                            .frame(width: section.config.pageWidth)
                    }
                }
                .padding(.horizontal)
            }
        )
    }
}

// Register
let registry = SwiftUISectionLayoutRendererRegistry()
registry.register(CarouselSectionLayoutRenderer())
```

Built-in layout types include:
- **list** – Vertical scrolling list
- **grid** – Multi-column grid layout
- **flow** – Flexible flow layout
- **horizontal** – Horizontal scrolling

---

## Part 6: State and Lifecycle Hooks

### 6.1 State Change Callbacks

React to state changes with type-safe observers:

```swift
// Simple callback
stateStore.onStateChange { path, oldValue, newValue in
    print("\(path) changed from \(oldValue) to \(newValue)")
}

// Type-safe observer
struct UserResponse: Codable {
    let id: Int
    let name: String
}

stateStore.observe("api.response", as: UserResponse.self) { user in
    guard let user = user else { return }
    print("User loaded: \(user.name)")  // Type-safe!
}

// Observer with diffing
stateStore.observe("cart.items", as: [CartItem].self) { oldItems, newItems in
    let added = newItems?.filter { item in
        !(oldItems?.contains { $0.id == item.id } ?? false)
    }
    print("Added items: \(added ?? [])")
}
```

### 6.2 External State Binding

Sync SCALS state with external SwiftUI state using `ScalsRendererBindingView`:

```swift
struct MyView: View {
    @State private var orderState = OrderState()
    
    var body: some View {
        ScalsRendererBindingView(
            document: document,
            state: $orderState,
            configuration: ScalsRendererBindingConfiguration(
                onStateChange: { path, old, new in
                    // Analytics, persistence, etc.
                    Analytics.track("state_change", properties: ["path": path])
                },
                onAction: { actionId, params in
                    // Track action execution
                }
            )
        )
    }
}
```

#### ScalsRendererBindingConfiguration Callbacks

| Callback | Signature | Use Case |
|----------|-----------|----------|
| `onStateChange` | `(path: String, oldValue: Any?, newValue: Any?) -> Void` | Analytics, persistence, debugging |
| `onAction` | `(actionId: String, parameters: [String: Any]) -> Void` | Action tracking, analytics |

### 6.3 ActionContext Delegate Callbacks

The `ActionContext` provides several injectable handlers for customizing behavior:

```swift
let context = ActionContext(
    stateStore: stateStore,
    actionDefinitions: actions,
    registry: actionRegistry,
    actionDelegate: myDelegate,           // ScalsActionDelegate for action interception
    alertPresenter: CustomAlertPresenter() // AlertPresenting for custom alerts
)

// Additional handlers set after creation
context.dismissHandler = { /* custom dismiss logic */ }
context.alertHandler = { config in /* legacy alert handling */ }
context.navigationHandler = { destination, presentation in /* custom navigation */ }
```

| Handler | Type | Purpose |
|---------|------|---------|
| `actionDelegate` | `ScalsActionDelegate?` | Intercept actions before registry lookup |
| `alertPresenter` | `AlertPresenting` | Custom alert presentation (injectable at init) |
| `dismissHandler` | `(() -> Void)?` | Custom dismiss behavior |
| `alertHandler` | `((AlertConfiguration) -> Void)?` | Legacy alert callback |
| `navigationHandler` | `((String, NavigationPresentation?) -> Void)?` | Custom navigation |

### 6.4 Root Lifecycle Actions

Execute actions on view lifecycle events:

```json
{
  "root": {
    "actions": {
      "onAppear": "loadData",
      "onDisappear": "saveState"
    },
    "children": [...]
  }
}
```

Supported events:
- `onAppear` – View appeared on screen
- `onDisappear` – View disappeared from screen

---

## Part 7: Navigation and Presentation

### 7.1 Navigation Handler

Handle navigation actions with custom logic:

```swift
let context = ActionContext(...)
context.navigationHandler = { destination, presentation in
    switch destination {
    case "checkout":
        router.push(CheckoutView())
    case "profile":
        router.present(ProfileView(), style: presentation)
    default:
        break
    }
}
```

### 7.2 Custom Alert Presenter

Replace the default alert presentation with custom UI:

```swift
// Implement the protocol
class CustomAlertPresenter: AlertPresenting {
    @MainActor
    func present(_ config: AlertConfiguration) {
        // Use your custom alert UI
        MyAlertService.show(
            title: config.title,
            message: config.message,
            buttons: config.buttons.map { ... }
        )
    }
}

// Inject during context creation
let context = ActionContext(
    stateStore: store,
    actionDefinitions: actions,
    registry: registry,
    alertPresenter: CustomAlertPresenter()
)
```

### 7.3 Dismiss Handler

Handle dismiss actions with custom behavior:

```swift
context.dismissHandler = {
    // Custom dismiss logic
    coordinator.popToRoot()
    // Or: navigationController?.popViewController(animated: true)
}
```

---

## Summary

SCALS extensibility is designed around the principle of "progressive complexity"—start with the simplest solution that works, and upgrade to more powerful options only when needed.

### Quick Reference

| Need | Solution |
|------|----------|
| One-off action for a single screen | Custom action closure |
| Action that presents UIKit views | Action delegate |
| Custom UI for one screen only | `CustomComponent` protocol |
| Reusable component across app | Full core module |
| Multiple related components | `SCALSPlugin` |
| Both SwiftUI and UIKit support | Full core module with both renderers |
| Custom styling system | `DesignSystemProvider` |
| Custom list/grid layouts | Section layout renderer |
| React to state changes | State observers |
| Sync with SwiftUI state | `ScalsRendererBindingView` |
| Custom navigation | Navigation handler |
| Custom alerts | `AlertPresenting` |

### Migration Path

1. **Prototype** with custom action closures and `CustomComponent`
2. **Extract** frequently-used components to core modules
3. **Bundle** related modules into plugins
4. **Ship** plugins as separate frameworks if needed

For most custom UI needs, `CustomComponent` is the right choice. For app-wide reusable components with full pipeline support, implement a core module. For related sets of components, bundle them as a `SCALSPlugin`. For consistent styling across your app, implement a `DesignSystemProvider`.
