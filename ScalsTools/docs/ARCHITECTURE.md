# ScalsTools - Architecture Documentation

Internal architecture and design decisions for ScalsTools

---

## System Overview

```
┌─────────────────────────────────────────────────────────┐
│                    ScalsTools Suite                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │           ScalsToolsCore (Shared Library)        │   │
│  │  ┌────────────────┐  ┌──────────────────────┐  │   │
│  │  │ CLIUtilities   │  │  TemplateEngine      │  │   │
│  │  │ - Console      │  │  - Stencil-based     │  │   │
│  │  │ - FileSystem   │  │  - Custom filters    │  │   │
│  │  │ - Progress     │  │  - Code generation   │  │   │
│  │  └────────────────┘  └──────────────────────┘  │   │
│  │  ┌────────────────┐  ┌──────────────────────┐  │   │
│  │  │ String Utils   │  │  SwiftCodeAnalyzer   │  │   │
│  │  │ - snake_case   │  │  - AST parsing       │  │   │
│  │  │ - PascalCase   │  │  - Code inspection   │  │   │
│  │  └────────────────┘  └──────────────────────┘  │   │
│  └──────────────────────────────────────────────────┘   │
│                          ▲                                │
│                          │                                │
│  ┌───────────────────────┴──────────────────────────┐   │
│  │              Individual CLI Tools                 │   │
│  ├───────────────────────────────────────────────────┤   │
│  │  - ConsistencyChecker  - ComponentGenerator      │   │
│  │  - PropertyValidator   - TestGenerator           │   │
│  │  - ReferenceGenerator  - ActionGenerator         │   │
│  │  - And 6 more...                                  │   │
│  └───────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
           ┌──────────────────────────────┐
           │     ScalsFramework Files     │
           ├──────────────────────────────┤
           │  ScalsModules/               │
           │  SCALS/                      │
           │  SCALSTests/                 │
           └──────────────────────────────┘
```

---

## Core Principles

### 1. Single Responsibility
Each tool does one thing well:
- **ConsistencyChecker**: Only validates consistency
- **ComponentGenerator**: Only generates components
- **TestGenerator**: Only generates tests

### 2. Shared Utilities
Common functionality in ScalsToolsCore:
- Console output
- File operations
- Template rendering
- Code analysis

### 3. Composition Over Inheritance
Tools use ScalsToolsCore utilities, not inheritance hierarchies

### 4. CLI-First Design
All tools are command-line executables:
- Easy CI/CD integration
- IDE-agnostic
- Scriptable
- LLM-friendly

---

## ScalsToolsCore Components

### Console Module

**Purpose**: Standardized output formatting

**Implementation**:
```swift
public enum Console {
    public static func success(_ message: String)  // ✅
    public static func error(_ message: String)    // ❌
    public static func warning(_ message: String)  // ⚠️
    public static func info(_ message: String)     // ℹ️
    public static func section(_ title: String)    // ====
    public static func subsection(_ title: String) // ---
    public static func progress(_ message: String) // ⏳
}
```

**Why Emojis**: Universal, language-independent, visually distinctive

---

### FileSystemUtilities Module

**Purpose**: Safe file operations with error handling

**Key Functions**:
- `findFile(named:in:)` - Recursive file search
- `findFiles(withExtension:in:)` - Find all files of type
- `readFile(at:)` - Read with UTF-8 encoding
- `writeFile(at:content:)` - Write with directory creation
- `fileExists(at:)` - Existence check

**Safety Features**:
- Creates intermediate directories automatically
- UTF-8 encoding enforced
- URL-based (no string path manipulation)

---

### TemplateEngine Module

**Purpose**: Code generation from templates

