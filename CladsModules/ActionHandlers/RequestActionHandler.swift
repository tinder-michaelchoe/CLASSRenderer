//
//  RequestActionHandler.swift
//  CladsModules
//
//  Handler for HTTP requests with cancellation and debug logging support.
//

import CLADS
import Foundation

/// Handler for HTTP requests (POST, PUT, PATCH, DELETE) with cancellation support.
///
/// Must be a `class` (not struct) because:
/// - Tracks mutable state (in-flight tasks)
/// - Needs to be referenced by CancelRequestActionHandler
/// - Registered as singleton in ActionRegistry
///
/// Example JSON:
/// ```json
/// {
///   "type": "request",
///   "method": "POST",
///   "url": "https://api.example.com/users",
///   "body": [
///     { "path": "form.name" },
///     { "path": "form.email", "as": "emailAddress" }
///   ],
///   "loadingPath": "api.isLoading",
///   "responsePath": "api.response",
///   "errorPath": "api.error",
///   "onSuccess": "handleSuccess",
///   "onError": "handleError"
/// }
/// ```
public final class RequestActionHandler: CancellableActionHandler {
    public static let actionType = "request"

    /// Composite key for task tracking: "documentId:requestId"
    private typealias TaskKey = String

    /// Thread-safe storage for in-flight tasks
    private var activeTasks: [TaskKey: Task<Void, Never>] = [:]
    private let lock = NSLock()

    /// URLSession for making requests (injectable for testing)
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Task Key Helpers

    private func taskKey(documentId: String, requestId: String) -> TaskKey {
        return "\(documentId):\(requestId)"
    }

    // MARK: - CancellableActionHandler

