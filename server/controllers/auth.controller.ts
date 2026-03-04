import type { Request, Response } from "express";
import bcrypt from "bcrypt";
import { storage } from "../storage";
import { AppError } from "../utils/AppError";

export async function register(req: Request, res: Response) {
  const { email, password, name, phone } = req.body;
  if (!email || !password || !name) {
    throw AppError.badRequest("Email, password, and name are required");
  }
  const existing = await storage.getUserByEmail(email);
  if (existing) throw AppError.conflict("Email already registered");

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await storage.createUser({ email: email.toLowerCase(), passwordHash, name, phone });
  req.session!.userId = user.id;

  const { passwordHash: _, ...safeUser } = user;
  res.json({ user: safeUser });
}

export async function login(req: Request, res: Response) {
  const { email, password } = req.body;
  if (!email || !password) throw AppError.badRequest("Email and password are required");

  const user = await storage.getUserByEmail(email);
  if (!user) throw AppError.unauthorized("Invalid email or password");

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) throw AppError.unauthorized("Invalid email or password");

  req.session!.userId = user.id;
  const { passwordHash: _, ...safeUser } = user;
  res.json({ user: safeUser });
}

export async function logout(req: Request, res: Response) {
  delete req.session!.userId;
  res.json({ success: true });
}

export async function me(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (!userId) return res.json({ user: null });
  const user = await storage.getUserById(userId);
  if (!user) return res.json({ user: null });
  const { passwordHash: _, ...safeUser } = user;
  res.json({ user: safeUser });
}

export async function mergeCart(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (!userId) throw AppError.unauthorized("Must be logged in to merge");
  const sessionId = req.session!.id;
  await storage.migrateCartToUser(sessionId, userId);
  const items = await storage.getCartItemsByUserId(userId);
  res.json({ success: true, cartItems: items });
}
