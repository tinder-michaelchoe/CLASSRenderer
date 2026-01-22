# SCALS JSON Schema Reference

This document provides a complete reference for authoring SCALS JSON documents. The schema defines the structure for server-driven UI that gets rendered to native SwiftUI or UIKit views.

## Document Structure

A SCALS document has the following top-level structure:

```json
{
  "id": "screen-id",
  "version": "1.0",
  "designSystem": "lightspeed",
  "state": { ... },
  "styles": { ... },
  "dataSources": { ... },
  "actions": { ... },
  "root": { ... }
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Unique identifier for the document |
| `root` | `object` | Root container for all UI elements |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | `string` | Document version string |
| `designSystem` | `string` | Design system identifier (e.g., "lightspeed"). Client must inject matching `DesignSystemProvider` |
| `state` | `object` | Initial state values |
| `styles` | `object` | Named style definitions |
| `dataSources` | `object` | Named data source definitions |
| `actions` | `object` | Named action definitions |

---

## Root Component

The `root` object is the container for all UI elements.

```json
{
  "root": {
    "backgroundColor": "#FFFFFF",
    "colorScheme": "system",
    "edgeInsets": {
      "top": 16,
      "bottom": { "positioning": "absolute", "value": 0 }
    },
    "actions": {
      "onAppear": "loadData",
      "onDisappear": "saveState"
    },
    "children": [ ... ]
  }
}
```

### Root Properties

| Property | Type | Description |
|----------|------|-------------|
| `children` | `array` | **Required.** Array of layout nodes |
| `backgroundColor` | `string` | Background color (hex string) |
| `colorScheme` | `"light" \| "dark" \| "system"` | Color scheme preference |
| `styleId` | `string` | Style reference (use `@` prefix for design system) |
| `edgeInsets` | `object` | Edge insets configuration |
| `actions` | `object` | Lifecycle actions (`onAppear`, `onDisappear`) |

### Edge Insets

Edge insets can be simple numbers (safe area relative) or objects with positioning:

```json
{
  "edgeInsets": {
    "top": 16,
    "bottom": { "positioning": "absolute", "value": 0 },
    "leading": 20,
    "trailing": 20
  }
}
```

| Positioning | Description |
|-------------|-------------|
| `safeArea` | Default. Inset is relative to safe area |
| `absolute` | Inset is relative to screen edge (ignores safe area) |

---

## Layout Nodes

Layout nodes are the building blocks of the UI tree. A layout node can be:

- **Layout** - Container (vstack, hstack, zstack)
- **SectionLayout** - Section-based scrolling layout
- **ForEach** - Iteration over arrays
- **Component** - Leaf UI elements
- **Spacer** - Flexible space

### Layout Containers

```json
{
  "type": "vstack",
  "alignment": "center",
  "spacing": 16,
  "padding": { "horizontal": 20, "vertical": 10 },
  "children": [ ... ]
}
```

| Property | Type | Description |
|----------|------|-------------|
| `type` | `"vstack" \| "hstack" \| "zstack"` | **Required.** Container type |
| `alignment` | `string \| object` | Content alignment |
| `spacing` | `number` | Spacing between children (points) |
| `padding` | `object` | Padding specification |
| `state` | `object` | Local state for this scope |
| `children` | `array` | Child layout nodes |

#### Alignment

For `vstack` and `hstack`:
```json
"alignment": "leading" | "center" | "trailing"
```

For `zstack` (2D alignment):
```json
"alignment": {
  "horizontal": "leading" | "center" | "trailing",
  "vertical": "top" | "center" | "bottom"
}
```

#### Padding

```json
{
  "padding": {
    "top": 10,
    "bottom": 10,
    "leading": 20,
    "trailing": 20
  }
}

