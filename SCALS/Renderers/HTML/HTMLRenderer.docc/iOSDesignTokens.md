# iOS Design Tokens Reference

Design tokens derived from Apple's Human Interface Guidelines for web rendering.

## Overview

The ``iOSDesignTokens`` enum provides a comprehensive set of iOS design values for generating CSS that matches native iOS appearance. These values are based on:

- Apple Human Interface Guidelines (HIG)
- SF Pro font metrics
- Framework7 iOS theme CSS patterns

## Typography

### Font Sizes and Weights

The iOS type scale is optimized for legibility on mobile devices:

```swift
// Large Title: 34pt Bold - for navigation titles
Typography.largeTitle  // CSSFont(size: 34, weight: 700)

// Title 1-3: Hierarchical headings
Typography.title1      // CSSFont(size: 28, weight: 700)
Typography.title2      // CSSFont(size: 22, weight: 700)
Typography.title3      // CSSFont(size: 20, weight: 600)

// Body content
Typography.headline    // CSSFont(size: 17, weight: 600)
Typography.body        // CSSFont(size: 17, weight: 400)
Typography.callout     // CSSFont(size: 16, weight: 400)
Typography.subheadline // CSSFont(size: 15, weight: 400)

// Small text
Typography.footnote    // CSSFont(size: 13, weight: 400)
Typography.caption1    // CSSFont(size: 12, weight: 400)
Typography.caption2    // CSSFont(size: 11, weight: 400)
```

### Font Stacks

Two font stacks are provided for system and monospace fonts:

```swift
// System font - uses SF Pro on Apple platforms
Typography.fontStack
// "system-ui, -apple-system, BlinkMacSystemFont, 'SF Pro Text', ..."

// Monospace - uses SF Mono on Apple platforms
Typography.monospaceFontStack
// "'SF Mono', ui-monospace, Menlo, Monaco, ..."
```

## Colors

### Light Mode Colors

```swift
LightColors.label                  // "#000000"
LightColors.secondaryLabel         // "rgba(60, 60, 67, 0.6)"
LightColors.tertiaryLabel          // "rgba(60, 60, 67, 0.3)"
LightColors.systemBackground       // "#FFFFFF"
LightColors.secondarySystemBackground  // "#F2F2F7"
LightColors.separator              // "rgba(60, 60, 67, 0.29)"
```

### Dark Mode Colors

```swift
DarkColors.label                   // "#FFFFFF"
DarkColors.secondaryLabel          // "rgba(235, 235, 245, 0.6)"
DarkColors.tertiaryLabel           // "rgba(235, 235, 245, 0.3)"
DarkColors.systemBackground        // "#000000"
DarkColors.secondarySystemBackground  // "#1C1C1E"
DarkColors.separator               // "rgba(84, 84, 88, 0.6)"
```

### System Tint Colors

These colors remain consistent across light and dark modes:

```swift
SystemColors.blue    // "#007AFF" - Primary action color
SystemColors.green   // "#34C759" - Success/positive
SystemColors.red     // "#FF3B30" - Destructive/error
SystemColors.orange  // "#FF9500" - Warning
SystemColors.purple  // "#AF52DE" - Accent
SystemColors.teal    // "#5AC8FA" - Info
SystemColors.yellow  // "#FFCC00" - Highlight
```

## Spacing

Standard iOS spacing values:

```swift
Spacing.minTouchTarget          // 44pt - Minimum tap target
Spacing.listRowPadding          // 16pt - List item padding
Spacing.cardPadding             // 16pt - Card content padding
Spacing.sectionHeaderPadding    // 16pt - Section header
Spacing.separatorInset          // 16pt - List separator inset
Spacing.navBarCompactHeight     // 44pt - Navigation bar
Spacing.navBarLargeTitleHeight  // 96pt - Large title nav bar
Spacing.tabBarHeight            // 49pt - Tab bar
```

## Corner Radius

iOS corner radius values for different contexts:

```swift
CornerRadius.small      // 10pt - Buttons, cards
CornerRadius.medium     // 12pt - Modals, sheets
CornerRadius.large      // 38pt - Full screen corners
CornerRadius.extraLarge // 44pt - Dynamic Island
```

## CSS Custom Properties

The base stylesheet exports these values as CSS custom properties:

```css
:root {
    /* Typography */
    --ios-font-stack: system-ui, -apple-system, ...;
    
    /* Colors */
    --ios-blue: #007AFF;
    --ios-label: #000000;
    --ios-background: #FFFFFF;
    
    /* Spacing */
    --ios-spacing-sm: 8px;
    --ios-spacing-md: 16px;
    --ios-spacing-lg: 24px;
    
    /* Corner Radius */
    --ios-corner-radius-sm: 10px;
    --ios-corner-radius-md: 12px;
}
```

## Dark Mode

Dark mode is handled automatically via CSS media queries:

```css
@media (prefers-color-scheme: dark) {
    :root:not(.light-mode) {
        --ios-label: #FFFFFF;
        --ios-background: #000000;
        /* ... */
    }
}
```

You can also force a specific mode by adding a class to the `<html>` element:

- `.light-mode` - Force light mode
- `.dark-mode` - Force dark mode

## Topics

### Token Categories

- ``iOSDesignTokens/Typography``
- ``iOSDesignTokens/LightColors``
- ``iOSDesignTokens/DarkColors``
- ``iOSDesignTokens/SystemColors``
- ``iOSDesignTokens/Spacing``
- ``iOSDesignTokens/CornerRadius``

### CSS Generation

- ``iOSDesignTokens/baseStylesheet``
