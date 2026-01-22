//
//  DesignSystemExampleView.swift
//  ScalsExamples
//
//  Example demonstrating Lightspeed design system integration with SCALS.
//

import SwiftUI
import SCALS
import ScalsModules

// MARK: - Design System Example JSON

/// Example JSON demonstrating Lightspeed design system integration.
///
/// Uses `@` prefix to reference design system styles:
/// - `@button.primary` → Lightspeed primary button with full component rendering
/// - `@button.secondary` → Lightspeed secondary button
/// - `@text.heading1` → Design system heading style (fallback to style tokens)
///
/// The LightspeedProvider handles both:
/// 1. Full component rendering (buttons use native LightspeedButton with animations)
/// 2. Style token fallback (text uses IR.Style from design system)
public let designSystemExampleJSON = """
{
  "id": "design-system-showcase",
  "version": "1.0",
  "designSystem": "lightspeed",
  "state": {
    "counter": 0,
    "username": "",
    "email": "",
    "isLoading": false
  },
  "actions": {
    "increment": {
      "type": "setState",
      "path": "counter",
      "value": { "$expr": "${counter} + 1" }
    },
    "decrement": {
      "type": "setState",
      "path": "counter",
      "value": { "$expr": "${counter} - 1" }
    },
    "reset": {
      "type": "setState",
      "path": "counter",
      "value": 0
    },
    "showPrimaryAlert": {
      "type": "showAlert",
      "title": "Primary Action",
      "message": "You tapped the primary button! This uses the native LightspeedButton component with press animation."
    },
    "showSecondaryAlert": {
      "type": "showAlert",
      "title": "Secondary Action",
      "message": "Secondary buttons are great for less prominent actions."
    },
    "showDestructiveAlert": {
      "type": "showAlert",
      "title": "Destructive Action",
      "message": "Destructive buttons are used for dangerous or irreversible actions."
    }
  },
  "root": {
    "backgroundColor": "#F9FAFB",
    "children": [
      {
        "type": "sectionLayout",
        "layoutType": "list",
        "sectionSpacing": 32,
        "contentInsets": { "top": 24, "leading": 20, "trailing": 20, "bottom": 40 },
        "sections": [
          {
            "layout": { "type": "list", "showsDividers": false },
            "children": [
              {
                "type": "vstack",
                "spacing": 8,
                "children": [
                  {
                    "type": "label",
                    "text": "Lightspeed",
                    "styleId": "@text.heading1"
                  },
                  {
                    "type": "label",
                    "text": "Design System Showcase",
                    "styleId": "@text.heading3"
                  },
                  {
                    "type": "label",
                    "text": "A complete overview of all implemented components and typography styles.",
                    "styleId": "@text.body"
                  }
                ]
              }
            ]
          },
          {
            "layout": { "type": "list", "showsDividers": false },
            "header": {
              "type": "label",
              "text": "TYPOGRAPHY",
              "styleId": "@text.caption"
            },
            "children": [
              {
                "type": "vstack",
                "spacing": 20,
                "children": [
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Display Heading", "styleId": "@text.heading1" },
                      { "type": "label", "text": "@text.heading1 · Merriweather Bold 32pt", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Section Heading", "styleId": "@text.heading2" },
                      { "type": "label", "text": "@text.heading2 · Merriweather SemiBold 24pt", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Subsection Heading", "styleId": "@text.heading3" },
                      { "type": "label", "text": "@text.heading3 · Merriweather Medium 20pt", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Body text for paragraphs and general content. The quick brown fox jumps over the lazy dog.", "styleId": "@text.body" },
                      { "type": "label", "text": "@text.body · Merriweather Regular 16pt", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Emphasized text with elegant italics for special callouts.", "styleId": "@text.bodyItalic" },
                      { "type": "label", "text": "@text.bodyItalic · Merriweather Italic 16pt", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Typography is the art of arranging type to make written language readable and beautiful.", "styleId": "@text.quote" },
                      { "type": "label", "text": "@text.quote · Merriweather Light Italic 18pt", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Form Label", "styleId": "@text.label" },
                      { "type": "label", "text": "@text.label · Merriweather Medium 14pt", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Caption and helper text for small labels", "styleId": "@text.caption" },
                      { "type": "label", "text": "@text.caption · Merriweather Light 12pt", "styleId": "@text.caption" }
                    ]
                  }
                ]
              }
            ]
          },
          {
            "layout": { "type": "list", "showsDividers": false },
            "header": {
              "type": "label",
              "text": "BUTTONS",
              "styleId": "@text.caption"
            },
            "children": [
              {
                "type": "vstack",
                "spacing": 16,
                "children": [
                  {
                    "type": "label",
                    "text": "Native LightspeedButton components with press animations and automatic dark mode adaptation.",
                    "styleId": "@text.body"
                  },
                  {
                    "type": "vstack",
                    "spacing": 12,
                    "children": [
                      {
                        "type": "button",
                        "text": "Primary Button",
                        "styleId": "@button.primary",
                        "fillWidth": true,
                        "actions": { "onTap": "showPrimaryAlert" }
                      },
                      { "type": "label", "text": "@button.primary · Main call-to-action", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 12,
                    "children": [
                      {
                        "type": "button",
                        "text": "Secondary Button",
                        "styleId": "@button.secondary",
                        "fillWidth": true,
                        "actions": { "onTap": "showSecondaryAlert" }
                      },
                      { "type": "label", "text": "@button.secondary · Alternative actions", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 12,
                    "children": [
                      {
                        "type": "button",
                        "text": "Destructive Button",
                        "styleId": "@button.destructive",
                        "fillWidth": true,
                        "actions": { "onTap": "showDestructiveAlert" }
                      },
                      { "type": "label", "text": "@button.destructive · Dangerous actions", "styleId": "@text.caption" }
                    ]
                  },
                  {
                    "type": "hstack",
                    "spacing": 12,
                    "children": [
                      {
                        "type": "button",
                        "text": "−",
                        "styleId": "@button.secondary",
                        "fillWidth": true,
                        "actions": { "onTap": "decrement" }
                      },
                      {
                        "type": "label",
                        "text": "${counter}",
                        "styleId": "@text.heading2"
                      },
                      {
                        "type": "button",
                        "text": "+",
                        "styleId": "@button.primary",
                        "fillWidth": true,
                        "actions": { "onTap": "increment" }
                      }
                    ]
                  },
                  { "type": "label", "text": "Interactive counter demo", "styleId": "@text.caption" }
                ]
              }
            ]
          },
          {
            "layout": { "type": "list", "showsDividers": false },
            "header": {
              "type": "label",
              "text": "TEXT FIELDS",
              "styleId": "@text.caption"
            },
            "children": [
              {
                "type": "vstack",
                "spacing": 16,
                "children": [
                  {
                    "type": "label",
                    "text": "Text fields use design system style tokens for consistent appearance.",
                    "styleId": "@text.body"
                  },
                  {
                    "type": "vstack",
                    "spacing": 8,
                    "children": [
                      { "type": "label", "text": "Username", "styleId": "@text.caption" },
                      {
                        "type": "textfield",
                        "placeholder": "Enter your username",
                        "bind": "username",
                        "styleId": "@textField.default"
                      }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 8,
                    "children": [
                      { "type": "label", "text": "Email", "styleId": "@text.caption" },
                      {
                        "type": "textfield",
                        "placeholder": "Enter your email",
                        "bind": "email",
                        "styleId": "@textField.default"
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            "layout": { "type": "list", "showsDividers": false },
            "header": {
              "type": "label",
              "text": "ABOUT",
              "styleId": "@text.caption"
            },
            "children": [
              {
                "type": "vstack",
                "spacing": 12,
                "children": [
                  {
                    "type": "label",
                    "text": "The Lightspeed design system provides:",
                    "styleId": "@text.body"
                  },
                  {
                    "type": "label",
                    "text": "✓ Native SwiftUI components with full fidelity\\n✓ Press animations and haptic feedback\\n✓ Automatic dark mode adaptation\\n✓ Style token fallbacks for unsupported components\\n✓ Consistent typography scale",
                    "styleId": "@text.body"
                  },
                  {
                    "type": "label",
                    "text": "Use the @ prefix to reference design system styles:\\n@button.primary, @text.heading1, etc.",
                    "styleId": "@text.caption"
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}
"""

// MARK: - Design System Example View

/// SwiftUI view wrapper for the design system example.
public struct DesignSystemExampleView: View {
    
    public init() {}
    
    public var body: some View {
        if let rendererView = ScalsRendererView(
            jsonString: designSystemExampleJSON,
            designSystemProvider: LightspeedProvider(),
            debugMode: true
        ) {
            rendererView
        } else {
            Text("Failed to parse design system example JSON")
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Preview

#Preview("Lightspeed Design System") {
    DesignSystemExampleView()
}
