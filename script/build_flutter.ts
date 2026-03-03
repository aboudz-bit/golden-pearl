import { execSync } from "child_process";
import fs from "fs";
import path from "path";

async function build() {
  const flutterDir = path.resolve(process.cwd(), "golden_pearl");
  const buildDir = path.resolve(flutterDir, "build", "web");

  console.log("Checking Flutter build...");
  
  if (!fs.existsSync(path.join(buildDir, "index.html"))) {
    console.log("Flutter web build not found. Starting build...");
    try {
      execSync("flutter build web --release", { 
        cwd: flutterDir,
        stdio: "inherit" 
      });
      console.log("Flutter build completed successfully.");
    } catch (error) {
      console.error("Flutter build failed:", error);
      // Create a minimal placeholder to prevent ENOENT if build fails
      if (!fs.existsSync(buildDir)) fs.mkdirSync(buildDir, { recursive: true });
      fs.writeFileSync(path.join(buildDir, "index.html"), "<html><body><h1>Build Failed</h1></body></html>");
    }
  } else {
    console.log("Flutter web build already exists.");
  }
}

build();
