import type { Request, Response } from "express";
import { z } from "zod";
import { storage } from "../storage";
import { insertProductSchema } from "@shared/schema";
import { AppError } from "../utils/AppError";
import { computeDiscountedPrice, computeBadgeText } from "./product-discounts.controller";

const updateProductSchema = insertProductSchema.partial();

const reorderItemSchema = z.object({
  id: z.number().int().positive(),
  orderIndex: z.number().int().min(0),
});

async function enrichWithDiscounts(products: any[]) {
  if (products.length === 0) return products;
  const ids = products.map(p => p.id);
  const discounts = await storage.getActiveDiscountsForProducts(ids);
  const discountMap = new Map<number, typeof discounts[0]>();
  for (const d of discounts) {
    if (!discountMap.has(d.productId)) {
      discountMap.set(d.productId, d);
    }
  }
  return products.map(p => {
    const d = discountMap.get(p.id);
    if (!d) return { ...p, activeDiscount: null, priceFinal: p.price, discountBadgeText: null };
    return {
      ...p,
      activeDiscount: { id: d.id, type: d.type, value: d.value, startsAt: d.startsAt, endsAt: d.endsAt },
      priceFinal: computeDiscountedPrice(p.price, d.type, d.value),
      discountBadgeText: computeBadgeText(d.type, d.value),
    };
  });
}

export async function listProducts(req: Request, res: Response) {
  const { category, search, featured } = req.query;
  let products;
  if (search && typeof search === "string") {
    products = await storage.searchProducts(search);
    if (category && typeof category === "string") {
      products = products.filter(p => p.category === category);
    }
  } else if (featured === "true") {
    products = await storage.getFeaturedProducts();
  } else if (category && typeof category === "string") {
    products = await storage.getProductsByCategory(category);
  } else {
    products = await storage.getProducts();
  }
  res.json(await enrichWithDiscounts(products));
}

export async function getProduct(req: Request, res: Response) {
  const product = await storage.getProduct(parseInt(req.params.id));
  if (!product) throw AppError.notFound("Product not found");
  const [enriched] = await enrichWithDiscounts([product]);
  res.json(enriched);
}

export async function createProduct(req: Request, res: Response) {
  const result = insertProductSchema.safeParse(req.body);
  if (!result.success) throw AppError.badRequest("Invalid product data");
  res.json(await storage.createProduct(result.data));
}

export async function updateProduct(req: Request, res: Response) {
  const result = updateProductSchema.safeParse(req.body);
  if (!result.success) throw AppError.badRequest("Invalid product data");
  const product = await storage.updateProduct(parseInt(req.params.id), result.data);
  if (!product) throw AppError.notFound("Product not found");
  res.json(product);
}

export async function deleteProduct(req: Request, res: Response) {
  await storage.deleteProduct(parseInt(req.params.id));
  res.json({ success: true });
}

export async function updateStock(req: Request, res: Response) {
  const { stock } = req.body;
  if (typeof stock !== "number" || stock < 0) throw AppError.badRequest("Invalid stock value");
  const product = await storage.updateProductStock(parseInt(req.params.id), stock);
  if (!product) throw AppError.notFound("Product not found");
  res.json(product);
}

export async function reorderProducts(req: Request, res: Response) {
  const { items } = req.body;
  if (!Array.isArray(items)) throw AppError.badRequest("items array required");
  const parsed = z.array(reorderItemSchema).safeParse(items);
  if (!parsed.success) throw AppError.badRequest("Invalid reorder data");
  await storage.reorderProducts(parsed.data);
  res.json({ success: true });
}
