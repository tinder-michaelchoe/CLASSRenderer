//
//  HTTPRequestExampleView.swift
//  ScalsExamples
//
//  Example demonstrating the HTTP request action.
//

import SwiftUI
import SCALS
import ScalsModules

/// Example demonstrating HTTP POST request action
public struct HTTPRequestExampleView: View {
    public init() {}
    
    public var body: some View {
        ScalsRendererView(jsonString: httpRequestJSON)
            .navigationTitle("HTTP Request")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - JSON Definition

/// Example JSON demonstrating HTTP request action
public let httpRequestJSON = """
{
  "id": "http-request-example",
  "version": "1.0",
  "state": {
    "form": {
      "title": "",
      "body": ""
    },
    "api": {
      "loading": false,
      "response": null,
      "error": null
    }
  },
  "styles": {
    "title": { "fontSize": 24, "fontWeight": "bold", "textColor": "#000000" },
    "subtitle": { "fontSize": 14, "textColor": "#666666" },
    "fieldLabel": { "fontSize": 14, "fontWeight": "medium", "textColor": "#333333" },
    "field": { "fontSize": 16, "textColor": "#000000", "backgroundColor": "#FFFFFF", "cornerRadius": 8, "padding": { "horizontal": 12, "vertical": 12 } },
    "responseTitle": { "fontSize": 16, "fontWeight": "semibold", "textColor": "#007AFF" },
    "responseBody": { "fontSize": 14, "textColor": "#333333" },
    "errorText": { "fontSize": 14, "textColor": "#FF3B30" },
    "successText": { "fontSize": 14, "textColor": "#34C759" },
    "submitButton": { "backgroundColor": "#007AFF", "textColor": "#FFFFFF", "cornerRadius": 10, "fontWeight": "semibold", "padding": { "horizontal": 24, "vertical": 14 } },
    "cancelButton": { "backgroundColor": "#FF3B30", "textColor": "#FFFFFF", "cornerRadius": 10, "fontWeight": "semibold", "padding": { "horizontal": 24, "vertical": 14 } },
    "clearButton": { "backgroundColor": "#E5E5EA", "textColor": "#333333", "cornerRadius": 10, "padding": { "horizontal": 24, "vertical": 14 } }
  },
  "actions": {
    "submitPost": {
      "type": "request",
      "requestId": "createPost",
      "method": "POST",
      "url": "https://jsonplaceholder.typicode.com/posts",
      "body": [
        { "path": "form.title" },
        { "path": "form.body" },
        { "literal": 1, "as": "userId" }
      ],
      "debug": true,
      "loadingPath": "api.loading",
      "responsePath": "api.response",
      "errorPath": "api.error",
      "onSuccess": "showSuccess",
      "onError": "showError"
    },
    "showSuccess": {
      "type": "showAlert",
      "title": "Success!",
      "message": { "type": "binding", "template": "Post created with ID: ${api.response.id}" }
    },
    "showError": {
      "type": "showAlert",
      "title": "Error",
      "message": { "type": "binding", "template": "Request failed: ${api.error.message}" }
    },
    "cancelRequest": {
      "type": "cancelRequest",
      "requestId": "createPost"
    },
    "clearForm": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "form.title", "value": "" },
        { "type": "setState", "path": "form.body", "value": "" },
        { "type": "setState", "path": "api.response", "value": null },
        { "type": "setState", "path": "api.error", "value": null }
      ]
    }
  },
  "root": {
    "backgroundColor": "#F2F2F7",
    "edgeInsets": { "top": 20, "leading": 20, "trailing": 20, "bottom": 20 },
    "children": [{
      "type": "vstack",
      "spacing": 20,
      "alignment": "leading",
      "children": [
        {
          "type": "vstack",
          "spacing": 4,
          "alignment": "leading",
          "children": [
            { "type": "label", "text": "HTTP Request Demo", "styleId": "title" },
            { "type": "label", "text": "Creates a post using JSONPlaceholder API", "styleId": "subtitle" }
          ]
        },
        {
          "type": "vstack",
          "spacing": 16,
          "children": [
            {
              "type": "vstack",
              "spacing": 6,
              "alignment": "leading",
              "children": [
                { "type": "label", "text": "Title", "styleId": "fieldLabel" },
                { "type": "textfield", "placeholder": "Enter post title...", "styleId": "field", "bind": "form.title" }
              ]
            },
            {
              "type": "vstack",
              "spacing": 6,
              "alignment": "leading",
              "children": [
                { "type": "label", "text": "Body", "styleId": "fieldLabel" },
                { "type": "textfield", "placeholder": "Enter post content...", "styleId": "field", "bind": "form.body" }
              ]
            }
          ]
        },
        {
          "type": "hstack",
          "spacing": 12,
          "children": [
            { "type": "button", "text": "Submit Post", "styleId": "submitButton", "actions": { "onTap": "submitPost" } },
            { "type": "button", "text": "Clear", "styleId": "clearButton", "actions": { "onTap": "clearForm" } }
          ]
        },
        {
          "type": "vstack",
          "spacing": 8,
          "alignment": "leading",
          "children": [
            { "type": "label", "text": "Response:", "styleId": "responseTitle" },
            { "type": "label", "text": "ID: ${api.response.id}", "styleId": "successText" },
            { "type": "label", "text": "Title: ${api.response.title}", "styleId": "responseBody" },
            { "type": "label", "text": "Body: ${api.response.body}", "styleId": "responseBody" }
          ]
        }
      ]
    }]
  }
}
"""

#Preview {
    NavigationStack {
        HTTPRequestExampleView()
    }
}
