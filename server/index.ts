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

// Use standard Replit port or fallback
const PORT = process.env.PORT || "8080";

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
  console.log(`${new Date().toLocaleTimeString()} [${source}] ${message}`);
}

(async () => {
  // Seed database first
  try {
    await seedDatabase();
  } catch (err) {
    log(`Database seeding error: ${err}`);
  }

  // Register API routes
  await registerRoutes(httpServer, app);

  const flutterBuildPath = path.resolve(process.cwd(), "golden_pearl", "build", "web");
  const indexPath = path.resolve(flutterBuildPath, "index.html");

  // Middleware for static files
  app.use(express.static(flutterBuildPath));
  
  // Catch-all route to serve Flutter app or placeholder
  app.get("*", (req, res, next) => {
    // Skip API routes
    if (req.path.startsWith("/api")) return next();
    
    if (fs.existsSync(indexPath)) {
      res.sendFile(indexPath);
    } else {
      // Create directory if missing to avoid future ENOENT
      if (!fs.existsSync(flutterBuildPath)) {
        fs.mkdirSync(flutterBuildPath, { recursive: true });
      }
      res.status(200).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Golden Pearl - Building</title>
          <style>
            body { font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f4f4f4; }
            .content { text-align: center; color: #1c1c1c; }
          </style>
        </head>
        <body>
          <div class="content">
            <h1 style="color: #B89B5E;">Golden Pearl</h1>
            <p>The application is being prepared for your luxury experience.</p>
            <p>This page will refresh every 10 seconds until the build is ready.</p>
            <script>setTimeout(() => location.reload(), 10000);</script>
          </div>
        </body>
        </html>
      `);
    }
  });

  // Error handling
  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Internal Server Error";
    res.status(status).json({ message });
  });

  httpServer.listen({ port: Number(PORT), host: "0.0.0.0" }, () => {
    log(`Server listening on 0.0.0.0:${PORT}`);
  });
})();