// Or using shorthands:
{
  "padding": {
    "horizontal": 20,
    "vertical": 10
  }
}
```

### Spacer

A flexible space that expands to fill available space:

```json
{ "type": "spacer" }
```

---

## Section Layout

Section-based layouts for heterogeneous scrolling content (lists, grids, carousels):

```json
{
  "type": "sectionLayout",
  "sectionSpacing": 24,
  "sections": [
    {
      "id": "featured",
      "layout": {
        "type": "horizontal",
        "itemSpacing": 16,
        "itemDimensions": { "width": 280, "height": 200 },
        "snapBehavior": "viewAligned"
      },
      "header": { "type": "label", "text": "Featured" },
      "children": [ ... ]
    },
    {
      "id": "grid-section",
      "layout": {
        "type": "grid",
        "columns": { "adaptive": { "minWidth": 150 } },
        "itemSpacing": 12,
        "lineSpacing": 12
      },
      "dataSource": "items",
      "itemTemplate": { ... }
    }
  ]
}
```

### Section Definition

| Property | Type | Description |
|----------|------|-------------|
| `id` | `string` | Section identifier |
| `layout` | `object` | **Required.** Layout configuration |
| `header` | `layoutNode` | Optional header |
| `footer` | `layoutNode` | Optional footer |
| `stickyHeader` | `boolean` | Make header sticky |
| `children` | `array` | Static children |
| `dataSource` | `string` | State path to array for data-driven content |
| `itemTemplate` | `layoutNode` | Template for data-driven items |

### Section Layout Types

#### Horizontal (Carousel)

```json
{
  "type": "horizontal",
  "itemSpacing": 16,
  "contentInsets": { "horizontal": 20 },
  "itemDimensions": {
    "width": 280,
    "height": { "fractional": 0.4 }
  },
  "showsIndicators": false,
  "isPagingEnabled": true,
  "snapBehavior": "viewAligned"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `itemSpacing` | `number` | Space between items |
| `contentInsets` | `padding` | Content insets |
| `itemDimensions` | `object` | Item width/height/aspectRatio |
| `showsIndicators` | `boolean` | Show scroll indicators |
| `isPagingEnabled` | `boolean` | Enable paging |
| `snapBehavior` | `"none" \| "viewAligned" \| "paging"` | Snap behavior |

#### List

```json
{
  "type": "list",
  "showsDividers": true,
  "contentInsets": { "vertical": 8 }
}
```

#### Grid

```json
{
  "type": "grid",
  "columns": 3,
  "itemSpacing": 12,
  "lineSpacing": 12
}

// Or adaptive columns:
{
  "type": "grid",
  "columns": { "adaptive": { "minWidth": 150 } }
}
```

#### Flow

```json
{
  "type": "flow",
  "alignment": "leading",
  "itemSpacing": 8,
  "lineSpacing": 8
}
```

### Dimension Values

Dimensions can be absolute or fractional:

```json
// Absolute (points)
"width": 280

// Fractional (0.0 to 1.0 of container)
"width": { "fractional": 0.8 }

// Explicit absolute
"width": { "absolute": 280 }
```

---

## ForEach

Iterate over arrays in state:

```json
{
  "type": "forEach",
  "items": "todos",
  "itemVariable": "todo",
  "indexVariable": "idx",
  "layout": "vstack",
  "spacing": 8,
  "template": {
    "type": "label",
    "text": "${todo.title}"
  },
  "emptyView": {
    "type": "label",
    "text": "No items"
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `type` | `"forEach"` | **Required** |
| `items` | `string` | **Required.** State path to array |
| `template` | `layoutNode` | **Required.** Template for each item |
| `itemVariable` | `string` | Variable name for current item (default: `"item"`) |
| `indexVariable` | `string` | Variable name for index (default: `"index"`) |
| `layout` | `"vstack" \| "hstack" \| "zstack"` | Container type (default: `"vstack"`) |
| `spacing` | `number` | Spacing between items |
| `alignment` | `string` | Content alignment |
| `padding` | `object` | Padding |
| `emptyView` | `layoutNode` | View to show when array is empty |

---

## Components

Leaf UI components that render actual content.

### Common Properties

All components support these properties:

| Property | Type | Description |
|----------|------|-------------|
| `type` | `string` | **Required.** Component type |
| `id` | `string` | Component identifier |
| `styleId` | `string` | Style reference. Use `@` prefix for design system (e.g., `@button.primary`) |
| `styles` | `object` | State-based styles (`normal`, `selected`, `disabled`) |
| `padding` | `object` | Padding |
| `actions` | `object` | Action bindings (`onTap`, `onValueChanged`) |
| `data` | `object` | Data references for component content |
| `state` | `object` | Local state for this component |

### Label (Text)

```json
{
  "type": "label",
  "text": "Hello, ${user.name}!",
  "styleId": "@text.heading1"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `text` | `string` | Text content. Supports `${path}` bindings |

### Button

```json
{
  "type": "button",
  "text": "Submit",
  "styleId": "@button.primary",
  "fillWidth": true,
  "actions": {
    "onTap": "submitForm"
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `text` | `string` | Button label |
| `fillWidth` | `boolean` | Expand to fill width |
| `isSelectedBinding` | `string` | Expression for selected state |
| `styles` | `object` | State-based styles |

#### State-Based Styles

```json
{
  "type": "button",
  "text": "Option A",
  "styles": {
    "normal": "optionNormal",
    "selected": "optionSelected",
    "disabled": "optionDisabled"
  },
  "isSelectedBinding": "${selectedOption == \"A\"}"
}
```

### TextField

```json
{
  "type": "textfield",
  "placeholder": "Enter your name",
  "bind": "form.name",
  "styleId": "@textField.default"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `placeholder` | `string` | Placeholder text |
| `bind` | `string` | State path for two-way binding |
| `localBind` | `string` | Local state path (without `local.` prefix) |

### Toggle

```json
{
  "type": "toggle",
  "bind": "settings.darkMode"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `bind` | `string` | State path to boolean value |

### Slider

```json
{
  "type": "slider",
  "bind": "volume",
  "minValue": 0,
  "maxValue": 100
}
```

| Property | Type | Description |
|----------|------|-------------|
| `bind` | `string` | State path to numeric value |
| `minValue` | `number` | Minimum value (default: 0) |
| `maxValue` | `number` | Maximum value (default: 1) |

### Image

```json
{
  "type": "image",
  "image": {
    "url": "${artwork.imageUrl}",
    "placeholder": { "sfsymbol": "photo" },
    "loading": { "sfsymbol": "arrow.2.circlepath" }
  },
  "styleId": "artworkImage",
  "actions": { "onTap": "showFullscreen" }
}
```

#### Image Source Types

```json
// SF Symbol
{ "sfsymbol": "star.fill" }

// Asset catalog
{ "asset": "logo" }

// Remote URL (supports ${path} templates)
{ "url": "https://example.com/image.jpg" }
{ "url": "${user.avatarUrl}" }
```

| Property | Type | Description |
|----------|------|-------------|
| `image` | `object` | **Required.** Image source |
| `image.sfsymbol` | `string` | SF Symbol name |
| `image.asset` | `string` | Asset catalog name |
| `image.url` | `string` | Remote URL (supports `${path}` templates) |
| `image.placeholder` | `object` | Placeholder for empty/error states |
| `image.loading` | `object` | Loading indicator image |

### Gradient

```json
{
  "type": "gradient",
  "gradientColors": [
    { "color": "#00000000", "location": 0 },
    { "color": "#000000CC", "location": 1 }
  ],
  "gradientStart": "top",
  "gradientEnd": "bottom"
}
```

#### Adaptive Colors (Dark Mode)

```json
{
  "gradientColors": [
    {
      "lightColor": "#FFFFFF",
      "darkColor": "#000000",
      "location": 0
    },
    {
      "lightColor": "#F0F0F0",
      "darkColor": "#1A1A1A",
      "location": 1
    }
  ]
}
```

| Property | Type | Description |
|----------|------|-------------|
| `gradientColors` | `array` | Color stops with location (0.0-1.0) |
| `gradientStart` | `string` | Start point |
| `gradientEnd` | `string` | End point |

**Points:** `top`, `bottom`, `leading`, `trailing`, `topLeading`, `topTrailing`, `bottomLeading`, `bottomTrailing`

### Divider

```json
{
  "type": "divider",
  "styleId": "dividerStyle"
}
```

---

## Styles

Named style definitions with inheritance support:

```json
{
  "styles": {
    "baseButton": {
      "cornerRadius": 12,
      "paddingTop": 14,
      "paddingBottom": 14
    },
    "primaryButton": {
      "inherits": "baseButton",
      "backgroundColor": "#6366F1",
      "textColor": "#FFFFFF"
    },
    "secondaryButton": {
      "inherits": "baseButton",
      "backgroundColor": "#F3F4F6",
      "textColor": "#374151"
    }
  }
}
```

### Style Properties

| Property | Type | Description |
|----------|------|-------------|
| `inherits` | `string` | Parent style ID |
| **Typography** | | |
| `fontFamily` | `string` | Font family name |
| `fontSize` | `number` | Font size (points) |
| `fontWeight` | `string` | `ultraLight`, `thin`, `light`, `regular`, `medium`, `semibold`, `bold`, `heavy`, `black` |
| `textColor` | `string` | Text color (hex) |
| `textAlignment` | `string` | `leading`, `center`, `trailing` |
| **Background** | | |
| `backgroundColor` | `string` | Background color (hex) |
| **Border** | | |
| `cornerRadius` | `number` | Corner radius (points) |
| `borderWidth` | `number` | Border width (points) |
| `borderColor` | `string` | Border color (hex) |
| **Dimensions** | | |
| `width` | `number` | Fixed width |
| `height` | `number` | Fixed height |
| `minWidth` | `number` | Minimum width |
| `minHeight` | `number` | Minimum height |
| `maxWidth` | `number` | Maximum width |
| `maxHeight` | `number` | Maximum height |
| **Image** | | |
| `tintColor` | `string` | Tint color for images (hex) |
| **Padding** | | |
| `padding` | `object` | Padding specification |

### Design System Styles

Reference design system styles with `@` prefix:

```json
{
  "type": "button",
  "styleId": "@button.primary"
}
```

The client must inject a matching `DesignSystemProvider` to resolve these styles.

---

## State

Initial state values for the document:

```json
{
  "state": {
    "count": 0,
    "user": {
      "name": "John",
      "email": "john@example.com"
    },
    "items": [],
    "isLoading": false
  }
}
```

State values can be:
- `null`
- `boolean`
- `integer`
- `number`
- `string`
- `array`
- `object`

### Accessing State

Use `${path}` syntax in text and templates:

```json
{
  "type": "label",
  "text": "Hello, ${user.name}! You have ${items.length} items."
}
```

### Local State

Components and layouts can declare local state:

```json
{
  "type": "vstack",
  "state": {
    "isExpanded": false
  },
  "children": [
    {
      "type": "button",
      "text": "Toggle",
      "actions": {
        "onTap": {
          "type": "toggleState",
          "path": "local.isExpanded"
        }
      }
    }
  ]
}
```

---

## Data Sources

Named data source definitions:

```json
{
  "dataSources": {
    "greeting": {
      "type": "static",
      "value": "Hello, World!"
    },
    "userName": {
      "type": "binding",
      "path": "user.name"
    },
    "welcomeMessage": {
      "type": "binding",
      "template": "Welcome back, ${user.name}!"
    }
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `type` | `"static" \| "binding"` | **Required.** Data source type |
| `value` | `string` | Static value (for `static` type) |
| `path` | `string` | State path (for `binding` type) |
| `template` | `string` | Template with `${path}` placeholders |

### Using Data Sources

Reference in components with `dataSourceId`:

```json
{
  "type": "label",
  "dataSourceId": "welcomeMessage"
}
```

Or use `data` for inline references:

```json
{
  "type": "customComponent",
  "data": {
    "title": { "type": "binding", "path": "item.title" },
    "subtitle": { "type": "static", "value": "Details" },
    "count": { "type": "localBinding", "path": "localCount" }
  }
}
```

---

## Actions

Actions define behavior triggered by user interactions or lifecycle events.

### Action Types

#### dismiss

Close the current view:

```json
{ "type": "dismiss" }
```

#### setState

Set a value in state:

```json
{
  "type": "setState",
  "path": "count",
  "value": 0
}
```

With expression:

```json
{
  "type": "setState",
  "path": "count",
  "value": { "$expr": "count + 1" }
}
```

#### toggleState

Toggle a boolean value:

```json
{
  "type": "toggleState",
  "path": "isEnabled"
}
```

#### showAlert

Display an alert dialog:

```json
{
  "type": "showAlert",
  "title": "Confirm",
  "message": "Are you sure?",
  "buttons": [
    { "label": "Cancel", "style": "cancel" },
    { "label": "Delete", "style": "destructive", "action": "performDelete" }
  ]
}
```

With template message:

```json
{
  "type": "showAlert",
  "title": "Success",
  "message": {
    "type": "binding",
    "template": "Created ${item.name} successfully!"
  }
}
```

Button styles: `default`, `cancel`, `destructive`

#### navigate

Navigate to another view:

```json
{
  "type": "navigate",
  "destination": "details",
  "presentation": "push"
}
```

Presentation styles: `push`, `present`, `fullScreen`

#### sequence

Execute multiple actions in order:

```json
{
  "type": "sequence",
  "steps": [
    { "type": "setState", "path": "isLoading", "value": true },
    { "type": "showAlert", "title": "Loading..." }
  ]
}
```

#### request (HTTP)

Make HTTP requests:

```json
{
  "type": "request",
  "method": "POST",
  "url": "https://api.example.com/users/${userId}",
  "headers": [
    { "name": "Authorization", "value": "Bearer ${auth.token}" }
  ],
  "body": [
    { "path": "form.name" },
    { "path": "form.email", "as": "emailAddress" }
  ],
  "loadingPath": "api.isLoading",
  "responsePath": "api.response",
  "errorPath": "api.error",
  "onSuccess": "handleSuccess",
  "onError": "handleError",
  "timeout": 30,
  "debug": true
}
```

| Property | Type | Description |
|----------|------|-------------|
| `method` | `string` | **Required.** `GET`, `POST`, `PUT`, `PATCH`, `DELETE` |
| `url` | `string` | **Required.** URL with optional `${path}` interpolation |
| `requestId` | `string` | ID for cancellation |
| `headers` | `array` | HTTP headers |
| `queryParams` | `array` | Query string parameters |
| `body` | `array` | Request body fields |
| `contentType` | `string` | `json` (default) or `formUrlEncoded` |
| `timeout` | `number` | Timeout in seconds (default: 30) |
| `debug` | `boolean` | Enable request/response logging |
| `loadingPath` | `string` | State path for loading indicator |
| `responsePath` | `string` | State path to store response |
| `errorPath` | `string` | State path to store error |
| `onSuccess` | `string` | Action ID on success |
| `onError` | `string` | Action ID on error |

#### cancelRequest

Cancel an in-flight request:

```json
{
  "type": "cancelRequest",
  "requestId": "searchRequest"
}
```

#### Custom Actions

Any other action type is passed to registered handlers:

```json
{
  "type": "submitOrder",
  "orderId": "${order.id}",
  "priority": "high"
}
```

### Action Bindings

Actions can be referenced by ID or defined inline:

```json
{
  "actions": {
    "onTap": "submitForm"
  }
}

// Or inline:
{
  "actions": {
    "onTap": {
      "type": "setState",
      "path": "count",
      "value": { "$expr": "count + 1" }
    }
  }
}
```

---

## Complete Example

```json
{
  "id": "todo-list",
  "version": "1.0",
  "designSystem": "lightspeed",
  "state": {
    "todos": [],
    "newTodoText": "",
    "filter": "all"
  },
  "styles": {
    "todoItem": {
      "padding": { "horizontal": 16, "vertical": 12 },
      "backgroundColor": "#FFFFFF"
    },
    "completedTodo": {
      "inherits": "todoItem",
      "textColor": "#9CA3AF"
    }
  },
  "actions": {
    "addTodo": {
      "type": "sequence",
      "steps": [
        {
          "type": "setState",
          "path": "todos",
          "value": { "$expr": "todos.concat([{ text: newTodoText, completed: false }])" }
        },
        {
          "type": "setState",
          "path": "newTodoText",
          "value": ""
        }
      ]
    }
  },
  "root": {
    "backgroundColor": "#F9FAFB",
    "actions": {
      "onAppear": "loadTodos"
    },
    "children": [
      {
        "type": "vstack",
        "spacing": 16,
        "padding": { "horizontal": 20, "top": 20 },
        "children": [
          {
            "type": "label",
            "text": "My Todos",
            "styleId": "@text.heading1"
          },
          {
            "type": "hstack",
            "spacing": 12,
            "children": [
              {
                "type": "textfield",
                "placeholder": "Add a new todo...",
                "bind": "newTodoText",
                "styleId": "@textField.default"
              },
              {
                "type": "button",
                "text": "Add",
                "styleId": "@button.primary",
                "actions": { "onTap": "addTodo" }
              }
            ]
          },
          {
            "type": "forEach",
            "items": "todos",
            "itemVariable": "todo",
            "spacing": 8,
            "template": {
              "type": "hstack",
              "styleId": "todoItem",
              "children": [
                {
                  "type": "toggle",
                  "bind": "todo.completed"
                },
                {
                  "type": "label",
                  "text": "${todo.text}"
                }
              ]
            },
            "emptyView": {
              "type": "label",
              "text": "No todos yet. Add one above!",
              "styleId": "@text.caption"
            }
          }
        ]
      }
    ]
  }
}
```

---

## Schema Validation

The full JSON Schema is available at:
- Document Schema: `SCALS/Schema/scals-schema.json`
- IR Schema: `SCALS/Schema/scals-ir-schema.json`

Use these schemas with your IDE or validation tools to get autocomplete and error checking while authoring SCALS documents.
