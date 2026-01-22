# ScalsTools - LLM Usage Guide

**For AI Assistants**: This guide explains how to use ScalsTools during development sessions

---

## Overview

ScalsTools provides automated code generation and validation utilities designed specifically for LLM-assisted development. These tools help you:

1. Maintain consistency across the framework
2. Generate boilerplate code quickly
3. Validate changes automatically
4. Create comprehensive tests

---

## Quick Start

### Running a Tool

```bash
# From project root
cd ScalsTools

# Run any tool
swift run <tool-name> [arguments]

# Example: Check component consistency
swift run scals-consistency-checker --framework-path .. --verbose
```

---

## When to Use Each Tool

### 🔍 Component Consistency Checker
**Use when**: Starting a development session or after making component changes

**Purpose**: Validate framework architecture and identify missing files

**Command**:
```bash
swift run scals-consistency-checker --framework-path .. --verbose
```

**What it checks**:
- Component resolver naming conventions
- Test file existence
- Renderer implementations
- File organization

**When LLM should run this**:
- [ ] At start of session (to understand current state)
- [ ] After creating new component
- [ ] After refactoring components
- [ ] Before committing changes

**Note**: Current version expects individual test/renderer files. Framework uses centralized pattern. See CONSISTENCY_REPORT.md for details.

---

### 🏗️ Component Generator (Coming Soon)
**Use when**: Creating a new component type

**Purpose**: Generate all necessary files for a new component

**Planned command**:
```bash
swift run scals-component-generator \
  --name video \
  --properties '{"url": "string", "autoplay": "boolean"}' \
  --platforms swiftui,html
```

**What it generates**:
- ComponentResolver implementation
- RenderNode definition
- Registry registration code
- Test skeleton
- Renderer stubs
- Documentation template

---

### ✅ Test Case Generator (Coming Soon)
**Use when**: Adding tests for existing components

**Purpose**: Generate test cases from JSON schema

**Planned command**:
```bash
swift run scals-test-generator \
  --schema ../Docs/scals-schema.json \
  --component button
```

---

### 🔧 Property Validator (Coming Soon)
**Use when**: Adding new properties to existing components

**Purpose**: Validate property handling across Document → IR → Renderer pipeline

**Planned command**:
```bash
swift run scals-property-validator --component button
```

---

## Development Workflow with ScalsTools

### Scenario 1: Creating a New Component

```bash
# Step 1: Generate component scaffolding
cd ScalsTools
swift run scals-component-generator \
  --name video \
  --properties '{"url": "string", "autoplay": "boolean"}'

# Step 2: Implement the resolver
# Edit: ScalsModules/ComponentResolvers/VideoComponentResolver.swift

# Step 3: Generate tests
swift run scals-test-generator --component video

# Step 4: Validate consistency
swift run scals-consistency-checker --framework-path .. --verbose

# Step 5: Generate documentation
swift run scals-reference-generator --component video
```

### Scenario 2: Adding Property to Existing Component

```bash
# Step 1: Check current state
swift run scals-property-validator --component button

# Step 2: Update component (manual)
# - Update Document.Component
# - Update ComponentResolver
# - Update RenderNode
# - Update Renderer

# Step 3: Validate changes
swift run scals-property-validator --component button

# Step 4: Generate tests for new property
swift run scals-test-generator \
  --component button \
  --property-only cornerRadius
```

### Scenario 3: Framework-Wide Migration

```bash
# Step 1: Run migration assistant
swift run scals-migration-assistant \
  --feature "Add padding support" \
  --components all

# Step 2: Review generated changes
# Assistant shows diff for each file

# Step 3: Apply changes
swift run scals-migration-assistant \
  --feature "Add padding support" \
  --components all \
  --apply

# Step 4: Validate consistency
swift run scals-consistency-checker --framework-path ..
```

---

## Integration with Development Session

### At Session Start

1. **Understand current state**:
   ```bash
   swift run scals-consistency-checker --framework-path .. --verbose
   ```

2. **Review issues** from CONSISTENCY_REPORT.md

3. **Plan work** based on findings

### During Development

1. **Generate code** instead of writing boilerplate
2. **Validate incrementally** after each component
3. **Run tests** automatically generated

### Before Committing

1. **Final consistency check**:
   ```bash
   swift run scals-consistency-checker --framework-path ..
   ```

2. **Run performance profiler** if applicable:
   ```bash
   swift run scals-performance-profiler --example ../ScalsExamples/Examples/*.json
   ```

3. **Generate documentation** for new components:
   ```bash
   swift run scals-reference-generator --component newComponent
   ```

---

## Output Interpretation

### Success Output
```
✅ Success message
ℹ️  Info message
```

### Warning Output
```
⚠️  Warning message
```
- Review but may not require action
- Could be false positive
- Check context

### Error Output
```
❌ Error message
```
- Requires action
- Blocks consistency
- Fix before proceeding

### Progress Output
```
⏳ Progress message
```
- Long-running operation
- Track completion

---

## File Locations

### Tools
- **Source**: `ScalsTools/Sources/[ToolName]/`
- **Executables**: `ScalsTools/.build/debug/scals-*`

### Framework Files
- **Components**: `ScalsModules/ComponentResolvers/`
- **Tests**: `SCALSTests/Resolution/`
- **Renderers**: `SCALS/Renderers/SwiftUI/`
- **IR**: `SCALS/IR/`
- **Document**: `SCALS/Document/`

---

## Common Patterns

### Reading Framework Code

Before generating code, understand existing patterns:

```bash
# Check how existing component is structured
cat ../ScalsModules/ComponentResolvers/ButtonComponentResolver.swift

# Check test patterns
cat ../SCALSTests/Resolution/ComponentResolverTests.swift

# Check renderer patterns
cat ../SCALS/Renderers/SwiftUI/SwiftUINodeRendering.swift
```

### Verifying Generated Code

After generation:

1. **Read the generated file**
2. **Compare with similar existing component**
3. **Run consistency checker**
4. **Compile and test**

---

## Tips for LLMs

### DO:
- ✅ Run consistency checker at start of session
- ✅ Use generators for boilerplate
- ✅ Validate after each change
- ✅ Read existing code before generating
- ✅ Follow established patterns
- ✅ Generate tests automatically

### DON'T:
- ❌ Assume tool output is always correct
- ❌ Skip validation steps
- ❌ Generate code without understanding patterns
- ❌ Ignore warnings without investigation
- ❌ Create inconsistent naming
- ❌ Skip documentation generation

---

## Troubleshooting

### Tool Won't Build
```bash
cd ScalsTools
swift package clean
swift package resolve
swift build
```

### Tool Shows Errors
1. Check framework path is correct
2. Verify file structure matches expectations
3. Review CONSISTENCY_REPORT.md for known issues

### Generated Code Won't Compile
1. Check Swift version compatibility
2. Verify imports are correct
3. Compare with working examples
4. Run consistency checker

---

## Getting Help

### Report Files
- `CONSISTENCY_REPORT.md` - Latest consistency analysis
- `Package.swift` - Tool configurations
- `README.md` - User documentation

### Debug Mode
Add `--verbose` flag to any command for detailed output

---

## Next Steps

After reading this guide:

1. Run consistency checker to understand current state
2. Review CONSISTENCY_REPORT.md
3. Use appropriate tool for your task
4. Validate changes before committing

**Remember**: These tools are helpers, not replacements for understanding the framework architecture.
