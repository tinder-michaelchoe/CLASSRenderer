# ScalsTools - Development Workflows

Real-world examples of using ScalsTools in development

---

## Daily Development

### Starting a Development Session

```bash
# 1. Navigate to tools
cd ScalsTools

# 2. Check framework state
swift run scals-consistency-checker --framework-path ..

# 3. Review report
cat CONSISTENCY_REPORT.md

# 4. Plan work based on findings
```

**Typical output**:
```
============================================================
SCALS Component Consistency Checker
============================================================

ℹ️  Found 8 resolver files
⚠️  Found 16 issue(s)

============================================================
Summary
============================================================

⚠️  Found 16 issue(s)
```

**Action**: Review CONSISTENCY_REPORT.md to understand context

---

## Workflow 1: Adding a New Component

### Scenario
Add a new "Video" component to ScalsFramework

### Steps

#### 1. Plan the Component

**Properties needed**:
- `url`: String (video URL)
- `autoplay`: Boolean
- `controls`: Boolean
- `poster`: String? (thumbnail)

#### 2. Generate Component (Future)

```bash
# When generator is implemented:
swift run scals-component-generator \
  --name video \
  --properties '{
    "url": "string",
    "autoplay": "boolean",
    "controls": "boolean",
    "poster": "string?"
  }' \
  --platforms swiftui,html
```

**Generates**:
- `ScalsModules/ComponentResolvers/VideoComponentResolver.swift`
- `SCALS/IR/RenderNode+Video.swift`
- `SCALS/Renderers/SwiftUI/VideoRenderer.swift`
- Test skeleton
- Documentation

#### 3. Implement Resolver (Manual for now)

```swift
// ScalsModules/ComponentResolvers/VideoComponentResolver.swift

import SCALS

public struct VideoComponentResolver: ComponentResolving {
    public static let componentType: Document.ComponentKind = "video"

    public func resolve(
        _ component: Document.Component,
        context: ResolutionContext
    ) throws -> RenderNode {
        let style = try context.resolveStyle(
            styleId: component.styleId,
            baseStyle: component.style
        )

        return .video(
            VideoNode(
                id: component.id,
                url: try component.requireString("url"),
                autoplay: component.bool("autoplay") ?? false,
                controls: component.bool("controls") ?? true,
                poster: component.string("poster"),
                style: style
            )
        )
    }
}
```

#### 4. Define RenderNode

```swift
// SCALS/IR/RenderNode.swift (add case)
public enum RenderNode {
    case video(VideoNode)
    // ... existing cases
}

// SCALS/IR/VideoNode.swift (new file)
public struct VideoNode {
    public let id: String
    public let url: String
    public let autoplay: Bool
    public let controls: Bool
    public let poster: String?
    public let style: Style
}
```

#### 5. Register Component

```swift
// SCALS/IR/Resolution/ComponentResolverRegistry.swift
registry.register(VideoComponentResolver())
```

#### 6. Generate Tests (Future)

```bash
swift run scals-test-generator --component video
```

**Manual test for now**:
```swift
// Add to SCALSTests/Resolution/ComponentResolverTests.swift

struct VideoComponentResolutionTests {
    @Test func resolvesVideoWithUrl() throws {
        let component = Document.Component(
            type: "video",
            id: "testVideo",
            properties: ["url": "https://example.com/video.mp4"]
        )

        // Test resolution
    }
}
```

#### 7. Validate

```bash
# Check consistency
swift run scals-consistency-checker --framework-path ..

# Run tests
cd ..
swift test

# Build project
xcodebuild -project ScalsRenderer.xcodeproj -scheme ScalsRenderer build
```

---

## Workflow 2: Adding Property to Existing Component

### Scenario
Add `cornerRadius` property to Button component

### Steps

#### 1. Check Current Implementation

```bash
# View current button resolver
cat ../ScalsModules/ComponentResolvers/ButtonComponentResolver.swift

# Check current tests
grep -A 20 "ButtonComponentResolutionTests" ../SCALSTests/Resolution/ComponentResolverTests.swift
```

#### 2. Update Document Schema

