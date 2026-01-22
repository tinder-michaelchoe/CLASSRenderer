# ScalsWasm Deployment Guide

## File Structure

### Build Output
- `ScalsWasm/dist/scals-preview.wasm` - Optimized WASM build

### SchemaEditor Integration
- **`SchemaEditor/public/scals-preview.wasm`** ✅ ACTUAL runtime file
  - Loaded by browser via `/scals-preview.wasm`
  - **This is the ONLY location that matters at runtime**

- **`SchemaEditor/src/lib/scals-preview/`** - TypeScript/JavaScript wrappers
  - Contains: `index.js`, `scals-preview.js`, type definitions
  - WASM file removed from here (not needed, public version is loaded)

## Build & Deploy

### Automatic (Recommended)
```bash
./build-wasm.sh
```
This will:
1. Build Swift to WASM
2. Optimize with wasm-opt
3. Copy to `dist/`
4. **Auto-copy to SchemaEditor/public/** (if directory exists)

### Manual
```bash
# Build
swift build -c release --swift-sdk swift-6.2.3-RELEASE_wasm

# Optimize
wasm-opt -O3 .build/release/ScalsWasm.wasm -o dist/scals-preview.wasm

# Deploy to SchemaEditor
cp dist/scals-preview.wasm ../../SchemaEditor/public/scals-preview.wasm
```

## Testing Changes

After deploying a new WASM file:

1. **Hard refresh** the browser (Cmd+Shift+R on Mac)
2. Or clear browser cache
3. Or use incognito mode

The browser aggressively caches WASM files.

## Registered Components

The WASM build includes these components:
- Text (label)
- Button
- Image
- Toggle
- Slider
- TextField
- Gradient
- Divider
- **Shape** (rectangle, circle, roundedRectangle, capsule, ellipse)

Excluded (not ready):
- PageIndicator (IR infrastructure complete, but excluded pending full testing)

## Troubleshooting

### "No resolver registered for component kind: X"
- The component is not registered in `Sources/ScalsWasm/main.swift`
- Check `Package.swift` to ensure the resolver file is not excluded
- Rebuild and redeploy

### Browser loading old WASM
- Check file timestamp: `ls -lh SchemaEditor/public/scals-preview.wasm`
- Hard refresh browser
- Check browser console for WASM size (should match file size)

### Build fails
- Ensure Swift SDK is installed: `swift sdk list`
- Required SDK: `swift-6.2.3-RELEASE_wasm`