    public func cancel(requestId: String, documentId: String) {
        let key = taskKey(documentId: documentId, requestId: requestId)
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

    // MARK: - ActionHandler

    @MainActor
    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        // Parse parameters
        guard let method = parameters.string("method")?.uppercased(),
              ["GET", "POST", "PUT", "PATCH", "DELETE"].contains(method) else {
            print("RequestActionHandler: Invalid or missing 'method' parameter. Must be GET, POST, PUT, PATCH, or DELETE.")
            return
        }

        guard let urlTemplate = parameters.string("url") else {
            print("RequestActionHandler: Missing 'url' parameter")
            return
        }

        let requestId = parameters.string("requestId") ?? UUID().uuidString
        let documentId = context.documentId
        let debug = parameters.bool("debug") ?? false
        let timeout = TimeInterval(parameters.int("timeout") ?? 30)
        let contentType = parameters.string("contentType") ?? "json"

        let loadingPath = parameters.string("loadingPath")
        let responsePath = parameters.string("responsePath")
        let errorPath = parameters.string("errorPath")
        let onSuccess = parameters.string("onSuccess")
        let onError = parameters.string("onError")

        // Cancel existing task with same requestId+documentId
        cancel(requestId: requestId, documentId: documentId)

        // Set loading state
        if let loadingPath = loadingPath {
            context.stateStore.set(loadingPath, value: true)
        }

        // Clear previous error
        if let errorPath = errorPath {
            context.stateStore.set(errorPath, value: nil)
        }

        // Interpolate URL
        let interpolatedUrl = context.stateStore.interpolate(urlTemplate)

        // Build query params
        var urlComponents = URLComponents(string: interpolatedUrl)
        if let queryParamsArray = parameters.array("queryParams") {
            var queryItems: [URLQueryItem] = urlComponents?.queryItems ?? []
            for param in queryParamsArray {
                if let value = resolveParamValue(param, stateStore: context.stateStore) {
                    let key = resolveParamKey(param)
                    queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
                }
            }
            if !queryItems.isEmpty {
                urlComponents?.queryItems = queryItems
            }
        }

        // Validate URL
        guard let url = urlComponents?.url else {
            let errorInfo: [String: Any] = [
                "statusCode": -1,
                "message": "Invalid URL: \(interpolatedUrl)",
                "code": "invalidURL"
            ]
            handleError(
                errorInfo: errorInfo,
                loadingPath: loadingPath,
                errorPath: errorPath,
                onError: onError,
                context: context,
                debug: debug,
                requestId: requestId
            )
            return
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout

        // Add headers
        if let headersArray = parameters.array("headers") {
            for header in headersArray {
                guard let name = header["name"] as? String else { continue }
                let value: String
                if let staticValue = header["value"] as? String {
                    value = context.stateStore.interpolate(staticValue)
                } else if let path = header["path"] as? String,
                          let stateValue = context.stateStore.get(path) {
                    value = String(describing: stateValue)
                } else {
                    continue
                }
                request.setValue(value, forHTTPHeaderField: name)
            }
        }

        // Build body
        if let bodyArray = parameters.array("body"), !bodyArray.isEmpty {
            var bodyDict: [String: Any] = [:]
            for param in bodyArray {
                let key = resolveParamKey(param)
                if let value = resolveParamValue(param, stateStore: context.stateStore) {
                    bodyDict[key] = value
                }
            }

            if contentType == "formUrlEncoded" {
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                let formString = bodyDict.map { "\($0.key)=\(urlEncode(String(describing: $0.value)))" }.joined(separator: "&")
                request.httpBody = formString.data(using: .utf8)
            } else {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict, options: [])
            }
        }

        // Log request if debug
        if debug {
            logRequest(request, requestId: requestId)
        }

        // Create and track task
        let key = taskKey(documentId: documentId, requestId: requestId)
        let startTime = Date()

        let task = Task { [weak self] in
            guard let self = self else { return }

            do {
                let (data, response) = try await self.session.data(for: request)

                // Check for cancellation
                if Task.isCancelled {
                    await MainActor.run {
                        self.handleCancellation(
                            requestId: requestId,
                            loadingPath: loadingPath,
                            errorPath: errorPath,
                            context: context
                        )
                    }
                    return
                }

                let duration = Date().timeIntervalSince(startTime) * 1000 // ms

                guard let httpResponse = response as? HTTPURLResponse else {
                    let errorInfo: [String: Any] = [
                        "statusCode": -1,
                        "message": "Invalid response type",
                        "code": "invalidResponse"
                    ]
                    await MainActor.run {
                        self.handleError(
                            errorInfo: errorInfo,
                            loadingPath: loadingPath,
                            errorPath: errorPath,
                            onError: onError,
                            context: context,
                            debug: debug,
                            requestId: requestId
                        )
                    }
                    return
                }

                let statusCode = httpResponse.statusCode

                // Log response if debug
                if debug {
                    self.logResponse(httpResponse, data: data, requestId: requestId, duration: duration, isError: statusCode >= 400)
                }

                // Handle success (2xx)
                if (200...299).contains(statusCode) {
                    await MainActor.run {
                        self.handleSuccess(
                            data: data,
                            response: httpResponse,
                            loadingPath: loadingPath,
                            responsePath: responsePath,
                            onSuccess: onSuccess,
                            context: context
                        )
                    }
                } else {
                    // Handle HTTP error (4xx, 5xx)
                    var errorInfo: [String: Any] = [
                        "statusCode": statusCode,
                        "message": HTTPURLResponse.localizedString(forStatusCode: statusCode)
                    ]
                    if let bodyDict = try? JSONSerialization.jsonObject(with: data, options: []) {
                        errorInfo["body"] = bodyDict
                    } else if let bodyString = String(data: data, encoding: .utf8) {
                        errorInfo["body"] = bodyString
                    }
                    await MainActor.run {
                        self.handleError(
                            errorInfo: errorInfo,
                            loadingPath: loadingPath,
                            errorPath: errorPath,
                            onError: onError,
                            context: context,
                            debug: false, // Already logged above
                            requestId: requestId
                        )
                    }
                }
            } catch {
                // Check for cancellation
                if Task.isCancelled || (error as NSError).code == NSURLErrorCancelled {
                    await MainActor.run {
                        self.handleCancellation(
                            requestId: requestId,
                            loadingPath: loadingPath,
                            errorPath: errorPath,
                            context: context
                        )
                    }
                    return
                }

                // Network error
                let nsError = error as NSError
                let errorInfo: [String: Any] = [
                    "statusCode": -1,
                    "message": error.localizedDescription,
                    "code": nsError.domain == NSURLErrorDomain ? "NSURLError\(nsError.code)" : nsError.domain
                ]
                if debug {
                    self.logNetworkError(error, requestId: requestId)
                }
                await MainActor.run {
                    self.handleError(
                        errorInfo: errorInfo,
                        loadingPath: loadingPath,
                        errorPath: errorPath,
                        onError: onError,
                        context: context,
                        debug: false,
                        requestId: requestId
                    )
                }
            }

            // Remove from active tasks
            self.lock.lock()
            self.activeTasks.removeValue(forKey: key)
            self.lock.unlock()
        }

        lock.lock()
        activeTasks[key] = task
        lock.unlock()

        // Wait for task completion
        await task.value
    }

    // MARK: - Parameter Helpers

    private func resolveParamKey(_ param: [String: Any]) -> String {
        // If "as" is specified, use it
        if let asKey = param["as"] as? String {
            return asKey
        }
        // Otherwise derive from path (last segment)
        if let path = param["path"] as? String {
            return path.split(separator: ".").last.map(String.init) ?? path
        }
        // Fallback for literal without "as"
        return "value"
    }

    @MainActor
    private func resolveParamValue(_ param: [String: Any], stateStore: StateStoring) -> Any? {
        // Check for literal value first
        if let literal = param["literal"] {
            return literal
        }
        // Otherwise read from state path
        if let path = param["path"] as? String {
            return stateStore.get(path)
        }
        return nil
    }

    private func urlEncode(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }

    // MARK: - Response Handlers

