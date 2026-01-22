//
//  iOSDesignTokens.swift
//  SCALS
//
//  iOS design tokens for HTML/CSS rendering.
//  Based on Apple's Human Interface Guidelines and SF Pro font metrics.
//

import Foundation

// MARK: - iOS Design Tokens

/// iOS design tokens for generating CSS that matches native iOS styling.
///
/// These values are derived from Apple's Human Interface Guidelines and
/// Framework7's iOS theme CSS patterns.
public enum iOSDesignTokens {
    
    // MARK: - Typography
    
    /// iOS typography scale based on SF Pro font metrics.
    public enum Typography {
        /// Large Title: 34pt Bold
        public static let largeTitle = CSSFont(size: 34, weight: 700)
        /// Title 1: 28pt Bold
        public static let title1 = CSSFont(size: 28, weight: 700)
        /// Title 2: 22pt Bold
        public static let title2 = CSSFont(size: 22, weight: 700)
        /// Title 3: 20pt Semibold
        public static let title3 = CSSFont(size: 20, weight: 600)
        /// Headline: 17pt Semibold
        public static let headline = CSSFont(size: 17, weight: 600)
        /// Body: 17pt Regular
        public static let body = CSSFont(size: 17, weight: 400)
        /// Callout: 16pt Regular
        public static let callout = CSSFont(size: 16, weight: 400)
        /// Subheadline: 15pt Regular
        public static let subheadline = CSSFont(size: 15, weight: 400)
        /// Footnote: 13pt Regular
        public static let footnote = CSSFont(size: 13, weight: 400)
        /// Caption 1: 12pt Regular
        public static let caption1 = CSSFont(size: 12, weight: 400)
        /// Caption 2: 11pt Regular
        public static let caption2 = CSSFont(size: 11, weight: 400)
        
        /// System font stack for iOS fidelity
        public static let fontStack = "system-ui, -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'SF Pro Display', 'Helvetica Neue', sans-serif"
        
        /// Monospace font stack
        public static let monospaceFontStack = "'SF Mono', ui-monospace, Menlo, Monaco, 'Cascadia Mono', 'Segoe UI Mono', 'Roboto Mono', monospace"
    }
    
    // MARK: - Colors (Light Mode)
    
    /// iOS semantic colors for light mode.
    public enum LightColors {
        // Labels
        public static let label = "#000000"
        public static let secondaryLabel = "rgba(60, 60, 67, 0.6)"
        public static let tertiaryLabel = "rgba(60, 60, 67, 0.3)"
        public static let quaternaryLabel = "rgba(60, 60, 67, 0.18)"
        
        // Backgrounds
        public static let systemBackground = "#FFFFFF"
        public static let secondarySystemBackground = "#F2F2F7"
        public static let tertiarySystemBackground = "#FFFFFF"
        public static let systemGroupedBackground = "#F2F2F7"
        public static let secondarySystemGroupedBackground = "#FFFFFF"
        
        // Fills
        public static let systemFill = "rgba(120, 120, 128, 0.2)"
        public static let secondarySystemFill = "rgba(120, 120, 128, 0.16)"
        public static let tertiarySystemFill = "rgba(118, 118, 128, 0.12)"
        public static let quaternarySystemFill = "rgba(116, 116, 128, 0.08)"
        
        // Separators
        public static let separator = "rgba(60, 60, 67, 0.29)"
        public static let opaqueSeparator = "#C6C6C8"
    }
    
    // MARK: - Colors (Dark Mode)
    
    /// iOS semantic colors for dark mode.
    public enum DarkColors {
        // Labels
        public static let label = "#FFFFFF"
        public static let secondaryLabel = "rgba(235, 235, 245, 0.6)"
        public static let tertiaryLabel = "rgba(235, 235, 245, 0.3)"
        public static let quaternaryLabel = "rgba(235, 235, 245, 0.18)"
        
        // Backgrounds
        public static let systemBackground = "#000000"
        public static let secondarySystemBackground = "#1C1C1E"
        public static let tertiarySystemBackground = "#2C2C2E"
        public static let systemGroupedBackground = "#000000"
        public static let secondarySystemGroupedBackground = "#1C1C1E"
        
        // Fills
        public static let systemFill = "rgba(120, 120, 128, 0.36)"
        public static let secondarySystemFill = "rgba(120, 120, 128, 0.32)"
        public static let tertiarySystemFill = "rgba(118, 118, 128, 0.24)"
        public static let quaternarySystemFill = "rgba(116, 116, 128, 0.18)"
        
