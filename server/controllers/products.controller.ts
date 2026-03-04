import type { Request, Response } from "express";
import { storage } from "../storage";
import { insertProductSchema } from "@shared/schema";
import { AppError } from "../utils/AppError";

export async function listProducts(req: Request, res: Response) {
  const { category, search, featured } = req.query;
  if (search && typeof search === "string") {
    let results = await storage.searchProducts(search);
    if (category && typeof category === "string") {
      results = results.filter(p => p.category === category);
    }
    return res.json(results);
  }
  if (featured === "true") {
    return res.json(await storage.getFeaturedProducts());
  }
  if (category && typeof category === "string") {
    return res.json(await storage.getProductsByCategory(category));
  }
  res.json(await storage.getProducts());
}

export async function getProduct(req: Request, res: Response) {
  const product = await storage.getProduct(parseInt(req.params.id));
  if (!product) throw AppError.notFound("Product not found");
  res.json(product);
}

export async function createProduct(req: Request, res: Response) {
  const result = insertProductSchema.safeParse(req.body);
  if (!result.success) throw AppError.badRequest("Invalid product data");
  res.json(await storage.createProduct(result.data));
}

export async function updateProduct(req: Request, res: Response) {
  const product = await storage.updateProduct(parseInt(req.params.id), req.body);
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
  await storage.reorderProducts(items);
  res.json({ success: true });
}
