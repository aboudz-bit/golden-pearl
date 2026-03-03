import express, { type Request, Response, NextFunction } from "express";
import session from "express-session";
import MemoryStore from "memorystore";
import cors from "cors";
import path from "path";
import fs from "fs";
import { registerRoutes } from "./routes";
import { createServer } from "http";
import { seedDatabase } from "./seed";

const SessionStore = MemoryStore(session);
const app = express();
const httpServer = createServer(app);

const PORT = process.env.PORT || "5000";

app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ verify: (req: any, _res, buf) => { req.rawBody = buf; } }));
app.use(express.urlencoded({ extended: false }));
app.use(session({
  secret: process.env.SESSION_SECRET || "golden-pearl-secret",
  resave: false,
  saveUninitialized: true,
  store: new SessionStore({ checkPeriod: 86400000 }),
  cookie: { secure: false, maxAge: 7 * 24 * 60 * 60 * 1000 },
}));

export function log(message: string, source = "express") {
  const formattedTime = new Date().toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    second: "2-digit",
    hour12: true,
  });
  console.log(`${formattedTime} [${source}] ${message}`);
}

app.use((req, res, next) => {
  const start = Date.now();
  const reqPath = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (reqPath.startsWith("/api")) {
      let logLine = `${req.method} ${reqPath} ${res.statusCode} in ${duration}ms`;
      if (capturedJsonResponse) {
        logLine += ` :: ${JSON.stringify(capturedJsonResponse).substring(0, 200)}`;
      }
      log(logLine);
    }
  });

  next();
});

(async () => {
  try {
    await seedDatabase();
  } catch (err) {
    console.error("Seed error:", err);
  }

  await registerRoutes(httpServer, app);

  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Internal Server Error";
    if (!res.headersSent) res.status(status).json({ message });
  });

  const flutterBuildPath = path.resolve(process.cwd(), "golden_pearl", "build", "web");
  const indexPath = path.resolve(flutterBuildPath, "index.html");

  if (!fs.existsSync(flutterBuildPath)) {
    fs.mkdirSync(flutterBuildPath, { recursive: true });
  }

  if (!fs.existsSync(indexPath)) {
    fs.writeFileSync(indexPath, `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Golden Pearl</title>
  <style>
    body { background: #F4F4F4; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; font-family: -apple-system, system-ui, sans-serif; }
    .card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); text-align: center; max-width: 400px; }
    h1 { color: #B89B5E; margin: 0 0 10px; }
    p { color: #6B6B6B; line-height: 1.5; }
    .spinner { border: 3px solid #EAEAEA; border-top: 3px solid #B89B5E; border-radius: 50%; width: 24px; height: 24px; animation: spin 1s linear infinite; margin: 20px auto; }
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="card">
    <h1>Golden Pearl</h1>
    <p>Preparing your luxury experience...</p>
    <div class="spinner"></div>
    <script>setTimeout(() => location.reload(), 8000);</script>
  </div>
</body>
</html>`);
  }

  const cacheOptions = { maxAge: "7d", immutable: true };
  app.use("/uploads", express.static(path.resolve(process.cwd(), "uploads"), { maxAge: "7d" }));
  app.use("/images", express.static(path.resolve(flutterBuildPath, "images"), cacheOptions));
  app.use("/videos", express.static(path.resolve(flutterBuildPath, "videos"), cacheOptions));
  app.use(express.static(flutterBuildPath));

  app.all("/api/{*path}", (_req, res) => {
    res.status(404).json({ message: "Not found" });
  });

  app.use("/{*path}", (_req, res) => {
    res.sendFile(indexPath);
  });

  httpServer.listen(Number(PORT), "0.0.0.0", () => {
    log(`serving on port ${PORT}`);
  });
})();
