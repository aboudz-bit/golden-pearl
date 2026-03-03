import express from "express";
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

// Use standard Replit port or fallback to 5000
const PORT = process.env.PORT || "5000";

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(session({
  secret: "golden-pearl-secret",
  resave: false,
  saveUninitialized: true,
  store: new SessionStore({ checkPeriod: 86400000 }),
  cookie: { secure: false, maxAge: 7 * 24 * 60 * 60 * 1000 },
}));

(async () => {
  console.log("Starting Golden Pearl Server...");
  try {
    await seedDatabase();
    await registerRoutes(httpServer, app);
    console.log("Server initialized and routes registered");
  } catch (err) {
    console.error("Initialization error:", err);
  }

  const flutterBuildPath = path.resolve(process.cwd(), "golden_pearl", "build", "web");
  const indexPath = path.resolve(flutterBuildPath, "index.html");

  // Ensure directories exist
  if (!fs.existsSync(flutterBuildPath)) {
    fs.mkdirSync(flutterBuildPath, { recursive: true });
  }

  // Create a functional loading page if the build isn't ready
  if (!fs.existsSync(indexPath)) {
    console.log("Flutter build not found, creating placeholder index.html");
    fs.writeFileSync(indexPath, `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Golden Pearl - Initializing</title>
        <style>
          body { background: #F4F4F4; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; font-family: -apple-system, system-ui, sans-serif; color: #1C1C1C; }
          .card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); text-align: center; max-width: 400px; }
          h1 { color: #B89B5E; margin: 0 0 10px; font-weight: 700; }
          p { color: #6B6B6B; line-height: 1.5; margin-bottom: 20px; }
          .spinner { border: 3px solid #EAEAEA; border-top: 3px solid #B89B5E; border-radius: 50%; width: 24px; height: 24px; animation: spin 1s linear infinite; margin: 0 auto; }
          @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>Golden Pearl</h1>
          <p>We are preparing your luxury boutique experience. This page will refresh automatically in a few seconds.</p>
          <div class="spinner"></div>
          <script>setTimeout(() => location.reload(), 8000);</script>
        </div>
      </body>
      </html>
    `);
  }

  // Serve static files from the flutter build directory
  app.use(express.static(flutterBuildPath));
  
  // Handle all other routes by serving index.html (SPA style)
  app.get("*", (req, res, next) => {
    if (req.path.startsWith("/api")) return next();
    res.sendFile(indexPath);
  });

  // Listen on 0.0.0.0 and the assigned port
  httpServer.listen(Number(PORT), "0.0.0.0", () => {
    console.log("Golden Pearl Boutique is live at http://0.0.0.0:" + PORT);
  });
})();
