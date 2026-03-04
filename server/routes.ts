import type { Express } from "express";
import { createServer, type Server } from "http";
import { asyncHandler } from "./middleware/asyncHandler";
import { isAdmin } from "./middleware/auth";
import { upload, uploadFile, deleteFile } from "./controllers/uploads.controller";
import * as auth from "./controllers/auth.controller";
import * as products from "./controllers/products.controller";
import * as cart from "./controllers/cart.controller";
import * as orders from "./controllers/orders.controller";
import * as admin from "./controllers/admin.controller";
import * as pub from "./controllers/public.controller";
import * as pay from "./controllers/payments.controller";
import * as ship from "./controllers/shipping.controller";
import * as customers from "./controllers/customers.controller";

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {

  app.post("/api/auth/register", asyncHandler(auth.register));
  app.post("/api/auth/login", asyncHandler(auth.login));
  app.post("/api/auth/logout", asyncHandler(auth.logout));
  app.get("/api/auth/me", asyncHandler(auth.me));
  app.post("/api/auth/merge", asyncHandler(auth.mergeCart));

  app.post("/api/admin/upload", isAdmin, upload.single("file"), asyncHandler(uploadFile));
  app.delete("/api/admin/upload", isAdmin, asyncHandler(deleteFile));

  app.get("/api/products", asyncHandler(products.listProducts));
  app.get("/api/products/:id", asyncHandler(products.getProduct));

  app.get("/api/cart", asyncHandler(cart.getCart));
  app.post("/api/cart", asyncHandler(cart.addToCart));
  app.patch("/api/cart/:id", asyncHandler(cart.updateCartItem));
  app.delete("/api/cart/:id", asyncHandler(cart.removeCartItem));
  app.delete("/api/cart", asyncHandler(cart.clearCart));

  app.post("/api/orders", asyncHandler(orders.createOrder));
  app.get("/api/orders", asyncHandler(orders.listOrders));
  app.get("/api/orders/:id", asyncHandler(orders.getOrder));

  app.post("/api/discounts/validate", asyncHandler(pub.validateDiscount));

  app.get("/api/notifications", asyncHandler(pub.getNotifications));
  app.get("/api/notifications/unread-count", asyncHandler(pub.getUnreadCount));
  app.patch("/api/notifications/:id/read", asyncHandler(pub.markNotificationRead));

  app.get("/api/settings/:key", asyncHandler(pub.getSetting));
  app.post("/api/analytics/pageview", asyncHandler(pub.recordPageView));

  app.get("/api/banners", asyncHandler(pub.getActiveBanners));
  app.get("/api/categories", asyncHandler(pub.getVisibleCategories));

  app.post("/api/admin/products", isAdmin, asyncHandler(products.createProduct));
  app.patch("/api/admin/products/reorder", isAdmin, asyncHandler(products.reorderProducts));
  app.patch("/api/admin/products/:id", isAdmin, asyncHandler(products.updateProduct));
  app.delete("/api/admin/products/:id", isAdmin, asyncHandler(products.deleteProduct));
  app.patch("/api/admin/products/:id/stock", isAdmin, asyncHandler(products.updateStock));

  app.get("/api/admin/orders", isAdmin, asyncHandler(orders.adminListOrders));
  app.patch("/api/admin/orders/:id/status", isAdmin, asyncHandler(orders.updateOrderStatus));

  app.get("/api/admin/settings", isAdmin, asyncHandler(admin.getSettings));
  app.put("/api/admin/settings/:key", isAdmin, asyncHandler(admin.updateSetting));
  app.get("/api/admin/analytics", isAdmin, asyncHandler(admin.getAnalytics));

  app.get("/api/admin/banners", isAdmin, asyncHandler(admin.listBanners));
  app.post("/api/admin/banners", isAdmin, asyncHandler(admin.createBanner));
  app.patch("/api/admin/banners/reorder", isAdmin, asyncHandler(admin.reorderBanners));
  app.patch("/api/admin/banners/:id", isAdmin, asyncHandler(admin.updateBanner));
  app.delete("/api/admin/banners/:id", isAdmin, asyncHandler(admin.deleteBanner));

  app.get("/api/admin/categories", isAdmin, asyncHandler(admin.listCategories));
  app.patch("/api/admin/categories/reorder", isAdmin, asyncHandler(admin.reorderCategories));
  app.patch("/api/admin/categories/:id", isAdmin, asyncHandler(admin.updateCategory));

  app.post("/api/admin/discounts", isAdmin, asyncHandler(admin.createDiscount));
  app.get("/api/admin/discounts", isAdmin, asyncHandler(admin.listDiscounts));
  app.patch("/api/admin/discounts/:id", isAdmin, asyncHandler(admin.updateDiscount));
  app.delete("/api/admin/discounts/:id", isAdmin, asyncHandler(admin.deleteDiscount));

  app.get("/api/admin/notifications", isAdmin, asyncHandler(admin.listNotifications));
  app.post("/api/admin/notifications/send", isAdmin, asyncHandler(admin.sendNotification));
  app.delete("/api/admin/notifications", isAdmin, asyncHandler(admin.deleteNotificationGroup));

  app.get("/api/admin/customers/export", isAdmin, asyncHandler(customers.exportCustomers));
  app.get("/api/admin/customers/:id/export", isAdmin, asyncHandler(customers.exportCustomer));
  app.post("/api/admin/customers/:id/notify-cart", isAdmin, asyncHandler(customers.notifyCart));
  app.get("/api/admin/customers/:id", isAdmin, asyncHandler(customers.getCustomer));
  app.get("/api/admin/customers", isAdmin, asyncHandler(customers.listCustomers));

  app.post("/api/payments/create", asyncHandler(pay.createPaymentStub));
  app.post("/api/webhooks/moyasar", asyncHandler(pay.moyasarWebhook));
  app.post("/api/payments/session", asyncHandler(pay.createPaymentSession));
  app.post("/api/payments/:sessionId/confirm", asyncHandler(pay.confirmPayment));
  app.post("/api/payments/:sessionId/refund", asyncHandler(pay.refundPayment));

  app.post("/api/shipping/quote", asyncHandler(ship.quoteShipping));
  app.post("/api/shipping/create", asyncHandler(ship.createShipment));
  app.get("/api/shipping/track/:trackingNumber", asyncHandler(ship.trackShipment));

  return httpServer;
}
