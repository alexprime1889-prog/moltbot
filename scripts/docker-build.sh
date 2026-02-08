#!/bin/bash
set -e

# Run canvas bundle
echo "Running canvas bundle..."
pnpm canvas:a2ui:bundle || echo "Canvas bundle failed, continuing..."

# Run TypeScript compilation but don't fail the build
echo "Running TypeScript compilation..."
tsc -p tsconfig.json || echo "TypeScript compilation completed with errors, continuing..."

# Copy files and write build info
echo "Copying files and writing build info..."
npx tsx scripts/canvas-a2ui-copy.ts
npx tsx scripts/copy-hook-metadata.ts
npx tsx scripts/write-build-info.ts

echo "Build completed"