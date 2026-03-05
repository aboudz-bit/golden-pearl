import type { Request, Response } from "express";
import { storage } from "../storage";
import { insertCartItemSchema, cartItems } from "@shared/schema";
import { AppError } from "../utils/AppError";
import { db } from "../db";
import { eq } from "drizzle-orm";
import { computeDiscountedPrice, computeBadgeText } from "./product-discounts.controller";

async function enrichCartWithDiscounts(items: any[]) {
  if (items.length === 0) return items;
  const productIds = [...new Set(items.map(i => i.product?.id || i.productId).filter(Boolean))];
  const discounts = await storage.getActiveDiscountsForProducts(productIds);
  const discountMap = new Map<number, typeof discounts[0]>();
  for (const d of discounts) {
    if (!discountMap.has(d.productId)) discountMap.set(d.productId, d);
  }
  return items.map(item => {
    const pid = item.product?.id || item.productId;
    const d = discountMap.get(pid);
    if (!item.product || !d) {
      return {
        ...item,
        product: item.product ? { ...item.product, activeDiscount: null, priceFinal: item.product.price, discountBadgeText: null } : item.product,
      };
    }
    return {
      ...item,
      product: {
        ...item.product,
        activeDiscount: { id: d.id, type: d.type, value: d.value, startsAt: d.startsAt, endsAt: d.endsAt },
        priceFinal: computeDiscountedPrice(item.product.price, d.type, d.value),
        discountBadgeText: computeBadgeText(d.type, d.value),
      },
    };
  });
}

export async function getCart(req: Request, res: Response) {
  const userId = req.session?.userId;
  let items;
  if (userId) {
    items = await storage.getCartItemsByUserId(userId);
  } else {
    const sessionId = req.session?.id || "anonymous";
    items = await storage.getCartItems(sessionId);
  }
  res.json(await enrichCartWithDiscounts(items));
}

export async function addToCart(req: Request, res: Response) {
  const sessionId = req.session?.id || "anonymous";
  const userId = req.session?.userId;

  const product = await storage.getProduct(req.body.productId);
  if (product && product.stock <= 0) {
    throw AppError.badRequest("Product is out of stock");
  }

  const itemData: any = { ...req.body, sessionId };
  if (userId) itemData.userId = userId;

  const result = insertCartItemSchema.safeParse(itemData);
  if (!result.success) throw AppError.badRequest("Invalid cart item data");
  res.json(await storage.addCartItem({ ...result.data, updatedAt: new Date() }));
}

export async function updateCartItem(req: Request, res: Response) {
  const { quantity } = req.body;
  if (typeof quantity !== "number" || quantity < 1) {
    throw AppError.badRequest("Invalid quantity");
  }
  const item = await storage.updateCartItem(parseInt(req.params.id), quantity);
  if (!item) throw AppError.notFound("Cart item not found");
  
  await db.update(cartItems).set({ updatedAt: new Date() }).where(eq(cartItems.id, item.id));

  res.json(item);
}

export async function removeCartItem(req: Request, res: Response) {
  await storage.removeCartItem(parseInt(req.params.id));
  res.json({ success: true });
}

export async function clearCart(req: Request, res: Response) {
  const sessionId = req.session?.id || "anonymous";
  await storage.clearCart(sessionId);
  res.json({ success: true });
}
