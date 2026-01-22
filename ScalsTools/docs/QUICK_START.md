# ScalsTools - Quick Start Guide

Get up and running with ScalsTools in 5 minutes

---

## Setup

```bash
cd ScalsTools
swift build
```

---

## Your First Command

```bash
# Check framework consistency
swift run scals-consistency-checker --framework-path ..
```

**Expected output**:
```
============================================================
SCALS Component Consistency Checker
============================================================

ℹ️  Analyzing framework at: /path/to/ScalsRenderer

--- Checking Component Resolvers ---
ℹ️  Found 8 resolver files
⚠️  Found 16 issue(s)
```

**Note**: Current issues are false positives. See `CONSISTENCY_REPORT.md`

---

## Common Tasks

### Check What Components Exist

```bash
ls ../ScalsModules/ComponentResolvers/
```

Output:
- TextComponentResolver.swift
- ButtonComponentResolver.swift
- ImageComponentResolver.swift
- TextFieldComponentResolver.swift
- ToggleComponentResolver.swift
- SliderComponentResolver.swift
- GradientComponentResolver.swift
- DividerComponentResolver.swift

### Verbose Mode

```bash
swift run scals-consistency-checker --framework-path .. --verbose
```

Shows detailed analysis for each component

---

## Available Tools

Currently implemented:

1. **scals-consistency-checker** - Validate framework consistency
2-12. Other tools - Stubs only (coming soon)

List all:
```bash
ls .build/debug/scals-*
```

---

## Next Steps

### For Users
- Read `README.md` for tool descriptions
- Check `docs/LLM_USAGE_GUIDE.md` for integration with AI assistants

### For Developers
- Read `docs/MAINTAINER_GUIDE.md` for development guide
- Check `Package.swift` for tool structure
- Explore `Sources/ScalsToolsCore/` for utilities

---

## Getting Help

```bash
# Show help for any tool
swift run scals-consistency-checker --help
```

Output:
```
USAGE: scals-consistency-checker [--framework-path <framework-path>] [--verbose]

OPTIONS:
  --framework-path <framework-path>
                          Path to the SCALS framework directory (default: ..)
  --verbose               Show verbose output
  -h, --help              Show help information.
```

---

## Troubleshooting

### Build Errors

```bash
swift package clean
swift package resolve
swift build
```

### Tool Not Found

Make sure you're in ScalsTools directory:
```bash
cd ScalsTools
pwd  # Should show: .../ScalsRenderer/ScalsTools
```

---

That's it! You're ready to use ScalsTools. 🎉
