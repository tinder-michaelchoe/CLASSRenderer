//
//  MetMuseumExampleView.swift
//  ScalsExamples
//
//  Example demonstrating GET requests with the Metropolitan Museum of Art API.
//  API Documentation: https://metmuseum.github.io/
//

import SwiftUI
import SCALS
import ScalsModules

/// Example demonstrating Met Museum API integration
public struct MetMuseumExampleView: View {
    public init() {}
    
    public var body: some View {
        ScalsRendererView(jsonString: metMuseumJSON)
            .navigationTitle("Met Museum Art")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - JSON Definition

/// Example JSON demonstrating Met Museum API search
/// Note: The Met API search returns only objectIDs, so we need to fetch each object individually.
/// This example lets users enter an Object ID directly to fetch artwork details.
/// Sample IDs with images: 436535 (Van Gogh), 437133 (Vermeer), 459055 (Monet), 436524 (Van Gogh Wheat Field)
public let metMuseumJSON = """
{
  "id": "met-museum-example",
  "version": "1.0",
  "state": {
    "objectId": "436535",
    "artwork": {
      "title": "Tap Fetch to load",
      "artistDisplayName": "",
      "objectDate": "",
      "medium": "",
      "department": "",
      "dimensions": "",
      "primaryImage": ""
    },
    "loading": false,
    "error": null
  },
  "styles": {
    "pageTitle": { "fontSize": 24, "fontWeight": "bold", "textColor": "#1a1a1a" },
    "subtitle": { "fontSize": 14, "textColor": "#666666" },
    "sectionTitle": { "fontSize": 16, "fontWeight": "semibold", "textColor": "#333333" },
    "field": { "fontSize": 16, "textColor": "#000000", "backgroundColor": "#FFFFFF", "cornerRadius": 8, "padding": { "horizontal": 12, "vertical": 10 } },
    "primaryButton": { "backgroundColor": "#C41E3A", "textColor": "#FFFFFF", "cornerRadius": 8, "fontWeight": "semibold", "padding": { "horizontal": 20, "vertical": 12 } },
    "secondaryButton": { "backgroundColor": "#E8E8E8", "textColor": "#333333", "cornerRadius": 8, "padding": { "horizontal": 12, "vertical": 8 } },
    "artworkImage": { "height": 250, "cornerRadius": 8 },
    "artworkTitle": { "fontSize": 18, "fontWeight": "bold", "textColor": "#1a1a1a" },
    "artistName": { "fontSize": 15, "fontWeight": "medium", "textColor": "#C41E3A" },
    "artworkDetail": { "fontSize": 14, "textColor": "#444444" },
    "detailLabel": { "fontSize": 11, "fontWeight": "semibold", "textColor": "#888888" },
    "helpText": { "fontSize": 12, "textColor": "#888888" },
    "card": { "backgroundColor": "#FFFFFF", "cornerRadius": 12, "padding": { "horizontal": 16, "vertical": 16 } }
  },
  "actions": {
    "fetchArtwork": {
      "type": "request",
      "requestId": "fetchArtwork",
      "method": "GET",
      "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/${objectId}",
      "debug": true,
      "loadingPath": "loading",
      "responsePath": "artwork",
      "errorPath": "error"
    },
    "loadVanGogh": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "436535" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/436535", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    },
    "loadVermeer": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "437879" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/437879", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    },
    "loadMonet": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "459055" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/459055", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    },
    "loadRembrandt": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "437394" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/437394", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    },
    "loadDegas": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "438817" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/438817", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    },
    "loadSargent": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "12123" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/12123", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    },
    "loadRenoir": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "436965" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/436965", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    },
    "loadCezanne": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "435868" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/435868", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    },
    "loadEl Greco": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "436573" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/436573", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    },
    "loadBruegel": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "objectId", "value": "435809" },
        { "type": "request", "requestId": "fetch", "method": "GET", "url": "https://collectionapi.metmuseum.org/public/collection/v1/objects/435809", "loadingPath": "loading", "responsePath": "artwork", "errorPath": "error" }
      ]
    }
  },
  "root": {
    "backgroundColor": "#F5F5F5",
    "edgeInsets": { "top": 40, "leading": 24, "trailing": 24, "bottom": 32 },
    "children": [
      {
        "type": "sectionLayout",
        "sections": [
          {
            "layout": { "type": "list", "showsDividers": false },
            "children": [
              {
                "type": "vstack",
                "spacing": 16,
                "alignment": "leading",
                "children": [
          {
            "type": "vstack",
            "spacing": 4,
            "alignment": "leading",
            "children": [
              { "type": "label", "text": "Met Museum Explorer", "styleId": "pageTitle" },
              { "type": "label", "text": "Explore artwork from The Metropolitan Museum of Art", "styleId": "subtitle" }
            ]
          },
          {
            "type": "vstack",
            "styleId": "card",
            "spacing": 12,
            "alignment": "leading",
            "children": [
              { "type": "label", "text": "Quick Select", "styleId": "sectionTitle" },
              {
                "type": "hstack",
                "spacing": 8,
                "children": [
                  { "type": "button", "text": "Van Gogh", "styleId": "secondaryButton", "actions": { "onTap": "loadVanGogh" } },
                  { "type": "button", "text": "Vermeer", "styleId": "secondaryButton", "actions": { "onTap": "loadVermeer" } },
                  { "type": "button", "text": "Monet", "styleId": "secondaryButton", "actions": { "onTap": "loadMonet" } }
                ]
              },
              {
                "type": "hstack",
                "spacing": 8,
                "children": [
                  { "type": "button", "text": "Rembrandt", "styleId": "secondaryButton", "actions": { "onTap": "loadRembrandt" } },
                  { "type": "button", "text": "Degas", "styleId": "secondaryButton", "actions": { "onTap": "loadDegas" } },
                  { "type": "button", "text": "Sargent", "styleId": "secondaryButton", "actions": { "onTap": "loadSargent" } }
                ]
              },
              {
                "type": "hstack",
                "spacing": 8,
                "children": [
                  { "type": "button", "text": "Renoir", "styleId": "secondaryButton", "actions": { "onTap": "loadRenoir" } },
                  { "type": "button", "text": "Cézanne", "styleId": "secondaryButton", "actions": { "onTap": "loadCezanne" } },
                  { "type": "button", "text": "El Greco", "styleId": "secondaryButton", "actions": { "onTap": "loadEl Greco" } },
                  { "type": "button", "text": "Bruegel", "styleId": "secondaryButton", "actions": { "onTap": "loadBruegel" } }
                ]
              }
            ]
          },
          {
            "type": "vstack",
            "styleId": "card",
            "spacing": 12,
            "alignment": "leading",
            "children": [
              { "type": "label", "text": "Fetch by Object ID", "styleId": "sectionTitle" },
              {
                "type": "hstack",
                "spacing": 12,
                "children": [
                  { "type": "textfield", "placeholder": "Enter ID...", "styleId": "field", "bind": "objectId" },
                  { "type": "button", "text": "Fetch", "styleId": "primaryButton", "actions": { "onTap": "fetchArtwork" } }
                ]
              },
              { "type": "label", "text": "Try: 436535, 437133, 459055", "styleId": "helpText" }
            ]
          },
          {
            "type": "vstack",
            "styleId": "card",
            "spacing": 12,
            "alignment": "center",
            "children": [
              {
                "type": "image",
                "image": {
                  "url": "${artwork.primaryImage}",
                  "placeholder": { "sfsymbol": "photo" },
                  "loading": { "sfsymbol": "arrow.trianglehead.2.clockwise" }
                },
                "styleId": "artworkImage"
              },
              {
                "type": "vstack",
                "spacing": 8,
                "alignment": "leading",
                "children": [
                  { "type": "label", "text": "${artwork.title}", "styleId": "artworkTitle" },
                  { "type": "label", "text": "${artwork.artistDisplayName}", "styleId": "artistName" },
                  {
                    "type": "hstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Date:", "styleId": "detailLabel" },
                      { "type": "label", "text": "${artwork.objectDate}", "styleId": "artworkDetail" }
                    ]
                  },
                  {
                    "type": "hstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Medium:", "styleId": "detailLabel" },
                      { "type": "label", "text": "${artwork.medium}", "styleId": "artworkDetail" }
                    ]
                  },
                  {
                    "type": "hstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Department:", "styleId": "detailLabel" },
                      { "type": "label", "text": "${artwork.department}", "styleId": "artworkDetail" }
                    ]
                  },
                  {
                    "type": "hstack",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Dimensions:", "styleId": "detailLabel" },
                      { "type": "label", "text": "${artwork.dimensions}", "styleId": "artworkDetail" }
                    ]
                  }
                ]
              }
            ]
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