**Built on**: [Stencil](https://github.com/stencilproject/Stencil)

**Custom Filters**:
```swift
{{ componentName|snakeCase }}     // button_component
{{ componentName|pascalCase }}    // ButtonComponent
{{ componentName|camelCase }}     // buttonComponent
{{ code|indent:4 }}               // Indent by 4 spaces
```

**Usage Pattern**:
```swift
let engine = TemplateEngine()
let context = [
    "name": "Button",
    "properties": ["text", "action"]
]
let code = try engine.render(template: template, context: context)
```

---

### SwiftCodeAnalyzer Module

**Purpose**: Inspect Swift source code structure

**Built on**: [SwiftSyntax](https://github.com/swiftlang/swift-syntax)

**Extracts**:
- Struct definitions
- Class definitions
- Enum cases
- Protocol requirements
- Properties (with modifiers)
- Methods (with signatures)
- Conformances

**Usage Pattern**:
```swift
let analyzer = SwiftCodeAnalyzer()
let analysis = try analyzer.analyzeFile(at: url)

for struct in analysis.structs {
    print("Struct: \(struct.name)")
    for property in struct.properties {
        print("  - \(property.name): \(property.type)")
    }
}
```

**Visitor Pattern**:
Uses SwiftSyntax's `SyntaxVisitor` to traverse AST:
```swift
class CodeVisitor: SyntaxVisitor {
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Extract struct info
        return .visitChildren
    }
}
```

---

### String Extensions

**Purpose**: Common text transformations

**Implementations**:
```swift
extension String {
    var snakeCase: String {
        // PascalCase → snake_case using regex
    }

    var pascalCase: String {
        // snake_case → PascalCase
    }

    var camelCase: String {
        // snake_case → camelCase
    }

    func indented(by: Int) -> String {
        // Add spaces to each line
    }
}
```

---

### ProgressTracker

**Purpose**: Show progress for long operations

**Usage**:
```swift
let progress = ProgressTracker(total: 100, title: "Processing")

for item in items {
    // Do work
    progress.increment("Processing \(item.name)")
}

progress.complete()
```

**Output**:
```
⏳ [10%] Processing item1
⏳ [20%] Processing item2
...
✅ Processing complete! (100 items)
```

---

## Tool Architecture Pattern

Each tool follows this structure:

```swift
import ArgumentParser
import ScalsToolsCore

@main
struct ToolName: ParsableCommand {
    // Configuration
    static let configuration = CommandConfiguration(
        commandName: "scals-tool-name",
        abstract: "Brief description"
    )

    // Arguments
    @Option(name: .long) var frameworkPath: String = ".."
    @Flag(name: .long) var verbose: Bool = false

    // Execution
    func run() throws {
        Console.section("Tool Name")

        // 1. Validate inputs
        let baseURL = URL(fileURLWithPath: frameworkPath)

        // 2. Perform analysis/generation
        // Use ScalsToolsCore utilities

        // 3. Report results
        Console.success("Done!")

        // 4. Exit with code
        if hasErrors {
            throw ExitCode(1)
        }
    }
}
```

---

## Dependencies

### ArgumentParser
**Why**: Standard Apple CLI argument parsing
**Features**:
- Type-safe arguments
- Auto-generated help
- Validation support
- Subcommands

### Stencil
**Why**: Mustache-compatible templates
**Features**:
- Template inheritance
- Custom filters
- Good Swift integration

### SwiftSyntax
**Why**: Official Swift AST library
**Features**:
- Parse Swift code
- Inspect structure
- Generate code
**Caveat**: Version must match Swift compiler version

---

## Code Generation Strategy

### Template-Based Generation

**When**: Generating files with predictable structure

**Approach**:
1. Define template with placeholders
2. Build context dictionary
3. Render template
4. Write to file

**Example**:
```
Template: ComponentResolver.stencil
Context: { "name": "Video", "properties": [...] }
Output: VideoComponentResolver.swift
```

### AST-Based Generation

**When**: Modifying existing Swift code

**Approach**:
1. Parse existing file
2. Analyze structure
3. Generate modifications
4. Rewrite file

**Example**: Adding property to existing struct

---

## Validation Strategy

### Multi-Layer Validation

1. **Structural**: Files exist in expected locations
2. **Naming**: Follow conventions
3. **Content**: Code structure correct
4. **Registration**: Components registered
5. **Testing**: Tests exist and pass

### Consistency Checks

```
┌─────────────────────┐
│  ComponentResolver  │ ─┐
└─────────────────────┘  │
                         │  All must
┌─────────────────────┐  │  be consistent
│    RenderNode       │ ─┤
└─────────────────────┘  │
                         │
┌─────────────────────┐  │
│     Renderer        │ ─┤
└─────────────────────┘  │
                         │
┌─────────────────────┐  │
│      Tests          │ ─┘
└─────────────────────┘
```

---

## Error Handling

### User-Friendly Errors

```swift
// Bad
throw NSError(domain: "Error", code: 1)

// Good
Console.error("Component 'Video' not found in ScalsModules/ComponentResolvers/")
Console.info("Expected file: VideoComponentResolver.swift")
throw ExitCode(1)
```

### Exit Codes

- `0`: Success
- `1`: Validation failed or operation error
- `2`: Invalid arguments
- `3`: File not found

---

## Testing Strategy

### Unit Tests
Test ScalsToolsCore utilities in isolation:
```swift
@Test func testSnakeCaseConversion() {
    #expect("FooBar".snakeCase == "foo_bar")
}
```

### Integration Tests
Test tools against sample framework structure:
```swift
@Test func testConsistencyChecker() {
    // Create temp framework structure
    // Run checker
    // Verify output
}
```

---

## Performance Considerations

### File System Operations
- Cache file lists to avoid repeated scans
- Use URL-based APIs (faster than string paths)
- Enumerate instead of recursive search when possible

### Code Analysis
- SwiftSyntax parsing is expensive - cache results
- Only analyze files that changed
- Use incremental parsing when available

### Template Rendering
- Pre-compile templates
- Reuse TemplateEngine instance
- Cache rendered snippets

---

## Security Considerations

### Path Traversal
- Always use URL-based APIs
- Validate paths are within framework
- No user input in file paths without validation

### Code Injection
- Template contexts are typed dictionaries
- No string interpolation in templates
- Validate all user input

### File Permissions
- Check write permissions before operations
- Don't modify files outside framework
- Preserve file permissions

---

## Extensibility

### Adding New Tool

1. Create executable target in Package.swift
2. Implement ParsableCommand
3. Use ScalsToolsCore utilities
4. Follow naming convention: `scals-*`

### Adding New Utility

1. Add to ScalsToolsCore
2. Make public
3. Document usage
4. Add tests

### Adding Template Filter

```swift
let ext = Extension()
ext.registerFilter("myFilter") { (value: Any?) in
    // Transform value
    return result
}
```

---

## Future Architecture

### Planned Improvements

1. **Plugin System**: Allow custom tools
2. **Configuration File**: `.scalstools.yml`
3. **Watch Mode**: Auto-run on file changes
4. **JSON Output**: For programmatic use
5. **Interactive Mode**: Wizard-style interfaces

---

## Related Documentation

- User Guide: `README.md`
- LLM Guide: `docs/LLM_USAGE_GUIDE.md`
- Maintainer Guide: `docs/MAINTAINER_GUIDE.md`
- Quick Start: `docs/QUICK_START.md`
