//
//  MockStateStore.swift
//  CLADSTests
//
//  Mock implementation of StateStoring for testing.
//

import Foundation
@testable import CLADS

/// Mock implementation of StateStoring for testing.
///
/// Provides a simple in-memory state store with tracking of method calls
/// for verification in tests.
///
/// Example usage:
/// ```swift
/// let mockStore = MockStateStore()
/// mockStore.values["count"] = 5
///
/// // Use in tests
/// let context = ActionContext(stateStore: mockStore, ...)
///
/// // Verify calls
/// #expect(mockStore.setCalls.contains { $0.path == "count" })
/// ```
public final class MockStateStore: StateStoring {
    
    // MARK: - State Storage
    
    public var values: [String: Any] = [:]
    public var arrays: [String: [Any]] = [:]
    
    // MARK: - Call Tracking
    
    public struct SetCall {
        public let path: String
        public let value: Any?
    }
    
    public var setCalls: [SetCall] = []
    public var getCalls: [String] = []
    
    // MARK: - Callbacks
    
    private var callbacks: [UUID: StateChangeCallback] = [:]
    private var dirtyPaths: Set<String> = []
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - StateStoring Implementation
    
    public func get(_ keypath: String) -> Any? {
        getCalls.append(keypath)
        return values[keypath]
    }
    
    public func get<T>(_ keypath: String, as type: T.Type) -> T? {
        get(keypath) as? T
    }
    
    public func getArray(_ keypath: String) -> [Any]? {
        arrays[keypath] ?? (values[keypath] as? [Any])
    }
    
    public func getArrayCount(_ keypath: String) -> Int {
        getArray(keypath)?.count ?? 0
    }
    
    public func arrayContains(_ keypath: String, value: Any) -> Bool {
        guard let array = getArray(keypath) else { return false }
        return array.contains { item in
            if let itemStr = item as? String, let valueStr = value as? String {
                return itemStr == valueStr
            }
            if let itemInt = item as? Int, let valueInt = value as? Int {
                return itemInt == valueInt
            }
            return false
        }
    }
    
    public func set(_ keypath: String, value: Any?) {
        let oldValue = values[keypath]
        setCalls.append(SetCall(path: keypath, value: value))
        values[keypath] = value
        dirtyPaths.insert(keypath)
        
        // Notify callbacks
        for callback in callbacks.values {
            callback(keypath, oldValue, value)
        }
    }
    
    public func initialize(from state: [String: Document.StateValue]?) {
        guard let state = state else { return }
        for (key, value) in state {
            values[key] = unwrap(value)
        }
    }
    
    // MARK: - Array Operations
    
    public func appendToArray(_ keypath: String, value: Any) {
        var array = getArray(keypath) ?? []
        array.append(value)
        set(keypath, value: array)
    }
    
    public func removeFromArray(_ keypath: String, value: Any) {
        guard var array = getArray(keypath) else { return }
        array.removeAll { item in
            if let itemStr = item as? String, let valueStr = value as? String {
                return itemStr == valueStr
            }
            if let itemInt = item as? Int, let valueInt = value as? Int {
                return itemInt == valueInt
            }
            return false
        }
        set(keypath, value: array)
    }
    
    public func removeFromArray(_ keypath: String, at index: Int) {
        guard var array = getArray(keypath), index >= 0, index < array.count else { return }
        array.remove(at: index)
        set(keypath, value: array)
    }
    
    public func toggleInArray(_ keypath: String, value: Any) {
        var array = getArray(keypath) ?? []
        if let index = array.firstIndex(where: { item in
            if let itemStr = item as? String, let valueStr = value as? String {
                return itemStr == valueStr
            }
            if let itemInt = item as? Int, let valueInt = value as? Int {
                return itemInt == valueInt
            }
            return false
        }) {
            array.remove(at: index)
        } else {
            array.append(value)
        }
        set(keypath, value: array)
    }
    
    // MARK: - Dirty Tracking
    
    public var hasDirtyPaths: Bool {
        !dirtyPaths.isEmpty
    }
    
    public func consumeDirtyPaths() -> Set<String> {
        let paths = dirtyPaths
        dirtyPaths = []
        return paths
    }
    
    public func isDirty(_ path: String) -> Bool {
        dirtyPaths.contains(path)
    }
    
    public func clearDirtyPaths() {
        dirtyPaths = []
    }
    
    // MARK: - Callbacks
    
    @discardableResult
    public func onStateChange(_ callback: @escaping StateChangeCallback) -> UUID {
        let id = UUID()
        callbacks[id] = callback
        return id
    }
    
    public func removeStateChangeCallback(_ id: UUID) {
        callbacks.removeValue(forKey: id)
    }
    
    public func removeAllCallbacks() {
        callbacks.removeAll()
    }
    
    // MARK: - Snapshot
    
    public func snapshot() -> [String: Any] {
        values
    }
    
    public func restore(from snapshot: [String: Any]) {
        values = snapshot
    }
    
    // MARK: - Expression Evaluation
    
    public func evaluate(expression: String) -> Any {
        // Simple implementation - just return the expression
        expression
    }
    
    public func interpolate(_ template: String) -> String {
        var result = template
        let pattern = "\\$\\{([^}]+)\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return template
        }
        
        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: template),
                  let keyRange = Range(match.range(at: 1), in: template) else {
                continue
            }
            let key = String(template[keyRange])
            let value = values[key].map { "\($0)" } ?? ""
            result.replaceSubrange(range, with: value)
        }
        return result
    }
    
    // MARK: - Helpers
    
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
    
    // MARK: - Test Helpers
    
    /// Reset all tracking and state
    public func reset() {
        values = [:]
        arrays = [:]
        setCalls = []
        getCalls = []
        callbacks = [:]
        dirtyPaths = []
    }
}
