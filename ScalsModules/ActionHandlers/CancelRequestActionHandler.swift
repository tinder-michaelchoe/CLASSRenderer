//
//  CancelRequestActionHandler.swift
//  ScalsModules
//
//  Handler for cancelling HTTP requests.
//

import SCALS
import Foundation

/// Handler for cancelling HTTP requests.
///
/// Example JSON to cancel a specific request:
/// ```json
/// {
///   "type": "cancelRequest",
///   "requestId": "createUser"
/// }
/// ```
///
/// Example JSON to cancel all requests for the current document:
/// ```json
/// {
///   "type": "cancelRequest"
/// }
/// ```
public struct CancelRequestActionHandler: ActionHandler {
    public static let actionType = "cancelRequest"

    public init() {}

    @MainActor
    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        // Get the request handler from registry
        guard let requestHandler = context.actionRegistry.getCancellableHandler(for: RequestActionHandler.actionType) else {
            print("CancelRequestActionHandler: RequestActionHandler not registered")
            return
        }

        let documentId = context.documentId

        if let requestId = parameters.string("requestId") {
            // Cancel specific request
            requestHandler.cancel(requestId: requestId, documentId: documentId)
        } else {
            // Cancel all requests for this document
            requestHandler.cancelAll(documentId: documentId)
        }
    }
}
