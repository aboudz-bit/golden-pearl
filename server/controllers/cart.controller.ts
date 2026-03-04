import type { Request, Response } from "express";
import { storage } from "../storage";
import { insertCartItemSchema } from "@shared/schema";
import { AppError } from "../utils/AppError";

export async function getCart(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (userId) {
    return res.json(await storage.getCartItemsByUserId(userId));
  }
  const sessionId = req.session?.id || "anonymous";
  res.json(await storage.getCartItems(sessionId));
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
