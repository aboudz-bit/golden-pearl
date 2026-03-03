import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { insertCartItemSchema, insertOrderSchema, insertProductSchema, insertDiscountCodeSchema, insertNotificationSchema } from "@shared/schema";
import { z } from "zod";

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {

  app.get("/api/products", async (req, res) => {
    try {
      const { category, search, featured } = req.query;
      if (search && typeof search === "string") {
        const products = await storage.searchProducts(search);
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
      const result = insertCartItemSchema.safeParse({ ...req.body, sessionId });
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
      const result = insertOrderSchema.safeParse({ ...req.body, sessionId });
      if (!result.success) return res.status(400).json({ message: "Invalid order", errors: result.error.flatten() });
      const order = await storage.createOrder(result.data);
      await storage.clearCart(sessionId);
      res.json(order);
    } catch (error) {
      res.status(500).json({ message: "Failed to create order" });
    }
  });

  app.get("/api/orders", async (req, res) => {
    try {
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

  app.post("/api/admin/products", async (req, res) => {
    try {
      const result = insertProductSchema.safeParse(req.body);
      if (!result.success) return res.status(400).json({ message: "Invalid product", errors: result.error.flatten() });
      const product = await storage.createProduct(result.data);
      res.json(product);
    } catch (error) {
      res.status(500).json({ message: "Failed to create product" });
    }
  });

  app.patch("/api/admin/products/:id", async (req, res) => {
    try {
      const product = await storage.updateProduct(parseInt(req.params.id), req.body);
      if (!product) return res.status(404).json({ message: "Product not found" });
      res.json(product);
    } catch (error) {
      res.status(500).json({ message: "Failed to update product" });
    }
  });

  app.delete("/api/admin/products/:id", async (req, res) => {
    try {
      await storage.deleteProduct(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete product" });
    }
  });

  app.get("/api/admin/orders", async (_req, res) => {
    try {
      const allOrders = await storage.getAllOrders();
      res.json(allOrders);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch orders" });
    }
  });

  app.post("/api/admin/discounts", async (req, res) => {
    try {
      const result = insertDiscountCodeSchema.safeParse(req.body);
      if (!result.success) return res.status(400).json({ message: "Invalid discount", errors: result.error.flatten() });
      const discount = await storage.createDiscountCode(result.data);
      res.json(discount);
    } catch (error) {
      res.status(500).json({ message: "Failed to create discount" });
    }
  });

  app.get("/api/admin/discounts", async (_req, res) => {
    try {
      const discounts = await storage.getAllDiscountCodes();
      res.json(discounts);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch discounts" });
    }
  });

  app.delete("/api/admin/discounts/:id", async (req, res) => {
    try {
      await storage.deleteDiscountCode(parseInt(req.params.id));
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete discount" });
    }
  });

  app.get("/api/notifications", async (req, res) => {
    try {
      const sessionId = req.session?.id || "anonymous";
      const notifs = await storage.getNotifications(sessionId);
      res.json(notifs);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch notifications" });
    }
  });

  app.get("/api/notifications/unread-count", async (req, res) => {
    try {
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
      res.status(500).json({ message: "Failed to mark notification read" });
    }
  });

  app.patch("/api/admin/orders/:id", async (req, res) => {
    try {
      const { status, trackingNumber } = req.body;
      const order = await storage.updateOrderStatus(parseInt(req.params.id), status, trackingNumber);
      if (!order) return res.status(404).json({ message: "Order not found" });

      if (status === "ready_for_pickup") {
        await storage.createNotification({
          userId: order.sessionId,
          orderId: order.id,
          title: "طلبك جاهز للاستلام | Your order is ready",
          message: "طلبك رقم #" + order.id + " أصبح جاهزاً للاستلام من المتجر. | Your order #" + order.id + " is ready for pickup at the store.",
          read: false,
        });
      }

      res.json(order);
    } catch (error) {
      res.status(500).json({ message: "Failed to update order" });
    }
  });

  app.post("/api/payments/create", async (req, res) => {
    try {
      const { orderId, amount } = req.body;
      if (!orderId || !amount) {
        return res.status(400).json({ message: "orderId and amount are required" });
      }
      res.json({
        id: `pay_${Date.now()}`,
        status: "initiated",
        amount,
        currency: "SAR",
        orderId,
        message: "Moyasar payment integration pending — connect API keys to activate",
      });
    } catch (error) {
      res.status(500).json({ message: "Failed to create payment" });
    }
  });

  app.post("/api/webhooks/moyasar", async (req, res) => {
    try {
      const { id, status, metadata } = req.body;
      if (status === "paid" && metadata?.orderId) {
        const order = await storage.updateOrderStatus(parseInt(metadata.orderId), "paid");
        if (order) {
          await storage.createNotification({
            userId: order.sessionId,
            orderId: order.id,
            title: "تم تأكيد الدفع | Payment Confirmed",
            message: "تم تأكيد دفع طلبك رقم #" + order.id + " بنجاح. | Your payment for order #" + order.id + " has been confirmed.",
            read: false,
          });
        }
      }
      res.json({ received: true });
    } catch (error) {
      res.status(500).json({ message: "Webhook processing failed" });
    }
  });

  return httpServer;
}