        // Separators
        public static let separator = "rgba(84, 84, 88, 0.6)"
        public static let opaqueSeparator = "#38383A"
    }
    
    // MARK: - System Colors (Tint Colors)
    
    /// iOS system tint colors (same in light and dark mode).
    public enum SystemColors {
        public static let blue = "#007AFF"
        public static let green = "#34C759"
        public static let indigo = "#5856D6"
        public static let orange = "#FF9500"
        public static let pink = "#FF2D55"
        public static let purple = "#AF52DE"
        public static let red = "#FF3B30"
        public static let teal = "#5AC8FA"
        public static let yellow = "#FFCC00"
        
        // Gray scale
        public static let gray = "#8E8E93"
        public static let gray2 = "#AEAEB2"
        public static let gray3 = "#C7C7CC"
        public static let gray4 = "#D1D1D6"
        public static let gray5 = "#E5E5EA"
        public static let gray6 = "#F2F2F7"
    }
    
    // MARK: - Spacing
    
    /// iOS spacing and sizing constants.
    public enum Spacing {
        /// Minimum touch target size (44pt)
        public static let minTouchTarget: CGFloat = 44
        
        /// Standard list row padding
        public static let listRowPadding: CGFloat = 16
        
        /// Standard card/cell padding
        public static let cardPadding: CGFloat = 16
        
        /// Standard section header padding
        public static let sectionHeaderPadding: CGFloat = 16
        
        /// List separator inset
        public static let separatorInset: CGFloat = 16
        
        /// Navigation bar height (compact)
        public static let navBarCompactHeight: CGFloat = 44
        
        /// Navigation bar height (large title)
        public static let navBarLargeTitleHeight: CGFloat = 96
        
        /// Tab bar height
        public static let tabBarHeight: CGFloat = 49
    }
    
    // MARK: - Corner Radius
    
    /// iOS corner radius values.
    public enum CornerRadius {
        /// Small (cards, buttons): 10px
        public static let small: CGFloat = 10
        /// Medium (modals, sheets): 12px
        public static let medium: CGFloat = 12
        /// Large (full screen corners): 38px
        public static let large: CGFloat = 38
        /// Extra large (dynamic island): 44px
        public static let extraLarge: CGFloat = 44
    }
    
    // MARK: - Base Stylesheet
    