    @MainActor
    private func handleSuccess(
        data: Data,
        response: HTTPURLResponse,
        loadingPath: String?,
        responsePath: String?,
        onSuccess: String?,
        context: ActionExecutionContext
    ) {
        // Set loading false
        if let loadingPath = loadingPath {
            context.stateStore.set(loadingPath, value: false)
        }

        // Parse and store response
        if let responsePath = responsePath {
            // Handle 204 No Content
            if response.statusCode == 204 || data.isEmpty {
                context.stateStore.set(responsePath, value: NSNull())
            } else {
                // Parse based on content type
                let contentType = response.value(forHTTPHeaderField: "Content-Type") ?? ""
                if contentType.contains("application/json") {
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                        context.stateStore.set(responsePath, value: jsonObject)
                    } else {
                        context.stateStore.set(responsePath, value: String(data: data, encoding: .utf8) ?? "")
                    }
                } else {
                    // Text or other
                    context.stateStore.set(responsePath, value: String(data: data, encoding: .utf8) ?? "")
                }
            }
        }

        // Execute onSuccess action
        if let onSuccess = onSuccess {
            Task {
                await context.executeAction(id: onSuccess)
            }
        }
    }

    @MainActor
    private func handleError(
        errorInfo: [String: Any],
        loadingPath: String?,
        errorPath: String?,
        onError: String?,
        context: ActionExecutionContext,
        debug: Bool,
        requestId: String
    ) {
        // Set loading false
        if let loadingPath = loadingPath {
            context.stateStore.set(loadingPath, value: false)
        }

        // Store error
        if let errorPath = errorPath {
            context.stateStore.set(errorPath, value: errorInfo)
        }

        // Execute onError action
        if let onError = onError {
            Task {
                await context.executeAction(id: onError)
            }
        }
    }

    @MainActor
    private func handleCancellation(
        requestId: String,
        loadingPath: String?,
        errorPath: String?,
        context: ActionExecutionContext
    ) {
        // Set loading false
        if let loadingPath = loadingPath {
            context.stateStore.set(loadingPath, value: false)
        }

        // Set cancellation error (but don't call onError)
        if let errorPath = errorPath {
            let cancellationError: [String: Any] = [
                "cancelled": true,
                "requestId": requestId,
                "message": "Request was cancelled"
            ]
            context.stateStore.set(errorPath, value: cancellationError)
        }
    }

    // MARK: - Debug Logging

    private func logRequest(_ request: URLRequest, requestId: String) {
        var log = """
        ┌─────────────────────────────────────────────────────────────
        │ 🌐 CLADS Request [\(requestId)]
        ├─────────────────────────────────────────────────────────────
        │ \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")
        """

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            log += "\n│ \n│ Headers:"
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                // Mask Authorization header value
                let displayValue = key.lowercased() == "authorization"
                    ? maskToken(value)
                    : value
                log += "\n│   \(key): \(displayValue)"
            }
        }

        if let body = request.httpBody, let bodyString = formatJSON(body) {
            log += "\n│ \n│ Body:\n\(indent(bodyString, prefix: "│   "))"
        }

        log += "\n└─────────────────────────────────────────────────────────────"
        print(log)
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data, requestId: String, duration: Double, isError: Bool) {
        let emoji = isError ? "❌" : "✅"
        let statusText = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
        var log = """
        ┌─────────────────────────────────────────────────────────────
        │ \(emoji) CLADS Response [\(requestId)] - \(response.statusCode) \(statusText) (\(Int(duration))ms)
        ├─────────────────────────────────────────────────────────────
        """

        let relevantHeaders = response.allHeaderFields.filter {
            let key = String(describing: $0.key).lowercased()
            return key == "content-type" || key.hasPrefix("x-")
        }
        if !relevantHeaders.isEmpty {
            log += "\n│ Headers:"
            for (key, value) in relevantHeaders {
                log += "\n│   \(key): \(value)"
            }
        }

        if let bodyString = formatJSON(data) {
            log += "\n│ \n│ Body:\n\(indent(bodyString, prefix: "│   "))"
        }

        log += "\n└─────────────────────────────────────────────────────────────"
        print(log)
    }

    private func logNetworkError(_ error: Error, requestId: String) {
        let log = """
        ┌─────────────────────────────────────────────────────────────
        │ ❌ CLADS Network Error [\(requestId)]
        ├─────────────────────────────────────────────────────────────
        │ \(error.localizedDescription)
        └─────────────────────────────────────────────────────────────
        """
        print(log)
    }

    private func maskToken(_ value: String) -> String {
        guard value.count > 10 else { return "***" }
        let prefix = String(value.prefix(6))
        let suffix = String(value.suffix(4))
        return "\(prefix)...\(suffix)"
    }

    private func formatJSON(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return String(data: data, encoding: .utf8)
        }
        return prettyString
    }

    private func indent(_ string: String, prefix: String) -> String {
        return string.split(separator: "\n", omittingEmptySubsequences: false)
            .map { "\(prefix)\($0)" }
            .joined(separator: "\n")
    }
}
