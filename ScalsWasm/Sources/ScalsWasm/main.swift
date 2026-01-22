//
//  main.swift
//  ScalsWasm
//
//  WebAssembly entry point for SCALS preview rendering.
//  Exports C-compatible functions for JavaScript interop.
//

import SCALS
import ScalsResolvers
import Foundation

// MARK: - Global State

// Wasm is single-instance, so we use global state
private var componentRegistry: ComponentResolverRegistry?
private var sectionLayoutRegistry: SectionLayoutConfigResolverRegistry?
private var isInitialized = false

// MARK: - Exported Functions

/// Initialize the SCALS renderer with all component and layout resolvers.
/// Must be called before any render calls.
@_cdecl("clads_init")
@_expose(wasm, "clads_init")
public func cladsInit() {
    guard !isInitialized else { return }

    // Register all component resolvers
    let compRegistry = ComponentResolverRegistry()
    compRegistry.register(TextComponentResolver())
    compRegistry.register(ButtonComponentResolver())
    compRegistry.register(ImageComponentResolver())
    compRegistry.register(ToggleComponentResolver())
    compRegistry.register(SliderComponentResolver())
    compRegistry.register(TextFieldComponentResolver())
    compRegistry.register(GradientComponentResolver())
    compRegistry.register(DividerComponentResolver())
    compRegistry.register(ShapeComponentResolver())
    // PageIndicator not yet in IR - excluding from WASM build
    componentRegistry = compRegistry

    // Register all section layout resolvers
    let sectionRegistry = SectionLayoutConfigResolverRegistry()
    sectionRegistry.register(HorizontalLayoutConfigResolver())
    sectionRegistry.register(ListLayoutConfigResolver())
    sectionRegistry.register(GridLayoutConfigResolver())
    sectionRegistry.register(FlowLayoutConfigResolver())
    sectionLayoutRegistry = sectionRegistry

    isInitialized = true
}

/// Render a SCALS JSON document to HTML.
///
/// - Parameters:
///   - jsonPtr: Pointer to UTF-8 encoded JSON string
///   - jsonLen: Length of the JSON string in bytes
/// - Returns: Pointer to UTF-8 encoded result string (HTML or JSON error).
///            Caller must free with `clads_free`.
#if arch(wasm32)
// WASM is single-threaded, so we use @preconcurrency to satisfy the compiler
// without requiring the full Swift concurrency runtime
@_cdecl("clads_render")
@_expose(wasm, "clads_render")
@preconcurrency @MainActor
public func cladsRender(jsonPtr: UnsafePointer<CChar>, jsonLen: Int32) -> UnsafeMutablePointer<CChar>? {
    return _cladsRenderImpl(jsonPtr: jsonPtr, jsonLen: jsonLen)
}
#else
@_cdecl("clads_render")
@MainActor
public func cladsRender(jsonPtr: UnsafePointer<CChar>, jsonLen: Int32) -> UnsafeMutablePointer<CChar>? {
    return _cladsRenderImpl(jsonPtr: jsonPtr, jsonLen: jsonLen)
}
#endif

/// Internal implementation shared between WASM and native builds.
@MainActor
private func _cladsRenderImpl(jsonPtr: UnsafePointer<CChar>, jsonLen: Int32) -> UnsafeMutablePointer<CChar>? {
    guard let registry = componentRegistry else {
        return createErrorResponse("Not initialized. Call clads_init() first.")
    }

    // Convert input to Data
    let jsonData = Data(bytes: jsonPtr, count: Int(jsonLen))

    do {
        // Parse the document
        let document = try JSONDecoder().decode(Document.Definition.self, from: jsonData)

        // Create resolver and resolve to render tree
        // Note: In Wasm, we run synchronously since it's single-threaded.
        let resolver = Resolver(document: document, componentRegistry: registry)
        let renderTree = try resolver.resolve()

        // Render to HTML
        let renderer = HTMLRenderer()
        let output = renderer.render(renderTree)

        return strdup(output.fullDocument)
    } catch let decodingError as DecodingError {
        return createErrorResponse(formatDecodingError(decodingError))
    } catch {
        return createErrorResponse(error.localizedDescription)
    }
}

/// Free a string allocated by clads_render.
///
/// - Parameter ptr: Pointer returned by clads_render
@_cdecl("clads_free")
@_expose(wasm, "clads_free")
public func cladsFree(ptr: UnsafeMutablePointer<CChar>?) {
    free(ptr)
}

/// Allocate memory for use by JavaScript.
///
/// - Parameter size: Number of bytes to allocate
/// - Returns: Pointer to allocated memory, or nil on failure
@_cdecl("clads_alloc")
@_expose(wasm, "clads_alloc")
public func cladsAlloc(size: Int32) -> UnsafeMutableRawPointer? {
    return malloc(Int(size))
}

// MARK: - Private Helpers

/// Create a JSON error response string.
private func createErrorResponse(_ message: String) -> UnsafeMutablePointer<CChar>? {
    let escaped = message
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
    return strdup("{\"error\": \"\(escaped)\"}")
}

/// Format a DecodingError for user-friendly display.
private func formatDecodingError(_ error: DecodingError) -> String {
    switch error {
    case .keyNotFound(let key, let context):
        let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
        return "Missing required key '\(key.stringValue)' at path: \(path.isEmpty ? "root" : path)"
    case .valueNotFound(let type, let context):
        let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
        return "Missing value of type '\(type)' at path: \(path.isEmpty ? "root" : path)"
    case .typeMismatch(let type, let context):
        let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
        return "Type mismatch: expected '\(type)' at path: \(path.isEmpty ? "root" : path)"
    case .dataCorrupted(let context):
        let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
        return "Data corrupted at path: \(path.isEmpty ? "root" : path). \(context.debugDescription)"
    @unknown default:
        return error.localizedDescription
    }
}
