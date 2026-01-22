# Components

Components are the leaf nodes in the SCALS layout tree. They represent individual UI elements that display content or capture user input.

## Component Types

| Type | Description | Key Properties |
|------|-------------|----------------|
| `label` | Text display | `label`, `dataSourceId`, `styleId` |
| `button` | Tappable button | `label`, `styleId`, `fillWidth`, `actions` |
| `textfield` | Text input | `placeholder`, `bind`, `styleId` |
| `image` | Image display | `data`, `styleId` |
| `gradient` | Gradient overlay | `gradientColors`, `gradientStart`, `gradientEnd` |

---

## Label

Displays static or dynamic text content.

### JSON Schema

```json
{
  "type": "label",
  "id": "optional-id",
  "label": "Static text content",
  "styleId": "textStyle",
  "dataSourceId": "dynamicTextSource"
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"label"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier for the component |
| `label` | `string` | No | Static text content |
| `styleId` | `string` | No | Reference to a style definition |
| `dataSourceId` | `string` | No | Reference to a data source for dynamic content |
| `data` | `DataReference` | No | Inline data reference |

### Text Resolution Priority

1. `data` (inline data reference)
2. `dataSourceId` (named data source)
3. `label` (static text)

### Example

```json
{
  "styles": {
    "titleStyle": {
      "fontSize": 24,
      "fontWeight": "bold",
      "textColor": "#000000"
    }
  },
  "dataSources": {
    "greeting": { "type": "static", "value": "Hello, World!" }
  },
  "root": {
    "children": [
      {
        "type": "label",
        "id": "greetingLabel",
        "styleId": "titleStyle",
        "dataSourceId": "greeting"
      }
    ]
  }
}
```

### IR Mapping

```swift
// Document Model (decoded from JSON)
Document.Component(type: .label, label: "Hello", styleId: "titleStyle")

