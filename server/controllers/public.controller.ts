import type { Request, Response } from "express";
import { storage } from "../storage";
import { AppError } from "../utils/AppError";
import { getCached, setCache } from "../middleware/cache";

export async function getActiveBanners(_req: Request, res: Response) {
  const cached = getCached("banners");
  if (cached) return res.json(cached);
  const data = await storage.getActiveBanners();
  setCache("banners", data, 60);
  res.json(data);
}

export async function getVisibleCategories(_req: Request, res: Response) {
  const cached = getCached("categories");
  if (cached) return res.json(cached);
  const data = await storage.getVisibleCategories();
  setCache("categories", data, 60);
  res.json(data);
}

export async function validateDiscount(req: Request, res: Response) {
  const { code } = req.body;
  if (!code) throw AppError.badRequest("Code is required");
  const discount = await storage.getDiscountCode(code);
  if (!discount || !discount.active) throw AppError.notFound("Invalid discount code");
  if (discount.maxUses && discount.usedCount >= discount.maxUses) {
    throw AppError.badRequest("Discount code has been fully redeemed");
  }
  if (discount.expiresAt && new Date(discount.expiresAt) < new Date()) {
    throw AppError.badRequest("Discount code has expired");
  }
  res.json({ type: discount.type, value: discount.value, minOrder: discount.minOrder });
}

export async function getNotifications(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (userId) {
    return res.json(await storage.getNotifications(String(userId)));
  }
  const sessionId = req.session?.id || "anonymous";
  res.json(await storage.getNotifications(sessionId));
}

export async function getUnreadCount(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (userId) {
    const count = await storage.getUnreadNotificationCount(String(userId));
    return res.json({ count });
  }
  const sessionId = req.session?.id || "anonymous";
  const count = await storage.getUnreadNotificationCount(sessionId);
  res.json({ count });
}

export async function markNotificationRead(req: Request, res: Response) {
  const notif = await storage.markNotificationRead(parseInt(req.params.id));
  if (!notif) throw AppError.notFound("Notification not found");
  res.json(notif);
}

export async function getSetting(req: Request, res: Response) {
  const value = await storage.getSetting(req.params.key);
  res.json({ key: req.params.key, value: value || null });
}

export async function recordPageView(req: Request, res: Response) {
  const { sessionId, page, productId } = req.body;
  if (!sessionId || !page) throw AppError.badRequest("sessionId and page are required");
  await storage.createPageView({ sessionId, page, productId: productId || null });
  res.json({ success: true });
}
