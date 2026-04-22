import type { Request, Response } from "express";
import { z } from "zod";
import { storage } from "../storage";
import { AppError } from "../utils/AppError";

const createDiscountSchema = z.object({
  productIds: z.array(z.number().int().positive()).min(1, "At least one product required"),
  type: z.enum(["percent", "fixed"]),
  value: z.number().int().positive("Value must be positive"),
  startsAt: z.string().refine(s => !isNaN(Date.parse(s)), "Invalid start date"),
  endsAt: z.string().refine(s => !isNaN(Date.parse(s)), "Invalid end date"),
  label: z.string().optional(),
});

const removeDiscountSchema = z.object({
  productIds: z.array(z.number().int().positive()).min(1),
});

export function computeDiscountedPrice(originalPrice: number, type: string, value: number): number {
  if (type === "percent") {
    return Math.round(originalPrice * (100 - value) / 100);
  }
  return Math.max(0, originalPrice - value);
}

export function computeBadgeText(type: string, value: number): string {
  if (type === "percent") return `-${value}%`;
  return `-${(value / 100).toFixed(value % 100 === 0 ? 0 : 2)} SAR`;
}

export async function createProductDiscounts(req: Request, res: Response) {
  const result = createDiscountSchema.safeParse(req.body);
  if (!result.success) {
    throw AppError.badRequest(result.error.issues.map(i => i.message).join(", "));
  }

  const { productIds, type, value, startsAt, endsAt, label } = result.data;
  const start = new Date(startsAt);
  const end = new Date(endsAt);

  if (end <= start) throw AppError.badRequest("End date must be after start date");
  if (type === "percent" && value > 95) throw AppError.badRequest("Percentage discount cannot exceed 95%");

  if (type === "fixed") {
    for (const pid of productIds) {
      const product = await storage.getProduct(pid);
      if (!product) throw AppError.notFound(`Product #${pid} not found`);
      if (value >= product.price) {
        throw AppError.badRequest(`Fixed discount (${value} halalas) exceeds or equals product "${product.nameEn}" price (${product.price} halalas)`);
      }
    }
  } else {
    for (const pid of productIds) {
      const product = await storage.getProduct(pid);
      if (!product) throw AppError.notFound(`Product #${pid} not found`);
    }
  }

  await storage.deleteProductDiscounts(productIds);

  const adminId = (req.session as any)?.userId || null;
  const created = [];
  for (const productId of productIds) {
    const discount = await storage.createProductDiscount({
      productId,
      type,
      value,
      startsAt: start,
      endsAt: end,
      label: label || null,
      createdByUserId: adminId,
    });
    created.push(discount);
  }

  res.json({ success: true, data: created, count: created.length });
}

export async function removeProductDiscounts(req: Request, res: Response) {
  const result = removeDiscountSchema.safeParse(req.body);
  if (!result.success) throw AppError.badRequest("productIds array required");
  const deleted = await storage.deleteProductDiscounts(result.data.productIds);
  res.json({ success: true, deleted });
}

export async function listProductDiscounts(_req: Request, res: Response) {
  const all = await storage.getAllProductDiscounts();
  res.json(all);
}

export async function getProductDiscount(req: Request, res: Response) {
  const productId = parseInt(req.params.productId);
  if (isNaN(productId)) throw AppError.badRequest("Invalid product ID");
  const discount = await storage.getActiveDiscountForProduct(productId);
  if (!discount) return res.json(null);
  const product = await storage.getProduct(productId);
  const priceFinal = product ? computeDiscountedPrice(product.price, discount.type, discount.value) : 0;
  const badgeText = computeBadgeText(discount.type, discount.value);
  res.json({ ...discount, priceFinal, badgeText });
}