// IR (RenderNode)
TextNode(id: "greetingLabel", content: "Hello, World!", style: IR.Style(...))
```

---

## Button

An interactive button that triggers actions when tapped. Supports text, images, and automatic shape handling.

### JSON Schema

```json
{
  "type": "button",
  "id": "optional-id",
  "text": "Button Text",
  "image": { "sfsymbol": "arrow.right" },
  "imagePlacement": "trailing",
  "imageSpacing": 8,
  "buttonShape": "capsule",
  "styleId": "buttonStyle",
  "fillWidth": true,
  "actions": {
    "onTap": "actionId"
  }
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"button"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier |
| `text` | `string` | No | Button text label |
| `image` | `ImageSource` | No | Button icon/image |
| `imagePlacement` | `string` | No | Image position relative to text: `"leading"`, `"trailing"`, `"top"`, `"bottom"` (default: `"leading"`) |
| `imageSpacing` | `number` | No | Spacing between image and text in points (default: `8`) |
| `buttonShape` | `string` | No | Automatic shape: `"circle"`, `"capsule"`, `"roundedSquare"` |
| `styleId` | `string` | No | Reference to a style definition |
| `fillWidth` | `boolean` | No | Whether button expands to fill container width |
| `actions.onTap` | `ActionBinding` | No | Action to execute on tap |

### Button Shapes

The `buttonShape` property automatically calculates the appropriate corner radius:

| Shape | Behavior | Best For |
|-------|----------|----------|
| `"circle"` | `cornerRadius = min(width, height) / 2` | Icon-only buttons, close buttons, floating action buttons |
| `"capsule"` | `cornerRadius = height / 2` | Pill-shaped buttons with text, tags |
| `"roundedSquare"` | `cornerRadius = 10px` (fixed) | Standard buttons with consistent rounding |

**Example: Circular close button**
```json
{
  "type": "button",
  "image": { "sfsymbol": "xmark" },
  "buttonShape": "circle",
  "styleId": "closeButton"
}

// Style only needs size - no cornerRadius!
"closeButton": {
  "width": 44,
  "height": 44,
  "backgroundColor": "#007AFF"
}
```

**Note:** When `buttonShape` is specified, the style's `cornerRadius` property is ignored.

### Image Support

Buttons can include images from three sources:

**SF Symbols:**
```json
{
  "type": "button",
  "text": "Continue",
  "image": { "sfsymbol": "arrow.right" }
}
```

**Asset Catalog:**
```json
{
  "type": "button",
  "text": "Share",
  "image": { "asset": "shareIcon" }
}
```

**Remote URL:**
```json
{
  "type": "button",
  "text": "Profile",
  "image": { "url": "https://example.com/icon.png" }
}
```

**Activity Indicator:**
```json
{
  "type": "button",
  "text": "Loading...",
  "image": { "activityIndicator": true },
  "styleId": "loadingButton"
}
```

**Note:** Activity indicators in buttons render as `ProgressView` (SwiftUI) or return `nil` for UIKit (text-only button). Use activity indicators to show loading states during async operations.

### Image Placement

Control where the image appears relative to text:

```json
{
  "type": "button",
  "text": "Next",
  "image": { "sfsymbol": "arrow.right" },
  "imagePlacement": "trailing",  // Image after text
  "imageSpacing": 12
}
```

**Placement Options:**
- `"leading"` - Image before text (default)
- `"trailing"` - Image after text
- `"top"` - Image above text (vertical layout)
- `"bottom"` - Image below text (vertical layout)

### Content Alignment

Buttons support horizontal content alignment via the `textAlignment` style property:

```json
{
  "leadingAligned": {
    "textAlignment": "leading",  // Align content to left
    "backgroundColor": "#E5E5EA",
    "height": 44
  },
  "centerAligned": {
    "textAlignment": "center",  // Center content (default)
    "backgroundColor": "#007AFF",
    "height": 44
  },
  "trailingAligned": {
    "textAlignment": "trailing",  // Align content to right
    "backgroundColor": "#E5E5EA",
    "height": 44
  }
}
```

**Alignment Options:**
- `"leading"` - Content aligned to the left edge
- `"center"` - Content centered (default if not specified)
- `"trailing"` - Content aligned to the right edge

**Note:** Alignment is most visible on buttons with `fillWidth: true` or explicit width values.

### Styling

Buttons support comprehensive style properties:

```json
{
  "buttonStyle": {
    "backgroundColor": "#007AFF",
    "textColor": "#FFFFFF",
    "textAlignment": "center",
    "cornerRadius": 12,
    "width": 200,
    "height": 50,
    "fontSize": 17,
    "fontWeight": "semibold",
    "tintColor": "#FFFFFF"  // For image/icon color
  }
}
```

### Examples

**Text-only button:**
```json
{
  "type": "button",
  "text": "Submit",
  "styleId": "primaryButton",
  "fillWidth": true,
  "actions": { "onTap": "submitForm" }
}
```

**Icon-only circular button:**
```json
{
  "type": "button",
  "image": { "sfsymbol": "xmark" },
  "buttonShape": "circle",
  "styleId": "closeButton"
}
```

**Button with image and text:**
```json
{
  "type": "button",
  "text": "Continue",
  "image": { "sfsymbol": "arrow.right" },
  "imagePlacement": "trailing",
  "imageSpacing": 8,
  "buttonShape": "capsule",
  "styleId": "primaryButton",
  "fillWidth": true
}
```

**Button with leading alignment:**
```json
{
  "type": "button",
  "text": "Back",
  "image": { "sfsymbol": "arrow.left" },
  "imagePlacement": "leading",
  "styleId": "backButton",  // textAlignment: "leading"
  "fillWidth": true
}
```

**Complete Example:**
```json
{
  "styles": {
    "primaryButton": {
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF",
      "height": 56,
      "fontSize": 17,
      "fontWeight": "semibold",
      "tintColor": "#FFFFFF"
    },
    "closeButton": {
      "width": 44,
      "height": 44,
      "backgroundColor": "rgba(255, 255, 255, 0.15)",
      "tintColor": "#FFFFFF"
    }
  },
  "actions": {
    "submitForm": { "type": "dismiss" },
    "dismiss": { "type": "dismiss" }
  },
  "root": {
    "children": [
      {
        "type": "button",
        "image": { "sfsymbol": "xmark" },
        "buttonShape": "circle",
        "styleId": "closeButton",
        "actions": { "onTap": "dismiss" }
      },
      {
        "type": "button",
        "text": "Continue",
        "image": { "sfsymbol": "arrow.right" },
        "imagePlacement": "trailing",
        "buttonShape": "capsule",
        "styleId": "primaryButton",
        "fillWidth": true,
        "actions": { "onTap": "submitForm" }
      }
    ]
  }
}
```

### IR Mapping

```swift
// Document Model (decoded from JSON)
Document.Component(type: .button, label: "Submit", styleId: "primaryButton", ...)

// IR (RenderNode)
ButtonNode(
    id: "submitButton",
    label: "Submit",
    style: IR.Style(...),
    fillWidth: true,
    onTap: .reference("submitForm")
)
```

---

## TextField

A text input field with optional state binding.

### JSON Schema

```json
{
  "type": "textfield",
  "id": "optional-id",
  "placeholder": "Enter text...",
  "styleId": "inputStyle",
  "bind": "state.path"
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"textfield"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier |
| `placeholder` | `string` | No | Placeholder text |
| `styleId` | `string` | No | Reference to a style definition |
| `bind` | `string` | No | State path for two-way binding |

### Two-Way Binding

When `bind` is specified, the text field:
1. Initializes with the current state value
2. Updates the state as the user types
3. Reflects external state changes

### Example

```json
{
  "state": {
    "username": ""
  },
  "styles": {
    "inputStyle": {
      "fontSize": 16,
      "textColor": "#000000"
    }
  },
  "root": {
    "children": [
      {
        "type": "textfield",
        "id": "usernameInput",
        "placeholder": "Enter username",
        "styleId": "inputStyle",
        "bind": "username"
      }
    ]
  }
}
```

### IR Mapping

```swift
// Document Model (decoded from JSON)
Document.Component(type: .textfield, placeholder: "Enter username", bind: "username", ...)

// IR (RenderNode)
TextFieldNode(
    id: "usernameInput",
    placeholder: "Enter username",
    style: IR.Style(...),
    bindingPath: "username"
)
```

---

## Image

Displays images from various sources.

### JSON Schema

```json
{
  "type": "image",
  "id": "optional-id",
  "data": {
    "type": "static",
    "value": "source-string"
  },
  "styleId": "imageStyle"
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"image"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier |
| `data` | `DataReference` | Yes | Image source reference |
| `styleId` | `string` | No | Reference to a style definition |

### Image Sources

Images can be loaded from multiple sources:

**SF Symbols:**
```json
{
  "type": "image",
  "image": { "sfsymbol": "star.fill" }
}
```

**Asset Catalog:**
```json
{
  "type": "image",
  "image": { "asset": "heroImage" }
}
```

**Remote URL:**
```json
{
  "type": "image",
  "image": { "url": "https://example.com/photo.jpg" }
}
```

**Dynamic URL from State:**
```json
{
  "type": "image",
  "image": { "statePath": "https://api.example.com/avatar/${user.id}.jpg" }
}
```

**Activity Indicator (Loading Spinner):**
```json
{
  "type": "image",
  "image": { "activityIndicator": true },
  "styleId": "spinnerStyle"
}
```

The activity indicator renders as:
- **SwiftUI**: `ProgressView()` - the standard circular loading indicator
- **UIKit**: `UIActivityIndicatorView` - the native iOS activity indicator

**Use Cases:**
- Loading placeholders while fetching data
- Indicating background operations
- Form submission states
- Content refresh indicators

**Styling:**
```json
{
  "spinnerStyle": {
    "width": 40,
    "height": 40
  }
}
```

**Note:** Activity indicators automatically start animating when rendered. They ignore image-specific properties like `tintColor` and use system defaults.

### Legacy Data Reference Format

The older `data.value` string format with prefixes is still supported:

| Prefix | Description | Example |
|--------|-------------|---------|
| `system:` | SF Symbol name | `"system:star.fill"` |
| `url:` | Remote image URL | `"url:https://example.com/image.jpg"` |
| (none) | Asset catalog name | `"heroImage"` |

### Size Styling

```json
{
  "imageStyle": {
    "width": 100,
    "height": 100
  }
}
```

### Example

```json
{
  "styles": {
    "heroImage": {
      "height": 300
    }
  },
  "root": {
    "children": [
      {
        "type": "image",
        "id": "backgroundImage",
        "data": {
          "type": "static",
          "value": "url:https://example.com/photo.jpg"
        },
        "styleId": "heroImage"
      }
    ]
  }
}
```

### IR Mapping

```swift
// Document Model (decoded from JSON)
Document.Component(type: .image, data: Document.DataSource(...), ...)

// IR (RenderNode)
ImageNode(
    id: "backgroundImage",
    source: .url(URL(string: "https://example.com/photo.jpg")!),
    style: IR.Style(...)
)

// ImageNode.Source enum (nested)
extension ImageNode {
    enum Source {
        case system(name: String)  // SF Symbols
        case asset(name: String)   // Asset catalog
        case url(URL)              // Remote URL
    }
}
```

---

## Gradient

Displays a gradient overlay, typically used with ZStack for image overlays.

### JSON Schema

```json
{
  "type": "gradient",
  "id": "optional-id",
  "gradientColors": [
    { "color": "#FFFFFF", "location": 0.0 },
    { "color": "#00FFFFFF", "location": 1.0 }
  ],
  "gradientStart": "bottom",
  "gradientEnd": "top",
  "styleId": "gradientStyle"
}
```

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `"gradient"` | Yes | Component type identifier |
| `id` | `string` | No | Unique identifier |
| `gradientColors` | `[GradientColorConfig]` | Yes | Array of color stops |
| `gradientStart` | `string` | No | Gradient start point (default: "bottom") |
| `gradientEnd` | `string` | No | Gradient end point (default: "top") |
| `styleId` | `string` | No | Reference to a style definition |

### Gradient Color Stops

Each color stop can be:

**Fixed color:**
```json
{ "color": "#FF0000", "location": 0.5 }
```

**Adaptive color (light/dark mode):**
```json
{
  "lightColor": "#FFFFFFFF",
  "darkColor": "#FF000000",
  "location": 0.0
}
```

### Gradient Points

| Value | Position |
|-------|----------|
| `top` | Top center |
| `bottom` | Bottom center |
| `leading` | Left center |
| `trailing` | Right center |
| `topLeading` | Top left |
| `topTrailing` | Top right |
| `bottomLeading` | Bottom left |
| `bottomTrailing` | Bottom right |

### Color Format

Colors support both hex and CSS rgba formats:

**Hex Format:**
- `#RRGGBB` - Opaque color (alpha = FF)
- `#AARRGGBB` - Color with alpha

Examples:
- `#FF0000` - Red (opaque)
- `#FFFF0000` - Red (opaque, explicit alpha)
- `#80FF0000` - Red (50% transparent)
- `#00FFFFFF` - White (fully transparent)

**CSS rgba Format:**
- `rgba(r, g, b, a)` - Red, green, blue (0-255), alpha (0.0-1.0)

Examples:
- `rgba(255, 0, 0, 1.0)` - Red (opaque)
- `rgba(0, 122, 255, 0.1)` - Blue (10% opacity)
- `rgba(255, 255, 255, 0.15)` - White (15% opacity)
- `rgba(0, 0, 0, 0.5)` - Black (50% opacity)

### Example: Image Overlay

```json
{
  "type": "zstack",
  "children": [
    {
      "type": "image",
      "data": { "type": "static", "value": "url:https://..." },
      "styleId": "heroImage"
    },
    {
      "type": "gradient",
      "gradientColors": [
        { "lightColor": "#FFFFFFFF", "darkColor": "#FF000000", "location": 0.0 },
        { "lightColor": "#00FFFFFF", "darkColor": "#00000000", "location": 0.4 }
      ],
      "gradientStart": "bottom",
      "gradientEnd": "top",
      "styleId": "heroGradient"
    }
  ]
}
```

### IR Mapping

```swift
// Document Model (decoded from JSON)
Document.Component(type: .gradient, gradientColors: [...], ...)

// IR (RenderNode)
GradientNode(
    id: "overlayGradient",
    gradientType: .linear,
    colors: [
        GradientNode.ColorStop(
            color: .adaptive(light: .white, dark: .black),
            location: 0.0
        ),
        GradientNode.ColorStop(
            color: .adaptive(light: .white.opacity(0), dark: .black.opacity(0)),
            location: 0.4
        )
    ],
    startPoint: .bottom,
    endPoint: .top,
    style: IR.Style(...)
)
```

---

## Spacer

A flexible space that expands to fill available space.

### JSON Schema

```json
{
  "type": "spacer"
}
```

### Usage

Spacers are commonly used to:
- Push content to edges
- Create equal spacing between elements
- Center content vertically or horizontally

### Example

```json
{
  "type": "vstack",
  "children": [
    { "type": "spacer" },
    { "type": "label", "label": "Centered Content" },
    { "type": "spacer" }
  ]
}
```

### IR Mapping

```swift
// IR
RenderNode.spacer
```

---

## Common Properties

All components share these optional properties:

| Property | Type | Description |
|----------|------|-------------|
| `id` | `string` | Unique identifier for the component |
| `styleId` | `string` | Reference to a named style |

## Data References

Components can reference data in two ways:

### Inline Data Reference

```json
{
  "data": {
    "type": "static",
    "value": "Hello World"
  }
}
```

### Named Data Source

```json
{
  "dataSources": {
    "greeting": { "type": "static", "value": "Hello World" }
  },
  "root": {
    "children": [
      {
        "type": "label",
        "dataSourceId": "greeting"
      }
    ]
  }
}
```

### Binding Data Reference

```json
{
  "data": {
    "type": "binding",
    "path": "user.name"
  }
}
```

### Template Data Reference

```json
{
  "data": {
    "type": "binding",
    "template": "Hello, ${user.name}!"
  }
}
```
