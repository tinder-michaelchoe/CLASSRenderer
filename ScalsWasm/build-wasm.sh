#!/bin/bash

set -e

echo "=== Building SCALS WebAssembly Module ==="

# Configuration
SWIFT_SDK="swift-6.2.3-RELEASE_wasm"
WASM_PATH=".build/release/ScalsWasm.wasm"
OUTPUT_DIR="dist"

echo "Using Swift SDK: $SWIFT_SDK"

# Check if SDK is installed
if ! swift sdk list | grep -q "$SWIFT_SDK"; then
    echo "Error: Swift SDK '$SWIFT_SDK' not found"
    echo "Available SDKs:"
    swift sdk list
    exit 1
fi

# Step 1: Build Swift package for WebAssembly
echo ""
echo "Step 1: Building Swift package for WebAssembly..."
swift build -c release --swift-sdk "$SWIFT_SDK"

# Check if WASM file was created
if [ ! -f "$WASM_PATH" ]; then
    echo "Error: WASM file not found at $WASM_PATH"
    exit 1
fi

echo "Found WASM at: $WASM_PATH"

# Get file size
ORIGINAL_SIZE=$(wc -c < "$WASM_PATH")
echo "Original size: $ORIGINAL_SIZE bytes"

# Step 2: Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 3: Optimize with wasm-opt (if available)
if command -v wasm-opt &> /dev/null; then
    echo ""
    echo "Step 2: Optimizing with wasm-opt..."
    wasm-opt -O3 "$WASM_PATH" -o "$OUTPUT_DIR/scals-preview.wasm"

    OPTIMIZED_SIZE=$(wc -c < "$OUTPUT_DIR/scals-preview.wasm")
    REDUCTION=$(( (ORIGINAL_SIZE - OPTIMIZED_SIZE) * 100 / ORIGINAL_SIZE ))
    echo "Optimized size: $OPTIMIZED_SIZE bytes"
    echo "Size reduction: $REDUCTION%"
else
    echo ""
    echo "Step 2: Copying WASM (wasm-opt not available, skipping optimization)..."
    cp "$WASM_PATH" "$OUTPUT_DIR/scals-preview.wasm"
fi

# Step 3: Copy to SchemaEditor if it exists
SCHEMA_EDITOR_PATH="../../SchemaEditor/public/scals-preview.wasm"
if [ -d "../../SchemaEditor/public" ]; then
    echo ""
    echo "Step 3: Copying to SchemaEditor..."
    cp "$OUTPUT_DIR/scals-preview.wasm" "$SCHEMA_EDITOR_PATH"
    echo "Copied to: $SCHEMA_EDITOR_PATH"
fi

echo ""
echo "=== Build Complete ==="
echo "Output: $OUTPUT_DIR/scals-preview.wasm"
if [ -f "$SCHEMA_EDITOR_PATH" ]; then
    echo "Deployed to: $SCHEMA_EDITOR_PATH"
fi
echo ""
echo "Next steps:"
echo "  1. Run 'npm install' to install JS dependencies"
echo "  2. Run 'npm run build:js' to build TypeScript"
echo "  3. Or run 'npm run build' to build everything"
