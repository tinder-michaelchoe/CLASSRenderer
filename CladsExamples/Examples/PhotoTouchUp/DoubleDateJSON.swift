//
//  DoubleDateJSON.swift
//  CladsExamples
//
//  JSON definition for the Double Date onboarding bottom sheet.
//

import Foundation

public enum DoubleDateJSON {

    public static let bottomSheet = """
    {
      "id": "double-date-onboarding",
      "version": "1.0",
      "root": {
        "backgroundColor": "#000000",
        "edgeInsets": {
          "top": { "positioning": "absolute", "value": 0 },
          "bottom": { "positioning": "absolute", "value": 0 }
        },
        "children": [
          {
            "type": "zstack",
            "alignment": {
              "horizontal": "center",
              "vertical": "top"
            },
            "children": [
              {
                "type": "gradient",
                "gradientColors": [
                  { "color": "#FF6B6B", "location": 0.0 },
                  { "color": "#FF5555", "location": 0.3 },
                  { "color": "#2D0A0A", "location": 0.7 },
                  { "color": "#000000", "location": 1.0 }
                ],
                "gradientStart": "top",
                "gradientEnd": "bottom",
                "styleId": "gradientBackground"
              },
              {
                "type": "vstack",
                "spacing": 0,
                "children": [
                  {
                    "type": "hstack",
                    "padding": { "leading": 24, "trailing": 24, "top": 60 },
                    "children": [
                      {
                        "type": "button",
                        "image": { "sfsymbol": "xmark" },
                        "buttonShape": "circle",
                        "styleId": "closeButton",
                        "actions": { "onTap": "dismiss" }
                      },
                      { "type": "spacer" }
                    ]
                  },
                  { "type": "spacer" },
                  {
                    "type": "image",
                    "image": { "asset": "DoubleDateHero" },
                    "styleId": "cardsImage"
                  },
                  {
                    "type": "vstack",
                    "spacing": 16,
                    "alignment": "center",
                    "padding": { "horizontal": 32, "top": 40 },
                    "children": [
                      {
                        "type": "label",
                        "text": "Get early access to Double Date!",
                        "styleId": "titleStyle"
                      },
                      {
                        "type": "label",
                        "text": "Invite friends to pair up on Double Date, and be the first to try it when it launches.",
                        "styleId": "subtitleStyle"
                      }
                    ]
                  },
                  { "type": "spacer" },
                  {
                    "type": "vstack",
                    "spacing": 16,
                    "alignment": "center",
                    "padding": { "horizontal": 32, "bottom": 60 },
                    "children": [
                      {
                        "type": "hstack",
                        "spacing": 8,
                        "alignment": "center",
                        "children": [
                          {
                            "type": "image",
                            "image": { "sfsymbol": "clock" },
                            "styleId": "clockIcon"
                          },
                          {
                            "type": "label",
                            "text": "Double Date launches soon.",
                            "styleId": "launchTextStyle"
                          }
                        ]
                      },
                      {
                        "type": "button",
                        "text": "Invite friends",
                        "image": { "sfsymbol": "person.2.fill" },
                        "imagePlacement": "leading",
                        "imageSpacing": 8,
                        "styleId": "primaryButton",
                        "fillWidth": true,
                        "actions": { "onTap": "inviteFriends" }
                      },
                      {
                        "type": "button",
                        "text": "Maybe later",
                        "image": { "sfsymbol": "arrow.right" },
                        "imagePlacement": "trailing",
                        "imageSpacing": 8,
                        "styleId": "secondaryButton",
                        "fillWidth": true,
                        "actions": { "onTap": "dismiss" }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      "styles": {
        "gradientBackground": {
          "height": 400
        },
        "closeButton": {
          "fontSize": 18,
          "fontWeight": "semibold",
          "textColor": "#FFFFFF",
          "backgroundColor": "rgba(255, 255, 255, 0.15)",
          "width": 44,
          "height": 44
        },
        "cardsImage": {
          "width": 350,
          "height": 350,
          "cornerRadius": 24
        },
        "titleStyle": {
          "fontSize": 32,
          "fontWeight": "bold",
          "textColor": "#FFFFFF",
          "textAlignment": "center"
        },
        "subtitleStyle": {
          "fontSize": 17,
          "fontWeight": "regular",
          "textColor": "#FFFFFF",
          "textAlignment": "center"
        },
        "clockIcon": {
          "width": 20,
          "height": 20,
          "tintColor": "#FFFFFF"
        },
        "launchTextStyle": {
          "fontSize": 15,
          "fontWeight": "medium",
          "textColor": "#FFFFFF"
        },
        "primaryButton": {
          "fontSize": 17,
          "fontWeight": "semibold",
          "textColor": "#000000",
          "backgroundColor": "#FFFFFF",
          "cornerRadius": 28,
          "height": 56
        },
        "secondaryButton": {
          "fontSize": 17,
          "fontWeight": "medium",
          "textColor": "#FFFFFF",
          "backgroundColor": "transparent",
          "height": 56
        }
      },
      "actions": {
        "dismiss": { "type": "dismiss" },
        "inviteFriends": { "type": "inviteFriends" }
      }
    }
    """
}
