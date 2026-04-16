import { execSync } from "child_process";
import fs from "fs";
import path from "path";

const ROOT = process.cwd();
const flutterDir = path.resolve(ROOT, "golden_pearl");
const flutterBuildDir = path.resolve(flutterDir, "build", "web");

console.log("=== Step 1: Build Express server with esbuild ===");
execSync(
  'npx esbuild server/index.ts --bundle --platform=node --format=cjs --packages=external --outfile=dist/index.cjs',
  { cwd: ROOT, stdio: "inherit" }
);
console.log("Server build complete → dist/index.cjs");

console.log("\n=== Step 2: Build Flutter web ===");
execSync("flutter gen-l10n", { cwd: flutterDir, stdio: "inherit" });
execSync("flutter build web --release", { cwd: flutterDir, stdio: "inherit" });
console.log("Flutter build complete → golden_pearl/build/web/");

console.log("\n=== Step 3: Copy static assets ===");
const assetDirs = ["images", "videos"];
for (const dir of assetDirs) {
  const src = path.resolve(flutterDir, "assets", dir);
  const dest = path.resolve(flutterBuildDir, dir);
  if (fs.existsSync(src)) {
    execSync(`cp -r "${src}" "${dest}"`, { stdio: "inherit" });
    console.log(`Copied assets/${dir} → build/web/${dir}`);
  }
}

console.log("\n=== Build complete ===");
