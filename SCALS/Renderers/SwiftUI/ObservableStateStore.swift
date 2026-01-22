//
//  ObservableStateStore.swift
//  ScalsRendererFramework
//
//  SwiftUI-specific wrapper for StateStore that provides ObservableObject conformance.
//  This bridges the platform-agnostic StateStore with SwiftUI's reactive system.
//

import SwiftUI
import Combine

/// SwiftUI wrapper for `StateStore` that provides `ObservableObject` conformance.
///
/// This class wraps the platform-agnostic `StateStore` and bridges its callback-based
/// change notifications to SwiftUI's `objectWillChange` publisher.
///
/// Use this class in SwiftUI views that need to react to state changes:
///
/// ```swift
/// struct MyView: View {
///     @ObservedObject var stateStore: ObservableStateStore
///
///     var body: some View {
///         Text(stateStore.get("message") as? String ?? "")
///     }
/// }
/// ```
///
/// For non-SwiftUI code, use `StateStore` directly.
@MainActor
public final class ObservableStateStore: ObservableObject {
    /// The underlying platform-agnostic state store
    public let store: StateStoring
    
    /// Internal callback ID for cleanup
    private var callbackId: UUID?
    
    // MARK: - Initialization
    
    /// Create a new ObservableStateStore with a fresh StateStore
    public init() {
        self.store = StateStore()
        setupCallback()
    }
    
    /// Wrap an existing StateStore
    /// - Parameter store: The StateStore to wrap
    public init(wrapping store: StateStore) {
        self.store = store
        setupCallback()
    }
    
    /// Wrap any StateStoring implementation
    /// - Parameter store: The StateStoring implementation to wrap
    public init(wrapping store: StateStoring) {
        self.store = store
        setupCallback()
    }
    
    deinit {
        if let id = callbackId {
            store.removeStateChangeCallback(id)
        }
    }
    
    private func setupCallback() {
        callbackId = store.onStateChange { [weak self] _, _, _ in
            // Dispatch to main thread since callbacks may come from any thread
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Reading State
    
    public func get(_ keypath: String) -> Any? {
        store.get(keypath)
    }
    
    public func get<T>(_ keypath: String, as type: T.Type = T.self) -> T? {
        store.get(keypath, as: type)
    }
    
    public func getArray(_ keypath: String) -> [Any]? {
        store.getArray(keypath)
    }
    
    public func getArrayCount(_ keypath: String) -> Int {
        store.getArrayCount(keypath)
    }
    
    public func arrayContains(_ keypath: String, value: Any) -> Bool {
        store.arrayContains(keypath, value: value)
    }
    
    // MARK: - Writing State
    
    public func set(_ keypath: String, value: Any?) {
        store.set(keypath, value: value)
    }
    
    public func initialize(from state: [String: Document.StateValue]?) {
        store.initialize(from: state)
    }
    
    // MARK: - Array Operations
    
    public func appendToArray(_ keypath: String, value: Any) {
        store.appendToArray(keypath, value: value)
    }
    
    public func removeFromArray(_ keypath: String, value: Any) {
        store.removeFromArray(keypath, value: value)
    }
    
    public func removeFromArray(_ keypath: String, at index: Int) {
        store.removeFromArray(keypath, at: index)
    }
    
    public func toggleInArray(_ keypath: String, value: Any) {
        store.toggleInArray(keypath, value: value)
    }
    
    // MARK: - Dirty Tracking
    
    public var hasDirtyPaths: Bool {
        store.hasDirtyPaths
    }
    
    public func consumeDirtyPaths() -> Set<String> {
        store.consumeDirtyPaths()
    }
    
    public func isDirty(_ path: String) -> Bool {
        store.isDirty(path)
    }
    
    public func clearDirtyPaths() {
        store.clearDirtyPaths()
    }
    
    // MARK: - Callbacks
    
    @discardableResult
    public func onStateChange(_ callback: @escaping StateChangeCallback) -> UUID {
        store.onStateChange(callback)
    }
    
    public func removeStateChangeCallback(_ id: UUID) {
        store.removeStateChangeCallback(id)
    }
    
    public func removeAllCallbacks() {
        store.removeAllCallbacks()
    }
    
    // MARK: - Typed Observers
    
    @discardableResult
    public func observe<T: Decodable>(
        _ keypath: String,
        as type: T.Type,
        callback: @escaping (T?) -> Void
    ) -> UUID {
        // Implement typed observation using the callback system
        return store.onStateChange { [weak self] path, _, _ in
            guard path == keypath || path.hasPrefix(keypath + ".") else { return }
            let decoded: T? = self?.getTyped(keypath, as: type)
            callback(decoded)
        }
    }
    
    @discardableResult
    public func observe<T: Decodable>(
        _ keypath: String,
        as type: T.Type,
        onChange: @escaping (_ old: T?, _ new: T?) -> Void
    ) -> UUID {
        // Implement typed observation with old/new values
        return store.onStateChange { [weak self] path, oldValue, _ in
            guard path == keypath || path.hasPrefix(keypath + ".") else { return }
            
            let oldDecoded: T?
            if let oldValue = oldValue {
                oldDecoded = self?.decodeValue(oldValue, as: type)
            } else {
                oldDecoded = nil
            }
            
            let newDecoded: T? = self?.getTyped(keypath, as: type)
            onChange(oldDecoded, newDecoded)
        }
    }
    
    private func decodeValue<T: Decodable>(_ value: Any, as type: T.Type) -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [])
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
    
    private func getTyped<T: Decodable>(_ keypath: String, as type: T.Type) -> T? {
        guard let value = store.get(keypath) else { return nil }
        return decodeValue(value, as: type)
    }
    
    // MARK: - Snapshot
    
    public func snapshot() -> [String: Any] {
        store.snapshot()
    }
    
    public func restore(from snapshot: [String: Any]) {
        store.restore(from: snapshot)
    }
    
    // MARK: - Expression Evaluation
    
    public func evaluate(expression: String) -> Any {
        store.evaluate(expression: expression)
    }
    
    public func interpolate(_ template: String) -> String {
        store.interpolate(template)
    }
    
    // MARK: - SwiftUI Bindings
    
    /// Get a SwiftUI Binding for two-way data binding.
    public func binding(for keypath: String) -> Binding<String> {
        Binding(
            get: { [weak self] in
                self?.get(keypath) as? String ?? ""
            },
            set: { [weak self] newValue in
                self?.set(keypath, value: newValue)
            }
        )
    }
    
    /// Get a SwiftUI Binding for a boolean value.
    public func boolBinding(for keypath: String) -> Binding<Bool> {
        Binding(
            get: { [weak self] in
                self?.get(keypath) as? Bool ?? false
            },
            set: { [weak self] newValue in
                self?.set(keypath, value: newValue)
            }
        )
    }
    
    /// Get a SwiftUI Binding for a double value.
    public func doubleBinding(for keypath: String) -> Binding<Double> {
        Binding(
            get: { [weak self] in
                self?.get(keypath) as? Double ?? 0.0
            },
            set: { [weak self] newValue in
                self?.set(keypath, value: newValue)
            }
        )
    }
}
