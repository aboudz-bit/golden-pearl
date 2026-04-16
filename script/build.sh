#!/usr/bin/env bash
set -euo pipefail

echo "=== Step 1: Build Express server ==="
echo "PATH: $PATH"
echo "Working directory: $(pwd)"

npx esbuild server/index.ts \
  --bundle --platform=node --format=cjs \
  --packages=external --outfile=dist/index.cjs

echo "Server build complete → dist/index.cjs"

echo ""
echo "=== Step 2: Build Flutter web ==="

FLUTTER_BUILD="golden_pearl/build/web"

echo "Checking for flutter..."
which flutter || true
flutter --version || { echo "FATAL: flutter not found in PATH"; exit 1; }

cd golden_pearl

echo "Cleaning stale build artifacts..."
rm -rf .dart_tool build

echo "Running flutter pub get..."
flutter pub get

echo "Running flutter gen-l10n..."
flutter gen-l10n 2>&1 || true

echo "Running flutter build web --release..."
flutter build web --release

cd ..

if [ ! -f "$FLUTTER_BUILD/index.html" ]; then
  echo "FATAL: $FLUTTER_BUILD/index.html not found after build!"
  echo "Contents of golden_pearl/build/:"
  ls -laR golden_pearl/build/ 2>&1 || echo "(directory does not exist)"
  exit 1
fi

echo "Flutter build verified → $FLUTTER_BUILD/index.html exists"

echo ""
echo "=== Step 3: Copy static assets ==="
[ -d "golden_pearl/assets/images" ] && cp -r golden_pearl/assets/images "$FLUTTER_BUILD/images" && echo "Copied images"
[ -d "golden_pearl/assets/videos" ] && cp -r golden_pearl/assets/videos "$FLUTTER_BUILD/videos" && echo "Copied videos"

echo ""
echo "=== Build complete ==="
