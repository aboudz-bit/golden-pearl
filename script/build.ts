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

console.log("\n=== Step 2: Flutter web build ===");
const flutterIndexExists = fs.existsSync(path.join(flutterBuildDir, "index.html"));

let flutterAvailable = false;
try {
  execSync("flutter --version", { stdio: "ignore" });
  flutterAvailable = true;
} catch (_) {}

if (flutterAvailable) {
  try {
    execSync("flutter gen-l10n", { cwd: flutterDir, stdio: "inherit" });
  } catch (_) {}
  execSync("flutter build web --release", { cwd: flutterDir, stdio: "inherit" });
  console.log("Flutter build complete → golden_pearl/build/web/");

  console.log("\n=== Step 3: Copy static assets ===");
  for (const dir of ["images", "videos"]) {
    const src = path.resolve(flutterDir, "assets", dir);
    const dest = path.resolve(flutterBuildDir, dir);
    if (fs.existsSync(src)) {
      execSync(`cp -r "${src}" "${dest}"`, { stdio: "inherit" });
      console.log(`Copied assets/${dir} → build/web/${dir}`);
    }
  }
} else if (flutterIndexExists) {
  console.log("Flutter not available but pre-built output found — skipping Flutter build.");
} else {
  console.error("ERROR: Flutter is not available and no pre-built output exists!");
  process.exit(1);
}

console.log("\n=== Build complete ===");
