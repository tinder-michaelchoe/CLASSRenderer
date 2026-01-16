//
//  StateStore.swift
//  CladsRendererFramework
//
//  Platform-agnostic state store for CLADS documents.
//  Provides key-value storage with dirty tracking and change notifications.
//
//  **Important**: This file should remain platform-agnostic. Do NOT import
//  SwiftUI or UIKit here. Platform-specific wrappers (like ObservableStateStore)
//  belong in the renderer layer.
//

import Foundation

// MARK: - State Change Callback

/// Callback invoked when state changes
public typealias StateChangeCallback = (_ path: String, _ oldValue: Any?, _ newValue: Any?) -> Void

// MARK: - State Storing Protocol

/// Protocol for state storage, enabling dependency injection and testing.
public protocol StateStoring: AnyObject {
    // MARK: - Reading State

    func get(_ keypath: String) -> Any?
    func get<T>(_ keypath: String, as type: T.Type) -> T?
    func getArray(_ keypath: String) -> [Any]?
    func getArrayCount(_ keypath: String) -> Int
    func arrayContains(_ keypath: String, value: Any) -> Bool

    // MARK: - Writing State

    func set(_ keypath: String, value: Any?)
    func initialize(from state: [String: Document.StateValue]?)

    // MARK: - Array Operations

    func appendToArray(_ keypath: String, value: Any)
    func removeFromArray(_ keypath: String, value: Any)
    func removeFromArray(_ keypath: String, at index: Int)
    func toggleInArray(_ keypath: String, value: Any)

    // MARK: - Dirty Tracking

    var hasDirtyPaths: Bool { get }
    func consumeDirtyPaths() -> Set<String>
    func isDirty(_ path: String) -> Bool
    func clearDirtyPaths()

    // MARK: - Callbacks

    @discardableResult
    func onStateChange(_ callback: @escaping StateChangeCallback) -> UUID
    func removeStateChangeCallback(_ id: UUID)
    func removeAllCallbacks()

    // MARK: - Typed Observers

    /// Observe state changes at a keypath with type-safe decoding.
    @discardableResult
    func observe<T: Decodable>(_ keypath: String, as type: T.Type, callback: @escaping (T?) -> Void) -> UUID

    /// Observe with both old and new values for diffing.
    @discardableResult
    func observe<T: Decodable>(_ keypath: String, as type: T.Type, onChange: @escaping (_ old: T?, _ new: T?) -> Void) -> UUID

    // MARK: - Snapshot

    func snapshot() -> [String: Any]
    func restore(from snapshot: [String: Any])

    // MARK: - Expression Evaluation

    func evaluate(expression: String) -> Any
    func interpolate(_ template: String) -> String
}

// MARK: - State Store

/// Platform-agnostic state store for documents with dirty tracking.
///
/// Provides:
/// - Key-value storage with nested keypath access
/// - Dirty path tracking for efficient updates
/// - Change callbacks for reactive updates
/// - Expression evaluation and template interpolation
/// - Thread-safe access using NSLock
///
/// For SwiftUI integration, use `ObservableStateStore` from the renderer layer,
/// which wraps this class and provides `ObservableObject` conformance.
///
/// Example:
/// ```swift
/// let store = StateStore()
/// store.set("user.name", value: "John")
/// let name = store.get("user.name") as? String  // "John"
///
/// store.onStateChange { path, old, new in
///     print("\(path) changed from \(old) to \(new)")
/// }
/// ```
public final class StateStore: StateStoring {
    private var values: [String: Any] = [:]

    // MARK: - Thread Safety

    private let lock = NSLock()

    // MARK: - Dependencies

    private let keypathAccessor = KeypathAccessor()
    private let expressionEvaluator = ExpressionEvaluator()

    // MARK: - Dirty Tracking

    private var dirtyPaths: Set<String> = []