```swift
// SCALS/Document/ComponentProperties.swift
// Add cornerRadius to component properties if not already there
```

#### 3. Update Resolver

```swift
// ScalsModules/ComponentResolvers/ButtonComponentResolver.swift

public func resolve(...) throws -> RenderNode {
    var style = try context.resolveStyle(...)

    // Add cornerRadius handling
    if let cornerRadius = component.properties["cornerRadius"] as? CGFloat {
        style.cornerRadius = cornerRadius
    }

    return .button(ButtonNode(..., style: style))
}
```

#### 4. Add Tests

```swift
// Add to ComponentResolverTests.swift

@Test func buttonWithCornerRadius() throws {
    let component = Document.Component(
        type: "button",
        id: "roundButton",
        properties: ["cornerRadius": 12.0]
    )

    // Test that cornerRadius is applied
}
```

#### 5. Validate Property Handling (Future)

```bash
swift run scals-property-validator --component button --property cornerRadius
```

**Checks**:
- ✅ Property in Document schema
- ✅ Resolver handles property
- ✅ Style applied to RenderNode
- ✅ Renderer uses property
- ✅ Tests cover property

---

## Workflow 3: Framework-Wide Refactoring

### Scenario
Add padding support to all components

### Steps

#### 1. Identify Affected Components

```bash
# List all resolvers
ls ../ScalsModules/ComponentResolvers/

# Count components
ls ../ScalsModules/ComponentResolvers/ | wc -l
```

Result: 8 components to update

#### 2. Update Base Types

```swift
// SCALS/Document/ComponentProperties.swift
// Add padding property type

public struct Padding: Codable {
    public let top: CGFloat?
    public let bottom: CGFloat?
    public let leading: CGFloat?
    public let trailing: CGFloat?
}
```

#### 3. Update Each Resolver (Future: Use Migration Assistant)

```bash
# When implemented:
swift run scals-migration-assistant \
  --feature "Add padding support" \
  --components all \
  --preview

# Review changes, then apply:
swift run scals-migration-assistant \
  --feature "Add padding support" \
  --components all \
  --apply
```

**Manual for now**: Update each resolver to handle padding

#### 4. Update Tests

Add padding tests to each component test struct

#### 5. Validate

```bash
# Check all components updated
swift run scals-consistency-checker --framework-path ..

# Run full test suite
cd .. && swift test
```

---

## Workflow 4: Debugging Inconsistencies

### Scenario
Consistency checker reports issues

### Steps

#### 1. Run Verbose Check

```bash
swift run scals-consistency-checker --framework-path .. --verbose
```

#### 2. Review Detailed Report

```bash
cat CONSISTENCY_REPORT.md
```

#### 3. Investigate Each Issue

**For missing tests**:
```bash
# Check if tests exist in different location
find ../SCALSTests -name "*Button*" -type f

# Check test content
grep -r "ButtonComponent" ../SCALSTests/
```

**For missing renderers**:
```bash
# Check renderer implementation
grep -r "ButtonNode" ../SCALS/Renderers/

# Check registry
grep "ButtonRenderer" ../SCALS/Renderers/SwiftUI/SwiftUINodeRendererRegistry.swift
```

#### 4. Fix or Document

If real issue: Fix it
If false positive: Document in CONSISTENCY_REPORT.md

---

## Workflow 5: Performance Optimization

### Scenario
JSON parsing seems slow

### Steps

#### 1. Profile Current Performance (Future)

```bash
swift run scals-performance-profiler \
  --examples ../ScalsExamples/Examples/*.json \
  --iterations 1000
```

**Output**:
```
⏳ Profiling 6 examples (1000 iterations each)

dad-jokes.json:
  Parse: 2.3ms average
  Resolve: 5.1ms average
  Render: 1.2ms average

task-manager.json:
  Parse: 4.5ms average (⚠️  slow)
  Resolve: 8.2ms average
  Render: 2.1ms average
```

#### 2. Identify Bottlenecks

```
Slowest operations:
1. task-manager.json parse (4.5ms)
2. shopping-cart.json resolve (9.1ms)
3. weather-dashboard.json render (3.2ms)
```

#### 3. Investigate