    /// Base CSS stylesheet with iOS design tokens as CSS custom properties.
    public static let baseStylesheet: String = """
/* SCALS iOS Base Styles */
/* Generated from Apple Human Interface Guidelines */

:root {
    /* Font Stack */
    --ios-font-stack: \(Typography.fontStack);
    --ios-mono-font-stack: \(Typography.monospaceFontStack);
    
    /* System Colors */
    --ios-blue: \(SystemColors.blue);
    --ios-green: \(SystemColors.green);
    --ios-indigo: \(SystemColors.indigo);
    --ios-orange: \(SystemColors.orange);
    --ios-pink: \(SystemColors.pink);
    --ios-purple: \(SystemColors.purple);
    --ios-red: \(SystemColors.red);
    --ios-teal: \(SystemColors.teal);
    --ios-yellow: \(SystemColors.yellow);
    --ios-gray: \(SystemColors.gray);
    
    /* Light Mode (default) */
    --ios-label: \(LightColors.label);
    --ios-secondary-label: \(LightColors.secondaryLabel);
    --ios-tertiary-label: \(LightColors.tertiaryLabel);
    --ios-background: \(LightColors.systemBackground);
    --ios-secondary-background: \(LightColors.secondarySystemBackground);
    --ios-grouped-background: \(LightColors.systemGroupedBackground);
    --ios-separator: \(LightColors.separator);
    --ios-fill: \(LightColors.systemFill);
    
    /* Spacing */
    --ios-spacing-xs: 4px;
    --ios-spacing-sm: 8px;
    --ios-spacing-md: 16px;
    --ios-spacing-lg: 24px;
    --ios-spacing-xl: 32px;
    
    /* Corner Radius */
    --ios-corner-radius-sm: \(Int(CornerRadius.small))px;
    --ios-corner-radius-md: \(Int(CornerRadius.medium))px;
    --ios-corner-radius-lg: \(Int(CornerRadius.large))px;
    
    /* Shadows */
    --ios-shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.1);
    --ios-shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
    --ios-shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
}

/* Dark Mode */
@media (prefers-color-scheme: dark) {
    :root:not(.light-mode) {
        --ios-label: \(DarkColors.label);
        --ios-secondary-label: \(DarkColors.secondaryLabel);
        --ios-tertiary-label: \(DarkColors.tertiaryLabel);
        --ios-background: \(DarkColors.systemBackground);
        --ios-secondary-background: \(DarkColors.secondarySystemBackground);
        --ios-grouped-background: \(DarkColors.systemGroupedBackground);
        --ios-separator: \(DarkColors.separator);
        --ios-fill: \(DarkColors.systemFill);
    }
}

/* Forced Dark Mode */
.dark-mode {
    --ios-label: \(DarkColors.label);
    --ios-secondary-label: \(DarkColors.secondaryLabel);
    --ios-tertiary-label: \(DarkColors.tertiaryLabel);
    --ios-background: \(DarkColors.systemBackground);
    --ios-secondary-background: \(DarkColors.secondarySystemBackground);
    --ios-grouped-background: \(DarkColors.systemGroupedBackground);
    --ios-separator: \(DarkColors.separator);
    --ios-fill: \(DarkColors.systemFill);
}

/* Forced Light Mode */
.light-mode {
    --ios-label: \(LightColors.label);
    --ios-secondary-label: \(LightColors.secondaryLabel);
    --ios-tertiary-label: \(LightColors.tertiaryLabel);
    --ios-background: \(LightColors.systemBackground);
    --ios-secondary-background: \(LightColors.secondarySystemBackground);
    --ios-grouped-background: \(LightColors.systemGroupedBackground);
    --ios-separator: \(LightColors.separator);
    --ios-fill: \(LightColors.systemFill);
}

/* Base Reset */
*, *::before, *::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

html {
    font-size: 16px;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    -webkit-text-size-adjust: 100%;
}

body {
    font-family: var(--ios-font-stack);
    font-size: 17px;
    line-height: 1.47;
    color: var(--ios-label);
    background-color: var(--ios-background);
    min-height: 100vh;
    min-height: 100dvh;
}

/* SCALS Root Container */
.scals-root {
    min-height: 100vh;
    min-height: 100dvh;
    padding: env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left);
}

/* iOS Button Base */
.ios-button {
    font-family: var(--ios-font-stack);
    font-size: 17px;
    font-weight: 600;
    min-height: \(Int(Spacing.minTouchTarget))px;
    padding: 12px 20px;
    border-radius: var(--ios-corner-radius-sm);
    border: none;
    background-color: var(--ios-blue);
    color: white;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    -webkit-tap-highlight-color: transparent;
    transition: opacity 0.15s ease;
}

.ios-button:active {
    opacity: 0.7;
}

.ios-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.ios-button--secondary {
    background-color: transparent;
    color: var(--ios-blue);
}

.ios-button--destructive {
    background-color: var(--ios-red);
}

/* iOS List Row */
.ios-list-row {
    min-height: \(Int(Spacing.minTouchTarget))px;
    padding: 11px \(Int(Spacing.listRowPadding))px;
    display: flex;
    align-items: center;
    gap: 12px;
    background-color: var(--ios-background);
}

.ios-list-row + .ios-list-row {
    border-top: 0.5px solid var(--ios-separator);
    margin-left: \(Int(Spacing.separatorInset))px;
}

/* iOS Section Header */
.ios-section-header {
    font-size: 13px;
    font-weight: 400;
    color: var(--ios-secondary-label);
    text-transform: uppercase;
    letter-spacing: 0.02em;
    padding: 16px \(Int(Spacing.sectionHeaderPadding))px 8px;
}

/* iOS Card */
.ios-card {
    background-color: var(--ios-secondary-background);
    border-radius: var(--ios-corner-radius-sm);
    padding: \(Int(Spacing.cardPadding))px;
}

/* iOS Divider */
.ios-divider {
    height: 0.5px;
    background-color: var(--ios-separator);
    margin: 0 \(Int(Spacing.listRowPadding))px;
}

/* iOS Text Styles */
.ios-text {
    font-family: var(--ios-font-stack);
    color: var(--ios-label);
    text-align: center;
}

.ios-text--secondary {
    color: var(--ios-secondary-label);
}

.ios-text--tertiary {
    color: var(--ios-tertiary-label);
}

/* Typography Classes */
.ios-large-title {
    font-size: \(Typography.largeTitle.size)px;
    font-weight: \(Typography.largeTitle.weight);
    line-height: 1.2;
}

.ios-title1 {
    font-size: \(Typography.title1.size)px;
    font-weight: \(Typography.title1.weight);
    line-height: 1.2;
}

.ios-title2 {
    font-size: \(Typography.title2.size)px;
    font-weight: \(Typography.title2.weight);
    line-height: 1.25;
}

.ios-title3 {
    font-size: \(Typography.title3.size)px;
    font-weight: \(Typography.title3.weight);
    line-height: 1.25;
}

.ios-headline {
    font-size: \(Typography.headline.size)px;
    font-weight: \(Typography.headline.weight);
    line-height: 1.3;
}

.ios-body {
    font-size: \(Typography.body.size)px;
    font-weight: \(Typography.body.weight);
    line-height: 1.47;
}

.ios-callout {
    font-size: \(Typography.callout.size)px;
    font-weight: \(Typography.callout.weight);
    line-height: 1.4;
}

.ios-subheadline {
    font-size: \(Typography.subheadline.size)px;
    font-weight: \(Typography.subheadline.weight);
    line-height: 1.4;
}

.ios-footnote {
    font-size: \(Typography.footnote.size)px;
    font-weight: \(Typography.footnote.weight);
    line-height: 1.4;
}

.ios-caption1 {
    font-size: \(Typography.caption1.size)px;
    font-weight: \(Typography.caption1.weight);
    line-height: 1.35;
}

.ios-caption2 {
    font-size: \(Typography.caption2.size)px;
    font-weight: \(Typography.caption2.weight);
    line-height: 1.35;
}

/* Layout Utilities */
.ios-vstack {
    display: flex;
    flex-direction: column;
}

.ios-hstack {
    display: flex;
    flex-direction: row;
    align-items: center;
}

.ios-zstack {
    display: grid;
    grid-template-areas: "stack";
}

.ios-zstack > * {
    grid-area: stack;
}

.ios-spacer {
    flex: 1 1 0%;
}

/* Image Styles */
.ios-image {
    max-width: 100%;
    height: auto;
    object-fit: cover;
}

.ios-image--contain {
    object-fit: contain;
}

.ios-image--fill {
    object-fit: fill;
}

/* Toggle (Switch) */
.ios-toggle {
    appearance: none;
    width: 51px;
    height: 31px;
    border-radius: 15.5px;
    background-color: var(--ios-fill);
    position: relative;
    cursor: pointer;
    transition: background-color 0.2s ease;
}

.ios-toggle::before {
    content: '';
    position: absolute;
    top: 2px;
    left: 2px;
    width: 27px;
    height: 27px;
    border-radius: 50%;
    background-color: white;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    transition: transform 0.2s ease;
}

.ios-toggle:checked {
    background-color: var(--ios-green);
}

.ios-toggle:checked::before {
    transform: translateX(20px);
}

/* Slider */
.ios-slider {
    appearance: none;
    width: 100%;
    height: 4px;
    border-radius: 2px;
    background: var(--ios-fill);
    outline: none;
}

.ios-slider::-webkit-slider-thumb {
    appearance: none;
    width: 28px;
    height: 28px;
    border-radius: 50%;
    background: white;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    cursor: pointer;
}

/* Text Field */
.ios-textfield {
    font-family: var(--ios-font-stack);
    font-size: 17px;
    padding: 12px 16px;
    border: none;
    border-radius: var(--ios-corner-radius-sm);
    background-color: var(--ios-fill);
    color: var(--ios-label);
    width: 100%;
}

.ios-textfield::placeholder {
    color: var(--ios-tertiary-label);
}

.ios-textfield:focus {
    outline: none;
    box-shadow: 0 0 0 2px var(--ios-blue);
}
"""
}

// MARK: - CSS Font

/// A CSS font definition with size and weight.
public struct CSSFont {
    public let size: Int
    public let weight: Int
    
    public init(size: Int, weight: Int) {
        self.size = size
        self.weight = weight
    }
    
    /// CSS font shorthand value
    public var css: String {
        "\(weight) \(size)px var(--ios-font-stack)"
    }
}