    public var hasDirtyPaths: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !dirtyPaths.isEmpty
    }

    // MARK: - Callbacks

    private var changeCallbacks: [UUID: StateChangeCallback] = [:]

    // MARK: - Initialization

    public init() {}

    /// Initialize with state from a document.
    public func initialize(from state: [String: Document.StateValue]?) {
        guard let state = state else { return }
        lock.lock()
        defer { lock.unlock() }
        for (key, value) in state {
            values[key] = unwrap(value)
        }
    }

    // MARK: - Reading State

    /// Get a value at the given keypath.
    ///
    /// Supports:
    /// - Simple keys: `"count"`
    /// - Nested keys: `"user.name"`
    /// - Array indices: `"items[0]"` or `"items.0"`
    /// - Mixed: `"users[0].name"`
    public func get(_ keypath: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        return keypathAccessor.get(keypath, from: values)
    }

    /// Get a value as a specific type.
    public func get<T>(_ keypath: String, as type: T.Type = T.self) -> T? {
        get(keypath) as? T
    }

    /// Get an array at the given keypath.
    public func getArray(_ keypath: String) -> [Any]? {
        get(keypath) as? [Any]
    }

    /// Get the count of an array at the given keypath.
    public func getArrayCount(_ keypath: String) -> Int {
        getArray(keypath)?.count ?? 0
    }

    /// Check if an array contains a value.
    public func arrayContains(_ keypath: String, value: Any) -> Bool {
        guard let array = getArray(keypath) else { return false }
        return array.contains { areEqual($0, value) }
    }

    // MARK: - Writing State

    /// Set a value at the given keypath.
    public func set(_ keypath: String, value: Any?) {
        lock.lock()
        let oldValue = keypathAccessor.get(keypath, from: values)
        keypathAccessor.set(keypath, value: value, in: &values)
        markDirtyUnsafe(keypath)
        let callbacks = changeCallbacks
        lock.unlock()
        
        // Notify callbacks outside the lock to avoid deadlocks
        notifyCallbacks(callbacks: callbacks, path: keypath, oldValue: oldValue, newValue: value)
    }

    // MARK: - Array Operations

    /// Append a value to an array.
    public func appendToArray(_ keypath: String, value: Any) {
        var array = getArray(keypath) ?? []
        array.append(value)
        set(keypath, value: array)
    }

    /// Remove a value from an array.
    public func removeFromArray(_ keypath: String, value: Any) {
        guard var array = getArray(keypath) else { return }
        array.removeAll { areEqual($0, value) }
        set(keypath, value: array)
    }

    /// Remove an item at a specific index from an array.
    public func removeFromArray(_ keypath: String, at index: Int) {
        guard var array = getArray(keypath), index >= 0, index < array.count else { return }
        array.remove(at: index)
        set(keypath, value: array)
    }

    /// Toggle a value in an array (add if missing, remove if present).
    public func toggleInArray(_ keypath: String, value: Any) {
        var array = getArray(keypath) ?? []
        if let index = array.firstIndex(where: { areEqual($0, value) }) {
            array.remove(at: index)
        } else {
            array.append(value)
        }
        set(keypath, value: array)
    }

    // MARK: - Dirty Tracking

    /// Mark a path as dirty (modified). Must be called with lock held.
    private func markDirtyUnsafe(_ path: String) {
        dirtyPaths.insert(path)

        // Also mark parent paths as dirty
        for parentPath in keypathAccessor.parentPaths(of: path) {
            dirtyPaths.insert(parentPath)
        }
    }

    /// Consume and return all dirty paths, clearing the dirty set.
    public func consumeDirtyPaths() -> Set<String> {
        lock.lock()
        defer { lock.unlock() }
        let paths = dirtyPaths
        dirtyPaths = []
        return paths
    }

    /// Check if a specific path is dirty.
    public func isDirty(_ path: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        if dirtyPaths.contains(path) { return true }

        // Check if any child path is dirty
        for dirtyPath in dirtyPaths {
            if dirtyPath.hasPrefix(path + ".") { return true }
        }

        return false
    }

    /// Clear all dirty paths without consuming.
    public func clearDirtyPaths() {
        lock.lock()
        defer { lock.unlock() }
        dirtyPaths = []
    }

    // MARK: - Callbacks

    /// Register a callback for state changes.
    @discardableResult
    public func onStateChange(_ callback: @escaping StateChangeCallback) -> UUID {
        lock.lock()
        defer { lock.unlock() }
        let id = UUID()
        changeCallbacks[id] = callback
        return id
    }

    /// Unregister a callback.
    public func removeStateChangeCallback(_ id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        changeCallbacks.removeValue(forKey: id)
    }

    /// Remove all callbacks.
    public func removeAllCallbacks() {
        lock.lock()
        defer { lock.unlock() }
        changeCallbacks.removeAll()
    }

    private func notifyCallbacks(callbacks: [UUID: StateChangeCallback], path: String, oldValue: Any?, newValue: Any?) {
        for callback in callbacks.values {
            callback(path, oldValue, newValue)
        }
    }

    // MARK: - Typed Observers

    /// Observe state changes at a keypath with type-safe decoding.
    ///
    /// Example:
    /// ```swift
    /// struct UserResponse: Codable {
    ///     let id: Int
    ///     let name: String
    /// }
    ///
    /// stateStore.observe("api.response", as: UserResponse.self) { response in
    ///     guard let user = response else { return }
    ///     print("User: \(user.name)")  // Compiler-safe!
    /// }
    /// ```
    @discardableResult
    public func observe<T: Decodable>(
        _ keypath: String,
        as type: T.Type,
        callback: @escaping (T?) -> Void
    ) -> UUID {
        return onStateChange { [weak self] path, _, _ in
            // Check if changed path is the target or a child of target
            guard path == keypath || path.hasPrefix(keypath + ".") else { return }

            let decoded: T? = self?.getTyped(keypath, as: type)
            callback(decoded)
        }
    }

    /// Observe with both old and new values for diffing.
    @discardableResult
    public func observe<T: Decodable>(
        _ keypath: String,
        as type: T.Type,
        onChange: @escaping (_ old: T?, _ new: T?) -> Void
    ) -> UUID {
        return onStateChange { [weak self] path, oldValue, newValue in
            // Check if changed path is the target or a child of target
            guard path == keypath || path.hasPrefix(keypath + ".") else { return }

            // Try to decode old value
            let oldDecoded: T?
            if let oldValue = oldValue {
                oldDecoded = self?.decodeValue(oldValue, as: type)
            } else {
                oldDecoded = nil
            }

            // Get current decoded value at keypath
            let newDecoded: T? = self?.getTyped(keypath, as: type)
            onChange(oldDecoded, newDecoded)
        }
    }

    /// Helper to decode an Any value to a typed object.
    private func decodeValue<T: Decodable>(_ value: Any, as type: T.Type) -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [])
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    // MARK: - Snapshot

    /// Get a snapshot of the current state.
    public func snapshot() -> [String: Any] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }

    /// Restore state from a snapshot.
    public func restore(from snapshot: [String: Any]) {
        lock.lock()
        values = snapshot
        for key in snapshot.keys {
            markDirtyUnsafe(key)
        }
        lock.unlock()
    }

    // MARK: - Expression Evaluation

    /// Evaluate an expression with state interpolation.
    public func evaluate(expression: String) -> Any {
        expressionEvaluator.evaluate(expression, using: self)
    }

    /// Interpolate template strings like "You pressed ${count} times".
    public func interpolate(_ template: String) -> String {
        expressionEvaluator.interpolate(template, using: self)
    }

    // MARK: - Typed State Support

    /// Get state as a typed Codable object.
    public func getTyped<T: Decodable>(_ type: T.Type = T.self) -> T? {
        lock.lock()
        let currentValues = values
        lock.unlock()
        
        do {
            let data = try JSONSerialization.data(withJSONObject: currentValues, options: [])
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    /// Get a nested value as a typed Codable object.
    public func getTyped<T: Decodable>(_ keypath: String, as type: T.Type = T.self) -> T? {
        guard let value = get(keypath) else { return nil }
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [])
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    /// Set state from a typed Codable object.
    public func setTyped<T: Encodable>(_ value: T) {
        do {
            let data = try JSONEncoder().encode(value)
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for (key, val) in dict {
                    set(key, value: val)
                }
            }
        } catch {
            // Silently fail if encoding fails
        }
    }

    /// Set a nested value from a typed Codable object.
    public func setTyped<T: Encodable>(_ keypath: String, value: T) {
        do {
            let data = try JSONEncoder().encode(value)
            let jsonValue = try JSONSerialization.jsonObject(with: data, options: [])
            set(keypath, value: jsonValue)
        } catch {
            // Silently fail if encoding fails
        }
    }

    // MARK: - Helpers

    /// Compare two Any values for equality.
    private func areEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        switch (lhs, rhs) {
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as String, let r as String): return l == r
        case (let l as Bool, let r as Bool): return l == r
        case (is NSNull, is NSNull): return true
        default: return false
        }
    }

    /// Unwrap a Document.StateValue to a native type.
    private func unwrap(_ stateValue: Document.StateValue) -> Any {
        switch stateValue {
        case .intValue(let v): return v
        case .doubleValue(let v): return v
        case .stringValue(let v): return v
        case .boolValue(let v): return v
        case .nullValue: return NSNull()
        case .arrayValue(let arr): return arr.map { unwrap($0) }
        case .objectValue(let obj): return obj.mapValues { unwrap($0) }
        }
    }
}

// MARK: - StateValueReading Conformance

extension StateStore: StateValueReading {
    public func getValue(_ keypath: String) -> Any? {
        get(keypath)
    }
}
