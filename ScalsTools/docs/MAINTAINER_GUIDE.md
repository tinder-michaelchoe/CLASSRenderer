# ScalsTools - Maintainer Guide

**For Framework Maintainers**: How to use and maintain ScalsTools

---

## Overview

ScalsTools is a suite of CLI utilities designed to automate common development tasks for the ScalsFramework. These tools are specifically optimized for LLM-assisted development workflows.

---

## Installation

### Build Tools

```bash
cd ScalsTools
swift build -c release
```

### Install System-Wide (Optional)

```bash
# Copy executables to /usr/local/bin
cp .build/release/scals-* /usr/local/bin/

# Or create symlinks
ln -s $(pwd)/.build/release/scals-* /usr/local/bin/
```

### Verify Installation

```bash
scals-consistency-checker --help
```

---

## Tool Reference

### 1. Component Consistency Checker

**Status**: ✅ Implemented
**Priority**: High - Use regularly

**Purpose**: Validates component architecture consistency

**Usage**:
```bash
scals-consistency-checker --framework-path /path/to/framework [--verbose]
```

**Checks**:
- Component resolver files exist
- Test coverage (currently expects individual files)
- Renderer implementations (currently expects individual files)

**Known Issues**:
- Expects individual test files, framework uses centralized `ComponentResolverTests.swift`
- Expects individual renderer files, framework uses registry pattern
- See `CONSISTENCY_REPORT.md` for details

**Future Improvements**:
- Update to match actual framework architecture
- Add property coverage validation
- Check registry registrations
- Validate protocol conformance

---

### 2. Component Generator

**Status**: 🚧 Stub implemented
**Priority**: High

**Planned Features**:
- Generate ComponentResolver
- Generate RenderNode definition
- Generate test skeleton
- Generate renderer stubs
- Register in appropriate registries
- Generate documentation

---

### 3-12. Other Tools

**Status**: 🚧 Stubs implemented
See `Package.swift` for full list

---

## Adding a New Tool

### Step 1: Create Source Directory

```bash
mkdir -p Sources/NewTool
```

### Step 2: Add to Package.swift

```swift
.executableTarget(
    name: "NewTool",
    dependencies: [
        "ScalsToolsCore",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ],
    path: "Sources/NewTool"
)
```

### Step 3: Create main.swift

```swift
import ArgumentParser
import ScalsToolsCore

@main
struct NewTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scals-new-tool",
        abstract: "Description of tool"
    )

    @Option(name: .long, help: "Framework path")
    var frameworkPath: String = ".."

    func run() throws {
        Console.section("New Tool")
        // Implementation
    }
}
```

### Step 4: Build and Test

```bash
swift build
swift run scals-new-tool --help
```

---

## ScalsToolsCore Utilities

### Console Output

```swift
Console.success("Operation succeeded")  // ✅
Console.error("Operation failed")       // ❌
Console.warning("Check this")           // ⚠️
Console.info("FYI")                     // ℹ️
Console.section("Section Title")        // ====
Console.subsection("Subsection")        // ---
Console.progress("Working...")          // ⏳
```

### File System Operations

```swift
// Find file by name
let url = try FileSystemUtilities.findFile(named: "Package.swift", in: baseURL)

// Find files by extension
let swiftFiles = try FileSystemUtilities.findFiles(withExtension: "swift", in: directory)

// Read file
let content = try FileSystemUtilities.readFile(at: url)

// Write file
try FileSystemUtilities.writeFile(at: url, content: "...")

// Check existence
if FileSystemUtilities.fileExists(at: url) { }
```

### String Utilities

```swift
let snake = "FooBar".snakeCase        // "foo_bar"
let pascal = "foo_bar".pascalCase     // "FooBar"
let camel = "foo_bar".camelCase       // "fooBar"
let indented = text.indented(by: 4)   // Add 4 spaces to each line
```

### Template Engine

```swift
let engine = TemplateEngine()
let context = ["name": "Button", "properties": [...]]
let output = try engine.render(template: template, context: context)
```

Templates support filters:
- `{{ name|snakeCase }}`
- `{{ name|pascalCase }}`
- `{{ name|camelCase }}`
- `{{ code|indent:4 }}`

