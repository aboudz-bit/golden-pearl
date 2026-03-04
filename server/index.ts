import express, { type Request, Response, NextFunction } from "express";
import session from "express-session";
import MemoryStore from "memorystore";
import cors from "cors";
import helmet from "helmet";
import compression from "compression";
import rateLimit from "express-rate-limit";
import path from "path";
import fs from "fs";
import { registerRoutes } from "./routes";
import { createServer } from "http";
import { seedDatabase } from "./seed";
import { errorHandler } from "./middleware/errorHandler";

const SessionStore = MemoryStore(session);
const app = express();
const httpServer = createServer(app);

const PORT = process.env.PORT || "5000";
const isProd = process.env.NODE_ENV === "production";

app.set("trust proxy", 1);

app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false,
}));

app.use(compression());

app.use(cors({
  origin: isProd ? (process.env.CORS_ORIGIN || true) : true,
  credentials: true,
}));

app.use(express.json({ limit: "10mb", verify: (req: any, _res, buf) => { req.rawBody = buf; } }));
app.use(express.urlencoded({ extended: false }));

app.use(session({
  secret: process.env.SESSION_SECRET || "golden-pearl-secret",
  resave: false,
  saveUninitialized: true,
  store: new SessionStore({ checkPeriod: 86400000 }),
  cookie: {
    secure: isProd,
    httpOnly: true,
    sameSite: "lax",
    maxAge: 7 * 24 * 60 * 60 * 1000,
  },
}));

const authLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: "Too many attempts, please try again later", code: "RATE_LIMITED" },
});

const uploadLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: "Upload rate limit exceeded", code: "RATE_LIMITED" },
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: "Rate limit exceeded", code: "RATE_LIMITED" },
});

app.use("/api/auth/login", authLimiter);
app.use("/api/auth/register", authLimiter);
app.use("/api/admin/upload", uploadLimiter);
app.use("/api/", apiLimiter);

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

  app.use(errorHandler);

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

  app.get("/uploads/:filename", (req, res, next) => {
    const filepath = path.resolve(process.cwd(), "uploads", req.params.filename);
    if (!fs.existsSync(filepath)) return next();
    const ext = path.extname(filepath).toLowerCase();
    if (ext !== ".mp4") return next();
    const stat = fs.statSync(filepath);
    const fileSize = stat.size;
    const range = req.headers.range;
    if (range) {
      const parts = range.replace(/bytes=/, "").split("-");
      const start = parseInt(parts[0], 10);
      const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
      const chunkSize = end - start + 1;
      const stream = fs.createReadStream(filepath, { start, end });
      res.writeHead(206, {
        "Content-Range": `bytes ${start}-${end}/${fileSize}`,
        "Accept-Ranges": "bytes",
        "Content-Length": chunkSize,
        "Content-Type": "video/mp4",
        "Cache-Control": "public, max-age=604800",
      });
      stream.pipe(res);
    } else {
      res.writeHead(200, {
        "Content-Length": fileSize,
        "Content-Type": "video/mp4",
        "Accept-Ranges": "bytes",
        "Cache-Control": "public, max-age=604800",
      });
      fs.createReadStream(filepath).pipe(res);
    }
  });

  app.use("/uploads", express.static(path.resolve(process.cwd(), "uploads"), { maxAge: "7d" }));
  app.use("/images", express.static(path.resolve(flutterBuildPath, "images"), cacheOptions));
  app.use("/videos", express.static(path.resolve(flutterBuildPath, "videos"), cacheOptions));
  app.use(express.static(flutterBuildPath));

  app.all("/api/{*path}", (_req, res) => {
    res.status(404).json({ success: false, message: "Not found", code: "NOT_FOUND" });
  });

  app.use("/{*path}", (_req, res) => {
    res.sendFile(indexPath);
  });

  httpServer.listen(Number(PORT), "0.0.0.0", () => {
    log(`serving on port ${PORT}`);
  });
})();
