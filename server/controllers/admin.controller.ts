import type { Request, Response } from "express";
import { z } from "zod";
import { storage } from "../storage";
import { insertBannerSchema, insertDiscountCodeSchema, insertCategorySchema } from "@shared/schema";
import { AppError } from "../utils/AppError";
import { invalidateCache } from "../middleware/cache";

const updateBannerSchema = insertBannerSchema.partial();
const updateCategorySchema = insertCategorySchema.partial();
const reorderItemSchema = z.object({
  id: z.number().int().positive(),
  sortOrder: z.number().int().min(0),
});
const validStatuses = new Set(["pending", "confirmed", "processing", "shipped", "delivered", "ready_for_pickup", "cancelled"]);

export async function getSettings(_req: Request, res: Response) {
  res.json(await storage.getAllSettings());
}

export async function updateSetting(req: Request, res: Response) {
  const { value } = req.body;
  if (value === undefined) throw AppError.badRequest("Value is required");
  res.json(await storage.setSetting(req.params.key, value));
}

export async function getAnalytics(_req: Request, res: Response) {
  res.json(await storage.getAnalytics());
}

export async function listBanners(_req: Request, res: Response) {
  res.json(await storage.getBanners());
}

export async function createBanner(req: Request, res: Response) {
  const result = insertBannerSchema.safeParse(req.body);
  if (!result.success) throw AppError.badRequest("Invalid banner data");
  const banner = await storage.createBanner(result.data);
  invalidateCache("banners");
  res.json(banner);
}

export async function updateBanner(req: Request, res: Response) {
  const result = updateBannerSchema.safeParse(req.body);
  if (!result.success) throw AppError.badRequest("Invalid banner data");
  const banner = await storage.updateBanner(parseInt(req.params.id), result.data);
  if (!banner) throw AppError.notFound("Banner not found");
  invalidateCache("banners");
  res.json(banner);
}

export async function deleteBanner(req: Request, res: Response) {
  await storage.deleteBanner(parseInt(req.params.id));
  invalidateCache("banners");
  res.json({ success: true });
}

export async function reorderBanners(req: Request, res: Response) {
  const { items } = req.body;
  if (!Array.isArray(items)) throw AppError.badRequest("items array required");
  const parsed = z.array(reorderItemSchema).safeParse(items);
  if (!parsed.success) throw AppError.badRequest("Invalid reorder data");
  await storage.reorderBanners(parsed.data);
  invalidateCache("banners");
  res.json({ success: true });
}

export async function listCategories(_req: Request, res: Response) {
  res.json(await storage.getCategories());
}

export async function reorderCategories(req: Request, res: Response) {
  const { items, orderedIds } = req.body;
  if (orderedIds && Array.isArray(orderedIds)) {
    const idsResult = z.array(z.number().int().positive()).safeParse(orderedIds);
    if (!idsResult.success) throw AppError.badRequest("Invalid orderedIds");
    const mapped = idsResult.data.map((id, idx) => ({ id, sortOrder: idx }));
    await storage.reorderCategories(mapped);
    invalidateCache("categories");
    return res.json({ success: true });
  }
  if (!Array.isArray(items)) throw AppError.badRequest("items array or orderedIds required");
  const parsed = z.array(reorderItemSchema).safeParse(items);
  if (!parsed.success) throw AppError.badRequest("Invalid reorder data");
  await storage.reorderCategories(parsed.data);
  invalidateCache("categories");
  res.json({ success: true });
}

export async function updateCategory(req: Request, res: Response) {
  const result = updateCategorySchema.safeParse(req.body);
  if (!result.success) throw AppError.badRequest("Invalid category data");
  const cat = await storage.updateCategory(parseInt(req.params.id), result.data);
  if (!cat) throw AppError.notFound("Category not found");
  invalidateCache("categories");
  res.json(cat);
}

export async function createDiscount(req: Request, res: Response) {
  const { minOrderAmount, expiresAt, ...rest } = req.body;
  const data: any = {
    ...rest,
    minOrder: minOrderAmount ?? rest.minOrder ?? 0,
  };
  if (expiresAt) {
    data.expiresAt = new Date(expiresAt);
  }
  const result = insertDiscountCodeSchema.safeParse(data);
  if (!result.success) {
    console.error("Discount validation failed:", result.error.format());
    throw AppError.badRequest("Invalid discount data");
  }
  res.json(await storage.createDiscountCode(result.data));
}

export async function listDiscounts(_req: Request, res: Response) {
  res.json(await storage.getAllDiscountCodes());
}

export async function updateDiscount(req: Request, res: Response) {
  const { minOrderAmount, expiresAt, ...rest } = req.body;
  const data: any = { ...rest };
  if (minOrderAmount !== undefined) {
    data.minOrder = minOrderAmount;
  }
  if (expiresAt !== undefined) {
    data.expiresAt = expiresAt ? new Date(expiresAt) : null;
  }
  const discount = await storage.updateDiscountCode(parseInt(req.params.id), data);
  if (!discount) throw AppError.notFound("Discount not found");
  res.json(discount);
}

export async function deleteDiscount(req: Request, res: Response) {
  await storage.deleteDiscountCode(parseInt(req.params.id));
  res.json({ success: true });
}

export async function sendNotification(req: Request, res: Response) {
  const { title, message, productId } = req.body;
  if (!title || !message) throw AppError.badRequest("Title and message are required");
  await storage.sendNotificationToAll(title, message, productId);
  res.json({ success: true });
}

export async function listNotifications(_req: Request, res: Response) {
  const all = await storage.getAllNotifications();
  const grouped = new Map<string, any>();
  for (const n of all) {
    const key = `${n.title}||${n.message}||${n.productId ?? ''}`;
    if (!grouped.has(key)) {
      grouped.set(key, { id: n.id, title: n.title, message: n.message, productId: n.productId, createdAt: n.createdAt, count: 0 });
    }
    grouped.get(key)!.count++;
  }
  res.json(Array.from(grouped.values()));
}

export async function deleteNotificationGroup(req: Request, res: Response) {
  const { title, message } = req.body;
  if (!title) throw AppError.badRequest("Title is required to identify notification group");
  const all = await storage.getAllNotifications();
  const toDelete = all.filter(n => n.title === title && n.message === message);
  for (const n of toDelete) {
    await storage.deleteNotification(n.id);
  }
  res.json({ success: true, deleted: toDelete.length });
}
