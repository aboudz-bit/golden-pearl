#!/usr/bin/env bash
set -e

echo "=== Building for deployment ==="

if command -v npx &> /dev/null && npx esbuild --version &> /dev/null 2>&1; then
  echo "Building Express server with esbuild..."
  npx esbuild server/index.ts --bundle --platform=node --format=cjs --packages=external --outfile=dist/index.cjs
  echo "Server build complete → dist/index.cjs"
elif [ -f "dist/index.cjs" ]; then
  echo "esbuild not available — using pre-built dist/index.cjs"
else
  echo "ERROR: esbuild not available and no pre-built dist/index.cjs found!"
  exit 1
fi

FLUTTER_BUILD="golden_pearl/build/web"

if command -v flutter &> /dev/null; then
  echo "Building Flutter web..."
  cd golden_pearl
  flutter gen-l10n 2>/dev/null || true
  flutter build web --release
  cd ..
  [ -d "golden_pearl/assets/images" ] && cp -r golden_pearl/assets/images "$FLUTTER_BUILD/images"
  [ -d "golden_pearl/assets/videos" ] && cp -r golden_pearl/assets/videos "$FLUTTER_BUILD/videos"
  echo "Flutter build complete"
elif [ -f "$FLUTTER_BUILD/index.html" ]; then
  echo "Flutter not available — using pre-built output"
else
  echo "ERROR: Flutter not available and no pre-built output found!"
  exit 1
fi

echo "=== Build complete ==="