### Code Analysis (SwiftSyntax)

```swift
let analyzer = SwiftCodeAnalyzer()
let analysis = try analyzer.analyzeFile(at: url)

// Access results
for struct in analysis.structs {
    print("\(struct.name): \(struct.properties.count) properties")
}
```

### Progress Tracking

```swift
let progress = ProgressTracker(total: 10, title: "Processing")
for item in items {
    progress.increment("Processing \(item)")
}
progress.complete()
```

---

## Testing

### Run All Tests

```bash
swift test
```

### Add New Test

Create `Tests/[TargetName]Tests/[TestFile].swift`:

```swift
import Testing
@testable import ScalsToolsCore

struct MyTests {
    @Test func testSomething() {
        #expect(true)
    }
}
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: ScalsTools CI

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Build Tools
        working-directory: ScalsTools
        run: swift build
      - name: Run Tests
        working-directory: ScalsTools
        run: swift test
      - name: Run Consistency Check
        working-directory: ScalsTools
        run: swift run scals-consistency-checker --framework-path ..
```

### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

cd ScalsTools
swift run scals-consistency-checker --framework-path ..
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Consistency check failed"
    echo "Run: cd ScalsTools && swift run scals-consistency-checker --framework-path .. --verbose"
    exit 1
fi
```

---

## Updating Tools

### Update Dependencies

```bash
swift package update
swift build
```

### Update SwiftSyntax

SwiftSyntax versions are tied to Swift versions. Update carefully:

```swift
// Package.swift
.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
```

---

## Troubleshooting

### Build Failures

**Symptom**: `error: terminated(1)`

**Solution**:
```bash
swift package clean
rm -rf .build
swift package resolve
swift build
```

### Missing Dependencies

**Symptom**: `No such module 'ArgumentParser'`

**Solution**:
```bash
swift package resolve
```

### SwiftSyntax Errors

**Symptom**: Syntax API changed

**Solution**: Check SwiftSyntax version matches your Swift version
```bash
swift --version
```

---

## Architecture Decisions

### Why CLI Tools?

- Easy to integrate with CI/CD
- Works with any IDE/editor
- Can be called from LLM workflows
- Simple, focused interfaces

### Why Swift?

- Same language as framework
- Direct access to SwiftSyntax for code analysis
- Strong type system prevents errors
- Fast compilation and execution

### Why Stencil Templates?

- Familiar Mustache-like syntax
- Good Swift integration
- Supports custom filters
- Well maintained

---

## Roadmap

### Phase 1: Foundation (Complete)
- [x] Package structure
- [x] ScalsToolsCore utilities
- [x] Component Consistency Checker (v1)
- [x] Documentation

### Phase 2: Generators (In Progress)
- [ ] Update Consistency Checker for actual architecture
- [ ] Component Generator
- [ ] Test Generator
- [ ] Property Validator

### Phase 3: Advanced Tools
- [ ] Integration Test Generator
- [ ] Reference Generator
- [ ] Migration Assistant
- [ ] Performance Profiler

### Phase 4: Design System
- [ ] Action Generator
- [ ] Design System Generator
- [ ] Custom Component Generator
- [ ] Update Assistant

---

## Contributing

### Adding a New Tool

1. Create issue describing tool purpose
2. Add stub implementation
3. Implement core functionality
4. Add tests
5. Update documentation
6. Submit PR

### Code Style

- Follow Swift API Design Guidelines
- Use `Console` for all output
- Handle errors gracefully
- Provide `--help` text
- Add `--verbose` flag for debugging

### Documentation

Update these files when adding tools:
- `README.md` - User-facing documentation
- `docs/LLM_USAGE_GUIDE.md` - LLM integration
- `docs/MAINTAINER_GUIDE.md` - This file
- `Package.swift` - Tool registration

---

## Support

### Questions

- Check existing documentation
- Review similar tools
- Read ScalsToolsCore source

### Bugs

Create issue with:
- Tool name and version
- Command run
- Expected vs actual output
- Framework path and structure

### Feature Requests

Propose new tools or features:
- Clear use case
- Expected behavior
- Sample command syntax
- Integration points

---

## License

Same as ScalsFramework
