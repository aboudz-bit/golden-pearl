import type { Express, Request, Response, NextFunction } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { insertCartItemSchema, insertOrderSchema, insertProductSchema, insertDiscountCodeSchema, insertBannerSchema } from "@shared/schema";
import { z } from "zod";
import { payments } from "./payments";
import { shipping } from "./shipping";
import bcrypt from "bcrypt";
import multer from "multer";
import sharp from "sharp";
import path from "path";
import fs from "fs";
import { randomUUID } from "crypto";

declare module "express-session" {
  interface SessionData {
    userId?: number;
  }
}

const uploadsDir = path.resolve(process.cwd(), "uploads");
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith("image/") || file.mimetype.startsWith("video/")) {
      cb(null, true);
    } else {
      cb(new Error("Only image and video files are allowed"));
    }
  },
});

async function isAdmin(req: Request, res: Response, next: NextFunction) {
  const userId = req.session?.userId;
  if (!userId) return res.status(401).json({ message: "Authentication required" });
  const user = await storage.getUserById(userId);
  if (!user || user.role !== "admin") return res.status(403).json({ message: "Admin access required" });
  next();
}

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {

  app.post("/api/auth/register", async (req, res) => {
    try {
      const { email, password, name, phone } = req.body;
      if (!email || !password || !name) {
        return res.status(400).json({ message: "Email, password, and name are required" });
      }
      const existing = await storage.getUserByEmail(email);
      if (existing) return res.status(409).json({ message: "Email already registered" });

      const passwordHash = await bcrypt.hash(password, 10);
      const user = await storage.createUser({ email: email.toLowerCase(), passwordHash, name, phone });
      req.session!.userId = user.id;

      const { passwordHash: _, ...safeUser } = user;
      res.json({ user: safeUser });
    } catch (error) {
      res.status(500).json({ message: "Failed to register" });
    }
  });

  app.post("/api/auth/login", async (req, res) => {
    try {
      const { email, password } = req.body;
      if (!email || !password) return res.status(400).json({ message: "Email and password are required" });

      const user = await storage.getUserByEmail(email);
      if (!user) return res.status(401).json({ message: "Invalid email or password" });

      const valid = await bcrypt.compare(password, user.passwordHash);
      if (!valid) return res.status(401).json({ message: "Invalid email or password" });

      req.session!.userId = user.id;
      const { passwordHash: _, ...safeUser } = user;
      res.json({ user: safeUser });
    } catch (error) {
      res.status(500).json({ message: "Failed to login" });
    }
  });

  app.post("/api/auth/logout", async (req, res) => {
    try {
      delete req.session!.userId;
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to logout" });
    }
  });

  app.get("/api/auth/me", async (req, res) => {
    try {
      const userId = req.session?.userId;
      if (!userId) return res.json({ user: null });
      const user = await storage.getUserById(userId);
      if (!user) return res.json({ user: null });
      const { passwordHash: _, ...safeUser } = user;
      res.json({ user: safeUser });
    } catch (error) {
      res.json({ user: null });
    }
  });

  app.post("/api/auth/merge", async (req, res) => {
    try {
      const userId = req.session?.userId;
      if (!userId) return res.status(401).json({ message: "Must be logged in to merge" });
      const sessionId = req.session!.id;
      await storage.migrateCartToUser(sessionId, userId);
      const items = await storage.getCartItemsByUserId(userId);
      res.json({ success: true, cartItems: items });
    } catch (error) {
      res.status(500).json({ message: "Failed to merge cart" });
    }
  });

  app.post("/api/admin/upload", isAdmin, upload.single("file"), async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ message: "No file uploaded" });

      const isImage = req.file.mimetype.startsWith("image/");
      const ext = isImage ? ".jpg" : path.extname(req.file.originalname) || ".mp4";
      const filename = `${randomUUID()}${ext}`;
      const filepath = path.join(uploadsDir, filename);

      if (isImage) {
        await sharp(req.file.buffer)
          .resize(1200, undefined, { withoutEnlargement: true })
          .jpeg({ quality: 80 })
          .toFile(filepath);
      } else {
        fs.writeFileSync(filepath, req.file.buffer);
      }

      const url = `/uploads/${filename}`;
      res.json({ url, type: isImage ? "image" : "video" });
    } catch (error) {
      console.error("Upload error:", error);
      res.status(500).json({ message: "Failed to upload file" });
    }
  });

  app.delete("/api/admin/upload", isAdmin, async (req, res) => {
    try {
      const { url } = req.body;
      if (!url || !url.startsWith("/uploads/")) return res.status(400).json({ message: "Invalid URL" });
      const filepath = path.join(uploadsDir, path.basename(url));
      if (fs.existsSync(filepath)) fs.unlinkSync(filepath);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete file" });
    }
  });

  app.get("/api/products", async (req, res) => {
    try {
      const { category, search, featured } = req.query;
      if (search && typeof search === "string") {
        let products = await storage.searchProducts(search);
        if (category && typeof category === "string") {
          products = products.filter(p => p.category === category);
        }
        return res.json(products);
      }
      if (featured === "true") {
        const products = await storage.getFeaturedProducts();
        return res.json(products);
      }
      if (category && typeof category === "string") {
        const products = await storage.getProductsByCategory(category);
        return res.json(products);
      }
      const products = await storage.getProducts();
      res.json(products);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch products" });
    }
  });

  app.get("/api/products/:id", async (req, res) => {
    try {
      const product = await storage.getProduct(parseInt(req.params.id));
      if (!product) return res.status(404).json({ message: "Product not found" });
      res.json(product);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch product" });
    }
  });

  app.get("/api/cart", async (req, res) => {
    try {
      const userId = req.session?.userId;
      if (userId) {
        const items = await storage.getCartItemsByUserId(userId);
        return res.json(items);
      }
      const sessionId = req.session?.id || "anonymous";
      const items = await storage.getCartItems(sessionId);
      res.json(items);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch cart" });
    }
  });

  app.post("/api/cart", async (req, res) => {
    try {
      const sessionId = req.session?.id || "anonymous";
      const userId = req.session?.userId;

      const product = await storage.getProduct(req.body.productId);
      if (product && product.stock <= 0) {
        return res.status(400).json({ message: "Product is out of stock" });
      }

      const itemData: any = { ...req.body, sessionId };
      if (userId) itemData.userId = userId;

      const result = insertCartItemSchema.safeParse(itemData);
      if (!result.success) return res.status(400).json({ message: "Invalid cart item", errors: result.error.flatten() });
      const item = await storage.addCartItem(result.data);
      res.json(item);
    } catch (error) {
      res.status(500).json({ message: "Failed to add to cart" });
    }
  });

  app.patch("/api/cart/:id", async (req, res) => {
    try {
      const { quantity } = req.body;
      if (typeof quantity !== "number" || quantity < 1) {
        return res.status(400).json({ message: "Invalid quantity" });
      }
      const item = await storage.updateCartItem(parseInt(req.params.id), quantity);
      if (!item) return res.status(404).json({ message: "Cart item not found" });
      res.json(item);
    } catch (error) {
      res.status(500).json({ message: "Failed to update cart item" });
    }
  });

  app.delete("/api/cart/:id", async (req, res) => {
    try {
      await storage.removeCartItem(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to remove cart item" });
    }
  });

  app.delete("/api/cart", async (req, res) => {
    try {
      const sessionId = req.session?.id || "anonymous";
      await storage.clearCart(sessionId);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to clear cart" });
    }
  });

  app.post("/api/orders", async (req, res) => {
    try {
      const sessionId = req.session?.id || "anonymous";
      const userId = req.session?.userId;

      const orderData: any = { ...req.body, sessionId };
      if (userId) orderData.userId = userId;

      const result = insertOrderSchema.safeParse(orderData);
      if (!result.success) return res.status(400).json({ message: "Invalid order", errors: result.error.flatten() });

      const items = req.body.items as any[];
      if (items && Array.isArray(items)) {
        for (const item of items) {
          if (item.productId) {
            const product = await storage.getProduct(item.productId);
            if (product && product.stock < (item.quantity || 1)) {
              return res.status(400).json({ message: `Insufficient stock for ${product.nameEn}` });
            }
          }
        }
      }

      const order = await storage.createOrder(result.data);
      res.json(order);

      try {
        if (items && Array.isArray(items)) {
          for (const item of items) {
            if (item.productId) {
              const product = await storage.getProduct(item.productId);
              if (product) {
                await storage.updateProductStock(item.productId, Math.max(0, product.stock - (item.quantity || 1)));
              }
            }
          }
        }

        if (userId) {
          await storage.clearCart(`user_${userId}`);
        }
        await storage.clearCart(sessionId);

        if (order.discountCode) {
          const discount = await storage.getDiscountCode(order.discountCode);
          if (discount) {
            await storage.incrementDiscountUsage(discount.id);
          }
        }
      } catch (postOrderError) {
        console.error("Post-order cleanup error:", postOrderError);
      }
    } catch (error) {
      res.status(500).json({ message: "Failed to create order" });
    }
  });

  app.get("/api/orders", async (req, res) => {
    try {
      const userId = req.session?.userId;
      if (userId) {
        const ordersList = await storage.getOrdersByUserId(userId);
        return res.json(ordersList);
      }
      const sessionId = req.session?.id || "anonymous";
      const ordersList = await storage.getOrders(sessionId);
      res.json(ordersList);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch orders" });
    }
  });

  app.get("/api/orders/:id", async (req, res) => {
    try {
      const order = await storage.getOrder(parseInt(req.params.id));
      if (!order) return res.status(404).json({ message: "Order not found" });
      res.json(order);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch order" });
    }
  });

  app.post("/api/discounts/validate", async (req, res) => {
    try {
      const { code } = req.body;
      if (!code) return res.status(400).json({ message: "Code is required" });
      const discount = await storage.getDiscountCode(code);
      if (!discount || !discount.active) return res.status(404).json({ message: "Invalid discount code" });
      if (discount.maxUses && discount.usedCount >= discount.maxUses) {
        return res.status(400).json({ message: "Discount code has been fully redeemed" });
      }
      if (discount.expiresAt && new Date(discount.expiresAt) < new Date()) {
        return res.status(400).json({ message: "Discount code has expired" });
      }
      res.json({ type: discount.type, value: discount.value, minOrder: discount.minOrder });
    } catch (error) {
      res.status(500).json({ message: "Failed to validate discount code" });
    }
  });

  app.get("/api/notifications", async (req, res) => {
    try {
      const userId = req.session?.userId;
      if (userId) {
        const notifs = await storage.getNotifications(String(userId));
        return res.json(notifs);
      }
      const sessionId = req.session?.id || "anonymous";
      const notifs = await storage.getNotifications(sessionId);
      res.json(notifs);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch notifications" });
    }
  });

  app.get("/api/notifications/unread-count", async (req, res) => {
    try {
      const userId = req.session?.userId;
      if (userId) {
        const count = await storage.getUnreadNotificationCount(String(userId));
        return res.json({ count });
      }
      const sessionId = req.session?.id || "anonymous";
      const count = await storage.getUnreadNotificationCount(sessionId);
      res.json({ count });
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch unread count" });
    }
  });

  app.patch("/api/notifications/:id/read", async (req, res) => {
    try {
      const notif = await storage.markNotificationRead(parseInt(req.params.id));
      if (!notif) return res.status(404).json({ message: "Notification not found" });
      res.json(notif);
    } catch (error) {
      res.status(500).json({ message: "Failed to mark notification as read" });
    }
  });

  app.get("/api/settings/:key", async (req, res) => {
    try {
      const value = await storage.getSetting(req.params.key);
      res.json({ key: req.params.key, value: value || null });
    } catch (error) {
      res.status(500).json({ message: "Failed to get setting" });
    }
  });

  app.post("/api/analytics/pageview", async (req, res) => {
    try {
      const { sessionId, page, productId } = req.body;
      if (!sessionId || !page) return res.status(400).json({ message: "sessionId and page are required" });
      await storage.createPageView({ sessionId, page, productId: productId || null });
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to record pageview" });
    }
  });

  app.get("/api/banners", async (_req, res) => {
    try {
      const activeBanners = await storage.getActiveBanners();
      res.json(activeBanners);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch banners" });
    }
  });

  app.get("/api/categories", async (_req, res) => {
    try {
      const cats = await storage.getVisibleCategories();
      res.json(cats);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch categories" });
    }
  });

  app.post("/api/admin/products", isAdmin, async (req, res) => {
    try {
      const result = insertProductSchema.safeParse(req.body);
      if (!result.success) return res.status(400).json({ message: "Invalid product", errors: result.error.flatten() });
      const product = await storage.createProduct(result.data);
      res.json(product);
    } catch (error) {
      res.status(500).json({ message: "Failed to create product" });
    }
  });

  app.patch("/api/admin/products/:id", isAdmin, async (req, res) => {
    try {
      const product = await storage.updateProduct(parseInt(req.params.id), req.body);
      if (!product) return res.status(404).json({ message: "Product not found" });
      res.json(product);
    } catch (error) {
      res.status(500).json({ message: "Failed to update product" });
    }
  });

  app.delete("/api/admin/products/:id", isAdmin, async (req, res) => {
    try {
      await storage.deleteProduct(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete product" });
    }
  });

  app.patch("/api/admin/products/:id/stock", isAdmin, async (req, res) => {
    try {
      const { stock } = req.body;
      if (typeof stock !== "number" || stock < 0) return res.status(400).json({ message: "Invalid stock value" });
      const product = await storage.updateProductStock(parseInt(req.params.id), stock);
      if (!product) return res.status(404).json({ message: "Product not found" });
      res.json(product);
    } catch (error) {
      res.status(500).json({ message: "Failed to update stock" });
    }
  });

  app.patch("/api/admin/products/reorder", isAdmin, async (req, res) => {
    try {
      const { items } = req.body;
      if (!Array.isArray(items)) return res.status(400).json({ message: "items array required" });
      await storage.reorderProducts(items);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to reorder products" });
    }
  });

  app.get("/api/admin/orders", isAdmin, async (_req, res) => {
    try {
      const allOrders = await storage.getAllOrders();
      res.json(allOrders);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch orders" });
    }
  });

  app.patch("/api/admin/orders/:id/status", isAdmin, async (req, res) => {
    try {
      const { status, trackingNumber } = req.body;
      if (!status) return res.status(400).json({ message: "Status is required" });
      const order = await storage.updateOrderStatus(parseInt(req.params.id), status, trackingNumber);
      if (!order) return res.status(404).json({ message: "Order not found" });

      res.json(order);

      try {
        const notifUserId = order.userId ? String(order.userId) : order.sessionId;
        if (status === "ready_for_pickup" && order.deliveryMethod === "pickup") {
          await storage.createNotification({
            userId: notifUserId,
            orderId: order.id,
            title: "طلبك جاهز للاستلام",
            message: `الطلب رقم #${order.id} جاهز للاستلام من المتجر`,
            read: false,
          });
        } else if (status === "shipped") {
          await storage.createNotification({
            userId: notifUserId,
            orderId: order.id,
            title: "تم شحن طلبك",
            message: `الطلب رقم #${order.id} في الطريق إليك${trackingNumber ? ` - رقم التتبع: ${trackingNumber}` : ''}`,
            read: false,
          });
        } else if (status === "delivered") {
          await storage.createNotification({
            userId: notifUserId,
            orderId: order.id,
            title: "تم توصيل طلبك",
            message: `الطلب رقم #${order.id} تم توصيله بنجاح`,
            read: false,
          });
        }
      } catch (notifError) {
        console.error("Notification creation error:", notifError);
      }
    } catch (error) {
      res.status(500).json({ message: "Failed to update order status" });
    }
  });

  app.get("/api/admin/settings", isAdmin, async (_req, res) => {
    try {
      const settings = await storage.getAllSettings();
      res.json(settings);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch settings" });
    }
  });

  app.put("/api/admin/settings/:key", isAdmin, async (req, res) => {
    try {
      const { value } = req.body;
      if (value === undefined) return res.status(400).json({ message: "Value is required" });
      const setting = await storage.setSetting(req.params.key, value);
      res.json(setting);
    } catch (error) {
      res.status(500).json({ message: "Failed to update setting" });
    }
  });

  app.get("/api/admin/analytics", isAdmin, async (_req, res) => {
    try {
      const analytics = await storage.getAnalytics();
      res.json(analytics);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch analytics" });
    }
  });

  app.get("/api/admin/banners", isAdmin, async (_req, res) => {
    try {
      const allBanners = await storage.getBanners();
      res.json(allBanners);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch banners" });
    }
  });

  app.post("/api/admin/banners", isAdmin, async (req, res) => {
    try {
      const result = insertBannerSchema.safeParse(req.body);
      if (!result.success) return res.status(400).json({ message: "Invalid banner", errors: result.error.flatten() });
      const banner = await storage.createBanner(result.data);
      res.json(banner);
    } catch (error) {
      res.status(500).json({ message: "Failed to create banner" });
    }
  });

  app.patch("/api/admin/banners/:id", isAdmin, async (req, res) => {
    try {
      const banner = await storage.updateBanner(parseInt(req.params.id), req.body);
      if (!banner) return res.status(404).json({ message: "Banner not found" });
      res.json(banner);
    } catch (error) {
      res.status(500).json({ message: "Failed to update banner" });
    }
  });

  app.delete("/api/admin/banners/:id", isAdmin, async (req, res) => {
    try {
      await storage.deleteBanner(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete banner" });
    }
  });

  app.patch("/api/admin/banners/reorder", isAdmin, async (req, res) => {
    try {
      const { items } = req.body;
      if (!Array.isArray(items)) return res.status(400).json({ message: "items array required" });
      await storage.reorderBanners(items);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to reorder banners" });
    }
  });

  app.get("/api/admin/categories", isAdmin, async (_req, res) => {
    try {
      const cats = await storage.getCategories();
      res.json(cats);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch categories" });
    }
  });

  app.patch("/api/admin/categories/:id", isAdmin, async (req, res) => {
    try {
      const cat = await storage.updateCategory(parseInt(req.params.id), req.body);
      if (!cat) return res.status(404).json({ message: "Category not found" });
      res.json(cat);
    } catch (error) {
      res.status(500).json({ message: "Failed to update category" });
    }
  });

  app.patch("/api/admin/categories/reorder", isAdmin, async (req, res) => {
    try {
      const { items } = req.body;
      if (!Array.isArray(items)) return res.status(400).json({ message: "items array required" });
      await storage.reorderCategories(items);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to reorder categories" });
    }
  });

  app.post("/api/admin/discounts", isAdmin, async (req, res) => {
    try {
      const result = insertDiscountCodeSchema.safeParse(req.body);
      if (!result.success) return res.status(400).json({ message: "Invalid discount", errors: result.error.flatten() });
      const discount = await storage.createDiscountCode(result.data);
      res.json(discount);
    } catch (error) {
      res.status(500).json({ message: "Failed to create discount" });
    }
  });

  app.get("/api/admin/discounts", isAdmin, async (_req, res) => {
    try {
      const discounts = await storage.getAllDiscountCodes();
      res.json(discounts);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch discounts" });
    }
  });

  app.patch("/api/admin/discounts/:id", isAdmin, async (req, res) => {
    try {
      const discount = await storage.updateDiscountCode(parseInt(req.params.id), req.body);
      if (!discount) return res.status(404).json({ message: "Discount not found" });
      res.json(discount);
    } catch (error) {
      res.status(500).json({ message: "Failed to update discount" });
    }
  });

  app.delete("/api/admin/discounts/:id", isAdmin, async (req, res) => {
    try {
      await storage.deleteDiscountCode(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete discount" });
    }
  });

  app.post("/api/admin/notifications/send", isAdmin, async (req, res) => {
    try {
      const { title, message, productId } = req.body;
      if (!title || !message) return res.status(400).json({ message: "Title and message are required" });
      await storage.sendNotificationToAll(title, message, productId);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to send notification" });
    }
  });

  app.post("/api/payments/create", async (req, res) => {
    try {
      const { orderId, amount, method } = req.body;
      if (!orderId || !amount) {
        return res.status(400).json({ message: "orderId and amount are required" });
      }
      res.json({
        id: `pay_stub_${Date.now()}`,
        status: "initiated",
        amount,
        currency: "SAR",
        method: method || "applepay",
        orderId,
        message: "Moyasar integration pending — API key required",
      });
    } catch (error) {
      res.status(500).json({ message: "Failed to create payment" });
    }
  });

  app.post("/api/webhooks/moyasar", async (req, res) => {
    try {
      console.log("Moyasar webhook received (stub):", JSON.stringify(req.body).substring(0, 200));
      res.json({ received: true });
    } catch (error) {
      res.status(500).json({ message: "Webhook processing failed" });
    }
  });

  app.post("/api/payments/session", async (req, res) => {
    try {
      const { orderId, amount, method } = req.body;
      if (!orderId || !amount || !method) {
        return res.status(400).json({ message: "orderId, amount, and method are required" });
      }
      const session = await payments.createPaymentSession({ orderId, amount, method, currency: "SAR" });
      res.json(session);
    } catch (error) {
      res.status(500).json({ message: "Failed to create payment session" });
    }
  });

  app.post("/api/payments/:sessionId/confirm", async (req, res) => {
    try {
      const session = await payments.confirmPayment(req.params.sessionId);
      res.json(session);
    } catch (error: any) {
      res.status(400).json({ message: error.message || "Failed to confirm payment" });
    }
  });

  app.post("/api/payments/:sessionId/refund", async (req, res) => {
    try {
      const { amount, reason } = req.body;
      const session = await payments.refundPayment({ sessionId: req.params.sessionId, amount, reason });
      res.json(session);
    } catch (error: any) {
      res.status(400).json({ message: error.message || "Failed to refund payment" });
    }
  });

  app.post("/api/shipping/quote", async (req, res) => {
    try {
      const { destinationCity, destinationCountry, itemCount, subtotal } = req.body;
      if (!destinationCity || !destinationCountry) {
        return res.status(400).json({ message: "destinationCity and destinationCountry are required" });
      }
      const quotes = await shipping.quoteShipping({
        destinationCity,
        destinationCountry,
        itemCount: itemCount ?? 1,
        subtotal: subtotal ?? 0,
      });
      res.json(quotes);
    } catch (error) {
      res.status(500).json({ message: "Failed to get shipping quotes" });
    }
  });

  app.post("/api/shipping/create", async (req, res) => {
    try {
      const shipment = await shipping.createShipment(req.body);
      res.json(shipment);
    } catch (error) {
      res.status(500).json({ message: "Failed to create shipment" });
    }
  });

  app.get("/api/shipping/track/:trackingNumber", async (req, res) => {
    try {
      const shipment = await shipping.trackShipment(req.params.trackingNumber);
      res.json(shipment);
    } catch (error: any) {
      res.status(404).json({ message: error.message || "Shipment not found" });
    }
  });

  return httpServer;
}