```bash
# Check file size
ls -lh ../ScalsExamples/Examples/task-manager.json

# Check complexity
jq '.root.children | length' ../ScalsExamples/Examples/task-manager.json
```

#### 4. Optimize

Based on findings:
- Simplify deeply nested structures
- Cache frequent lookups
- Optimize hot paths

#### 5. Re-profile

```bash
swift run scals-performance-profiler --examples ../ScalsExamples/Examples/task-manager.json
```

Verify improvements

---

## Workflow 6: Documentation Generation

### Scenario
Need to document new Video component

### Steps

#### 1. Generate Reference (Future)

```bash
swift run scals-reference-generator \
  --component video \
  --output ../Docs/components/video.md
```

**Generates**:
```markdown
# Video Component

## Overview
Displays video content with playback controls.

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| url | string | Yes | - | Video URL |
| autoplay | boolean | No | false | Auto-play video |
| controls | boolean | No | true | Show controls |
| poster | string | No | - | Thumbnail URL |

## Example

'''json
{
  "type": "video",
  "id": "intro",
  "url": "https://example.com/intro.mp4",
  "autoplay": true,
  "controls": true
}
'''

## Platform Support

- ✅ SwiftUI
- ✅ HTML
- ❌ UIKit
```

#### 2. Review and Customize

Edit generated markdown to add:
- Usage tips
- Common patterns
- Related components

#### 3. Add to Documentation

```bash
# Link from main docs
echo "- [Video](components/video.md)" >> ../Docs/COMPONENTS.md
```

---

## Workflow 7: CI/CD Integration

### Add to GitHub Actions

```yaml
# .github/workflows/scals-tools.yml

name: ScalsTools Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Build Tools
        working-directory: ScalsTools
        run: swift build -c release

      - name: Check Consistency
        working-directory: ScalsTools
        run: |
          swift run scals-consistency-checker --framework-path ..
          EXIT_CODE=$?
          cat CONSISTENCY_REPORT.md
          exit $EXIT_CODE

      - name: Upload Report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: consistency-report
          path: ScalsTools/CONSISTENCY_REPORT.md
```

### Add Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running ScalsTools consistency check..."
cd ScalsTools
swift run scals-consistency-checker --framework-path .. --quiet

if [ $? -ne 0 ]; then
    echo "❌ Consistency check failed"
    echo "Run: cd ScalsTools && swift run scals-consistency-checker --framework-path .. --verbose"
    echo ""
    echo "To bypass: git commit --no-verify"
    exit 1
fi

echo "✅ Consistency check passed"
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## Workflow 8: LLM-Assisted Development

### Using with Claude Code / ChatGPT / Copilot

#### 1. Share Context

```
I'm working on the ScalsFramework. I have ScalsTools available.
Current consistency status:

[paste output of: swift run scals-consistency-checker --framework-path ..]

I want to add a new Video component.
```

#### 2. Let LLM Use Tools

LLM can:
- Run consistency checks
- Generate code using templates
- Validate changes
- Update documentation

#### 3. Validate LLM Changes

```bash
# After LLM generates code
swift run scals-consistency-checker --framework-path ..
swift test
```

#### 4. Iterate

If validation fails, LLM can:
- Read error messages
- Check existing patterns
- Fix and re-validate

---

## Summary

### Key Workflows

1. **New Component**: Plan → Generate → Implement → Test → Validate
2. **Add Property**: Check → Update → Test → Validate
3. **Refactor**: Identify → Update All → Test → Validate
4. **Debug**: Check → Investigate → Fix → Verify
5. **Optimize**: Profile → Identify → Fix → Re-profile
6. **Document**: Generate → Customize → Link
7. **CI/CD**: Automate → Monitor → Act
8. **LLM**: Share Context → Use Tools → Validate → Iterate

### Best Practices

- ✅ Run consistency check before starting
- ✅ Validate after each change
- ✅ Use verbose mode when investigating
- ✅ Read generated reports
- ✅ Automate repetitive tasks
- ✅ Document custom patterns

---

## Next Steps

Choose a workflow that matches your task and follow the steps. Adapt as needed for your specific situation.
