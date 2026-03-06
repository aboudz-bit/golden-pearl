import type { Express } from "express";
import { type Server } from "http";
import { z } from "zod";
import crypto from "crypto";
import * as storage from "./storage";
import {
  insertCompanySchema, insertProductSchema, insertExperienceSchema,
  insertProductAssetSchema, insertAnalyticsEventSchema,
} from "@shared/schema";

// Simple password hash for demo (production: use bcrypt/argon2)
function hashPassword(pw: string): string {
  return crypto.createHash("sha256").update(pw).digest("hex");
}

// Auth middleware
function requireAuth(req: any, res: any, next: any) {
  if (!req.session?.userId) {
    return res.status(401).json({ message: "Authentication required" });
  }
  next();
}

function requireRole(...roles: string[]) {
  return (req: any, res: any, next: any) => {
    if (!req.session?.userId) {
      return res.status(401).json({ message: "Authentication required" });
    }
    if (!roles.includes(req.session.userRole)) {
      return res.status(403).json({ message: "Insufficient permissions" });
    }
    next();
  };
}

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {

  // ========== AUTH ==========
  app.post("/api/auth/login", async (req, res) => {
    try {
      const { email, password } = req.body;
      if (!email || !password) return res.status(400).json({ message: "Email and password required" });

      const user = await storage.getUserByEmail(email);
      if (!user) return res.status(401).json({ message: "Invalid credentials" });

      const hash = hashPassword(password);
      if (user.passwordHash !== hash) return res.status(401).json({ message: "Invalid credentials" });

      if (!user.isActive) return res.status(403).json({ message: "Account disabled" });

      // Get company memberships
      const membershipsList = await storage.getMembershipsByUser(user.id);
      const activeCompanyId = membershipsList.length > 0 ? membershipsList[0].company.id : null;

      (req.session as any).userId = user.id;
      (req.session as any).userRole = user.role;
      (req.session as any).companyId = activeCompanyId;

      await storage.updateUser(user.id, { lastLoginAt: new Date() } as any);
      await storage.createAuditLog({
        userId: user.id,
        companyId: activeCompanyId,
        action: "login",
        entityType: "user",
        entityId: user.id,
        ipAddress: req.ip || req.socket.remoteAddress,
      });

      const { passwordHash, ...safeUser } = user;
      res.json({
        user: safeUser,
        companyId: activeCompanyId,
        memberships: membershipsList.map(m => ({
          companyId: m.company.id,
          companyName: m.company.name,
          companySlug: m.company.slug,
          role: m.membership.role,
        })),
      });
    } catch (error) {
      console.error("Login error:", error);
      res.status(500).json({ message: "Login failed" });
    }
  });

  app.post("/api/auth/logout", (req, res) => {
    req.session.destroy(() => {
      res.json({ success: true });
    });
  });

  app.get("/api/auth/me", async (req, res) => {
    const userId = (req.session as any)?.userId;
    if (!userId) return res.status(401).json({ message: "Not authenticated" });

    const user = await storage.getUserById(userId);
    if (!user) return res.status(401).json({ message: "User not found" });

    const membershipsList = await storage.getMembershipsByUser(user.id);
    const { passwordHash, ...safeUser } = user;
    res.json({
      user: safeUser,
      companyId: (req.session as any).companyId,
      memberships: membershipsList.map(m => ({
        companyId: m.company.id,
        companyName: m.company.name,
        companySlug: m.company.slug,
        role: m.membership.role,
      })),
    });
  });

  app.post("/api/auth/switch-company", requireAuth, async (req, res) => {
    const { companyId } = req.body;
    (req.session as any).companyId = companyId;
    res.json({ success: true, companyId });
  });

  // ========== DASHBOARD STATS ==========
  app.get("/api/dashboard/stats", requireAuth, async (req, res) => {
    try {
      const companyId = (req.session as any).userRole === "super_admin"
        ? undefined
        : (req.session as any).companyId;
      const stats = await storage.getDashboardStats(companyId);
      res.json(stats);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch stats" });
    }
  });

  // ========== COMPANIES ==========
  app.get("/api/companies", requireAuth, async (_req, res) => {
    try {
      const list = await storage.getCompanies();
      res.json(list);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch companies" });
    }
  });

  app.get("/api/companies/:id", requireAuth, async (req, res) => {
    try {
      const company = await storage.getCompanyById(parseInt(req.params.id));
      if (!company) return res.status(404).json({ message: "Company not found" });
      res.json(company);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch company" });
    }
  });

  app.post("/api/companies", requireRole("super_admin"), async (req, res) => {
    try {
      const result = insertCompanySchema.safeParse(req.body);
      if (!result.success) return res.status(400).json({ message: "Invalid data", errors: result.error.flatten() });
      const company = await storage.createCompany(result.data);
      await storage.createAuditLog({
        userId: (req.session as any).userId,
        companyId: company.id,
        action: "create",
        entityType: "company",
        entityId: company.id,
      });
      res.json(company);
    } catch (error) {
      res.status(500).json({ message: "Failed to create company" });
    }
  });

  app.patch("/api/companies/:id", requireAuth, async (req, res) => {
    try {
      const company = await storage.updateCompany(parseInt(req.params.id), req.body);
      if (!company) return res.status(404).json({ message: "Company not found" });
      res.json(company);
    } catch (error) {
      res.status(500).json({ message: "Failed to update company" });
    }
  });

  app.delete("/api/companies/:id", requireRole("super_admin"), async (req, res) => {
    try {
      await storage.deleteCompany(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete company" });
    }
  });

  // ========== USERS ==========
  app.get("/api/users", requireAuth, async (req, res) => {
    try {
      const companyId = (req.session as any).userRole === "super_admin"
        ? undefined
        : (req.session as any).companyId;
      const list = await storage.getUsers(companyId);
      // Strip password hashes
      res.json(list.map((u: any) => { const { passwordHash, ...safe } = u; return safe; }));
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch users" });
    }
  });

  app.post("/api/users", requireRole("super_admin", "company_admin"), async (req, res) => {
    try {
      const { email, password, firstName, lastName, role, companyId } = req.body;
      if (!email || !password || !firstName || !lastName) {
        return res.status(400).json({ message: "Missing required fields" });
      }
      const existing = await storage.getUserByEmail(email);
      if (existing) return res.status(409).json({ message: "Email already in use" });

      const user = await storage.createUser({
        email,
        passwordHash: hashPassword(password),
        firstName,
        lastName,
        role: role || "viewer",
      });

      const targetCompany = companyId || (req.session as any).companyId;
      if (targetCompany) {
        await storage.createMembership({
          userId: user.id,
          companyId: targetCompany,
          role: role === "super_admin" ? "company_admin" : (role || "viewer"),
        });
      }

      const { passwordHash, ...safeUser } = user;
      res.json(safeUser);
    } catch (error) {
      res.status(500).json({ message: "Failed to create user" });
    }
  });

  // ========== PRODUCTS ==========
  app.get("/api/products", requireAuth, async (req, res) => {
    try {
      const companyId = (req.session as any).userRole === "super_admin"
        ? (req.query.companyId ? parseInt(req.query.companyId as string) : undefined)
        : (req.session as any).companyId;
      const list = await storage.getProducts(companyId);
      res.json(list);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch products" });
    }
  });

  app.get("/api/products/:id", requireAuth, async (req, res) => {
    try {
      const product = await storage.getProductById(parseInt(req.params.id));
      if (!product) return res.status(404).json({ message: "Product not found" });

      const assets = await storage.getAssetsByProduct(product.id);
      res.json({ ...product, assets });
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch product" });
    }
  });

  app.post("/api/products", requireAuth, async (req, res) => {
    try {
      const companyId = req.body.companyId || (req.session as any).companyId;
      if (!companyId) return res.status(400).json({ message: "Company context required" });

      const slug = req.body.slug || req.body.title?.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
      const data = { ...req.body, companyId, slug };

      const product = await storage.createProduct(data);
      await storage.createAuditLog({
        userId: (req.session as any).userId,
        companyId,
        action: "create",
        entityType: "product",
        entityId: product.id,
      });
      res.json(product);
    } catch (error) {
      console.error("Create product error:", error);
      res.status(500).json({ message: "Failed to create product" });
    }
  });

  app.patch("/api/products/:id", requireAuth, async (req, res) => {
    try {
      const product = await storage.updateProduct(parseInt(req.params.id), req.body);
      if (!product) return res.status(404).json({ message: "Product not found" });
      res.json(product);
    } catch (error) {
      res.status(500).json({ message: "Failed to update product" });
    }
  });

  app.delete("/api/products/:id", requireAuth, async (req, res) => {
    try {
      await storage.deleteProduct(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete product" });
    }
  });

  // ========== ASSETS ==========
  app.get("/api/products/:productId/assets", requireAuth, async (req, res) => {
    try {
      const assets = await storage.getAssetsByProduct(parseInt(req.params.productId));
      res.json(assets);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch assets" });
    }
  });

  app.get("/api/assets", requireAuth, async (req, res) => {
    try {
      const companyId = (req.session as any).userRole === "super_admin"
        ? (req.query.companyId ? parseInt(req.query.companyId as string) : undefined)
        : (req.session as any).companyId;
      if (!companyId) return res.json([]);
      const assets = await storage.getAssetsByCompany(companyId);
      res.json(assets);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch assets" });
    }
  });

  app.post("/api/assets", requireAuth, async (req, res) => {
    try {
      const companyId = req.body.companyId || (req.session as any).companyId;
      const asset = await storage.createAsset({ ...req.body, companyId });
      res.json(asset);
    } catch (error) {
      res.status(500).json({ message: "Failed to create asset" });
    }
  });

  app.delete("/api/assets/:id", requireAuth, async (req, res) => {
    try {
      await storage.deleteAsset(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete asset" });
    }
  });

  // ========== EXPERIENCES ==========
  app.get("/api/experiences", requireAuth, async (req, res) => {
    try {
      const companyId = (req.session as any).userRole === "super_admin"
        ? (req.query.companyId ? parseInt(req.query.companyId as string) : undefined)
        : (req.session as any).companyId;
      const list = await storage.getExperiences(companyId);
      res.json(list);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch experiences" });
    }
  });

  app.get("/api/experiences/:id", requireAuth, async (req, res) => {
    try {
      const exp = await storage.getExperienceById(parseInt(req.params.id));
      if (!exp) return res.status(404).json({ message: "Experience not found" });

      // Get linked product and assets
      let product = null;
      let assets: any[] = [];
      if (exp.productId) {
        product = await storage.getProductById(exp.productId);
        if (product) {
          assets = await storage.getAssetsByProduct(product.id);
        }
      }
      res.json({ ...exp, product, assets });
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch experience" });
    }
  });

  app.post("/api/experiences", requireAuth, async (req, res) => {
    try {
      const companyId = req.body.companyId || (req.session as any).companyId;
      if (!companyId) return res.status(400).json({ message: "Company context required" });

      const slug = req.body.slug || `${req.body.name?.toLowerCase().replace(/[^a-z0-9]+/g, "-")}-${Date.now().toString(36)}`;
      const data = { ...req.body, companyId, slug };

      const exp = await storage.createExperience(data);
      await storage.createAuditLog({
        userId: (req.session as any).userId,
        companyId,
        action: "create",
        entityType: "experience",
        entityId: exp.id,
      });
      res.json(exp);
    } catch (error) {
      console.error("Create experience error:", error);
      res.status(500).json({ message: "Failed to create experience" });
    }
  });

  app.patch("/api/experiences/:id", requireAuth, async (req, res) => {
    try {
      const exp = await storage.updateExperience(parseInt(req.params.id), req.body);
      if (!exp) return res.status(404).json({ message: "Experience not found" });
      res.json(exp);
    } catch (error) {
      res.status(500).json({ message: "Failed to update experience" });
    }
  });

  app.delete("/api/experiences/:id", requireAuth, async (req, res) => {
    try {
      await storage.deleteExperience(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete experience" });
    }
  });

  // ========== PUBLISH ==========
  app.post("/api/experiences/:id/publish", requireAuth, async (req, res) => {
    try {
      const expId = parseInt(req.params.id);
      const exp = await storage.getExperienceById(expId);
      if (!exp) return res.status(404).json({ message: "Experience not found" });

      await storage.updateExperience(expId, { status: "published" });

      const baseUrl = `${req.protocol}://${req.get("host")}`;
      const publicUrl = `${baseUrl}/ar/${exp.slug}`;
      const qrTargetUrl = `${baseUrl}/qr/${exp.slug}`;
      const embedSnippet = `<iframe src="${publicUrl}?embed=1" width="100%" height="500" frameborder="0" allow="camera;xr-spatial-tracking"></iframe>`;

      const record = await storage.createPublishRecord({
        experienceId: expId,
        companyId: exp.companyId,
        publishedById: (req.session as any).userId,
        publicUrl,
        embedSnippet,
        qrTargetUrl,
        isLive: true,
      });

      await storage.createAuditLog({
        userId: (req.session as any).userId,
        companyId: exp.companyId,
        action: "publish",
        entityType: "experience",
        entityId: expId,
      });

      res.json({ ...record, experience: { ...exp, status: "published" } });
    } catch (error) {
      res.status(500).json({ message: "Failed to publish experience" });
    }
  });

  app.post("/api/experiences/:id/unpublish", requireAuth, async (req, res) => {
    try {
      const expId = parseInt(req.params.id);
      await storage.updateExperience(expId, { status: "draft" });
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to unpublish" });
    }
  });

  // ========== ANALYTICS ==========
  app.post("/api/analytics/event", async (req, res) => {
    try {
      const event = await storage.createAnalyticsEvent(req.body);
      res.json(event);
    } catch (error) {
      res.status(500).json({ message: "Failed to track event" });
    }
  });

  app.get("/api/analytics/summary", requireAuth, async (req, res) => {
    try {
      const companyId = (req.session as any).userRole === "super_admin"
        ? undefined
        : (req.session as any).companyId;
      const days = parseInt(req.query.days as string) || 30;
      const summary = await storage.getAnalyticsSummary(companyId, days);
      res.json(summary);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch analytics" });
    }
  });

  app.get("/api/analytics/timeline", requireAuth, async (req, res) => {
    try {
      const companyId = (req.session as any).userRole === "super_admin"
        ? undefined
        : (req.session as any).companyId;
      const days = parseInt(req.query.days as string) || 30;
      const timeline = await storage.getAnalyticsTimeline(companyId, days);
      res.json(timeline);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch timeline" });
    }
  });

  // ========== SETTINGS ==========
  app.get("/api/settings", requireAuth, async (req, res) => {
    try {
      const companyId = (req.session as any).companyId;
      const list = await storage.getSettings(companyId);
      res.json(list);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch settings" });
    }
  });

  app.put("/api/settings", requireAuth, async (req, res) => {
    try {
      const { key, value, category } = req.body;
      const companyId = (req.session as any).companyId;
      const setting = await storage.upsertSetting(companyId, key, value, category);
      res.json(setting);
    } catch (error) {
      res.status(500).json({ message: "Failed to save setting" });
    }
  });

  // ========== AUDIT LOGS ==========
  app.get("/api/audit-logs", requireAuth, async (req, res) => {
    try {
      const companyId = (req.session as any).userRole === "super_admin"
        ? undefined
        : (req.session as any).companyId;
      const logs = await storage.getAuditLogs(companyId);
      res.json(logs);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch audit logs" });
    }
  });

  // ========== PUBLIC VIEWER ROUTES (no auth required) ==========
  app.get("/api/public/viewer/:companySlug/:productSlug", async (req, res) => {
    try {
      const company = await storage.getCompanyBySlug(req.params.companySlug);
      if (!company) return res.status(404).json({ message: "Company not found" });

      const product = await storage.getProductBySlug(company.id, req.params.productSlug);
      if (!product) return res.status(404).json({ message: "Product not found" });

      const assets = await storage.getAssetsByProduct(product.id);

      res.json({ company: { name: company.name, slug: company.slug, logo: company.logo, brandPrimaryColor: company.brandPrimaryColor }, product, assets });
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch viewer data" });
    }
  });

  app.get("/api/public/experience/:slug", async (req, res) => {
    try {
      const exp = await storage.getExperienceBySlug(req.params.slug);
      if (!exp) return res.status(404).json({ message: "Experience not found" });

      const company = await storage.getCompanyById(exp.companyId);
      let product = null;
      let assets: any[] = [];
      if (exp.productId) {
        product = await storage.getProductById(exp.productId);
        if (product) {
          assets = await storage.getAssetsByProduct(product.id);
        }
      }

      res.json({
        experience: exp,
        company: company ? { name: company.name, slug: company.slug, logo: company.logo, brandPrimaryColor: company.brandPrimaryColor } : null,
        product,
        assets,
      });
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch experience" });
    }
  });

  return httpServer;
}
